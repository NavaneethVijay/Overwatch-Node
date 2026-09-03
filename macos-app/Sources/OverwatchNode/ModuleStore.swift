import Foundation

/// Where per-app "Contextual Controls" module JSON lives — deliberately
/// outside the signed .app bundle so adding, editing, or removing a module
/// never requires a `swift build` + repackage. Built-in modules (see
/// DefaultModules.swift) are just seeded here once on first launch; from
/// then on they're indistinguishable from a module someone drops in by hand.
enum ModuleStore {
    static let directory: URL = {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("OverwatchNode/Modules", isDirectory: true)
    }()

    static func ensureSeeded() {
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            AppLog.lifecycle.error("failed to create Modules directory: \(String(describing: error), privacy: .public)")
            return
        }

        for module in DefaultModules.all {
            let fileURL = directory.appendingPathComponent(module.filename)
            guard !fm.fileExists(atPath: fileURL.path) else { continue }
            do {
                try module.json.data(using: .utf8)?.write(to: fileURL)
                AppLog.lifecycle.info("seeded default module \(module.filename, privacy: .public)")
            } catch {
                AppLog.lifecycle.error("failed to seed module \(module.filename, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        }
    }

    /// Re-scans the folder on every call rather than caching — this only
    /// runs once per frontmost-app change, not per-frame, so there's nothing
    /// to optimize, and a re-scan means an edited/added/removed .json file
    /// takes effect on the very next app switch with no restart needed.
    static func module(forBundleId bundleId: String) -> ModuleSchema? {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ) else {
            return nil
        }

        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file) else { continue }
            guard let schema = try? JSONDecoder().decode(ModuleSchema.self, from: data) else {
                AppLog.lifecycle.error("failed to parse module file \(file.lastPathComponent, privacy: .public)")
                continue
            }
            if schema.bundleId == bundleId { return schema }
        }
        return nil
    }

    /// Permanent, non-deletable built-ins — currently just Window
    /// Management (see DefaultModules.swift's doc comment on it). Checked
    /// by `removeModule` (the actual enforcement point) and by
    /// `InstalledModule.isProtected` (so ModulesView can hide/disable the
    /// delete button instead of letting the user hit an error after the
    /// fact).
    static let protectedBundleIds: Set<String> = ["com.overwatchnode.windowManagement"]

    struct InstalledModule: Identifiable {
        var id: String { bundleId }
        let bundleId: String
        let displayName: String
        let filename: String
        var isProtected: Bool { ModuleStore.protectedBundleIds.contains(bundleId) }
    }

    /// For the settings window's Modules tab — every module currently in
    /// the folder, default-seeded or hand-added alike (they're
    /// indistinguishable once seeded).
    static func installedModules() -> [InstalledModule] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ) else {
            return []
        }

        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { file -> InstalledModule? in
                guard
                    let data = try? Data(contentsOf: file),
                    let schema = try? JSONDecoder().decode(ModuleSchema.self, from: data)
                else { return nil }
                return InstalledModule(bundleId: schema.bundleId, displayName: schema.displayName, filename: file.lastPathComponent)
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    /// The app picked in the UI — not whatever `bundleId`/`displayName` the
    /// uploaded file might itself contain — is what determines which app a
    /// module applies to; the uploaded file only supplies `sections`/
    /// `projects`. This overwrites any existing module for that bundle id,
    /// including a default-seeded one, since editing/replacing an app's
    /// module is exactly what re-importing means. `ModuleValidator` runs
    /// here — the one path that accepts arbitrary content — rejecting
    /// anything containing a `capability` action or `dynamicList` control
    /// (both privileged/internal-only, never something an uploaded file
    /// should be able to reach) or exceeding basic size limits.
    static func importModule(from sourceURL: URL, bundleId: String, displayName: String) throws {
        let data = try Data(contentsOf: sourceURL)
        let uploaded = try JSONDecoder().decode(UploadedModuleContent.self, from: data)
        let problems = ModuleValidator.validate(sections: uploaded.sections, projects: uploaded.projects ?? [])
        guard problems.isEmpty else {
            throw ModuleImportError.invalidContent(problems)
        }
        let schema = ModuleSchema(
            bundleId: bundleId,
            displayName: displayName,
            sections: uploaded.sections,
            projects: uploaded.projects,
            currentProjectId: nil
        )
        let encoded = try JSONEncoder().encode(schema)
        try encoded.write(to: directory.appendingPathComponent("\(bundleId).json"))
    }

    /// Creates a brand-new, empty module for an app — no JSON file needed
    /// up front. The "Add Module" flow uses this for "build it in the app"
    /// (as opposed to "import a JSON file", still supported via
    /// `importModule` above): write an empty schema, then immediately open
    /// `ModuleEditorView` on the result so the user starts adding sections/
    /// buttons/Projects right away through the builder UI. Same overwrite
    /// semantics as `importModule` — picking an app that already has a
    /// module replaces it.
    static func createEmptyModule(bundleId: String, displayName: String) throws -> InstalledModule {
        let schema = ModuleSchema(bundleId: bundleId, displayName: displayName, sections: [], projects: nil, currentProjectId: nil)
        let encoded = try JSONEncoder().encode(schema)
        let filename = "\(bundleId).json"
        try encoded.write(to: directory.appendingPathComponent(filename))
        return InstalledModule(bundleId: bundleId, displayName: displayName, filename: filename)
    }

    /// Sets which Project is "current" for an app — called when the phone
    /// sends `select_project`. Persisted (not just broadcast) so it's
    /// consistent across a reconnect and across any other connected phone,
    /// per the confirmed design (see mac_remote_project_status memory). A
    /// no-op if `bundleId` has no module file or `projectId` isn't one of
    /// its actual projects.
    static func setCurrentProject(bundleId: String, projectId: String) {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ) else { return }

        for file in files where file.pathExtension == "json" {
            guard
                let data = try? Data(contentsOf: file),
                var schema = try? JSONDecoder().decode(ModuleSchema.self, from: data),
                schema.bundleId == bundleId
            else { continue }

            guard schema.projects?.contains(where: { $0.id == projectId }) == true else { return }
            schema.currentProjectId = projectId
            guard let encoded = try? JSONEncoder().encode(schema) else { return }
            try? encoded.write(to: file)
            return
        }
    }

    /// The real enforcement point for "can't be deleted" — ModulesView also
    /// hides the delete button for a protected module, but this guard is
    /// what actually matters, in case anything else ever calls this.
    static func removeModule(filename: String) throws {
        if let schema = loadSchema(filename: filename), protectedBundleIds.contains(schema.bundleId) {
            throw ModuleRemovalError.protectedModule
        }
        try FileManager.default.removeItem(at: directory.appendingPathComponent(filename))
    }

    /// For ModuleEditorView — load one module's full schema (sections and
    /// all) to edit in place, distinct from `installedModules()`, which
    /// only surfaces the bundleId/displayName/filename the Modules list
    /// needs.
    static func loadSchema(filename: String) -> ModuleSchema? {
        guard let data = try? Data(contentsOf: directory.appendingPathComponent(filename)) else { return nil }
        return try? JSONDecoder().decode(ModuleSchema.self, from: data)
    }

    /// Writes an edited schema back to its file — the phone picks it up on
    /// the next frontmost-app switch (see `module(forBundleId:)`'s
    /// re-scan-every-call comment), no restart needed on either side.
    static func saveSchema(_ schema: ModuleSchema, filename: String) throws {
        let encoded = try JSONEncoder().encode(schema)
        try encoded.write(to: directory.appendingPathComponent(filename))
    }
}

/// What an uploaded module file needs to supply — its controls and,
/// optionally, Projects; the picked app supplies bundleId/displayName (see
/// `importModule`).
private struct UploadedModuleContent: Decodable {
    let sections: [ModuleSection]
    let projects: [Project]?
}

enum ModuleImportError: LocalizedError {
    case invalidContent([String])

    var errorDescription: String? {
        switch self {
        case .invalidContent(let problems):
            "This file isn't allowed:\n" + problems.joined(separator: "\n")
        }
    }
}

enum ModuleRemovalError: LocalizedError {
    case protectedModule

    var errorDescription: String? {
        "This module is built into the app and can't be removed."
    }
}
