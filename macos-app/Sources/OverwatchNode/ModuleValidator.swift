import Foundation

/// The actual security/sanity boundary for user-authored module content.
///
/// The module builder UI (ModuleEditorView.swift) can't produce a
/// disallowed shape in the first place — its action-kind picker only ever
/// offers Shortcut/Paste, and "Add Section" never creates a `dynamicList`
/// control — so this validator is only called from `ModuleStore.
/// importModule`, the one path that accepts arbitrary uploaded JSON.
/// Deliberately NOT called from `saveSchema`: re-validating a builder-saved
/// schema would risk rejecting an unrelated no-op save of a built-in module
/// (Chrome/Edge's Tabs section legitimately contains `dynamicList`/
/// `capability` content this editor deliberately never touches).
enum ModuleValidator {
    static let maxLabelLength = 60
    static let maxPasteTextLength = 500
    static let maxSections = 12
    static let maxControlsPerSection = 20
    static let maxProjects = 20

    /// Empty array means valid. Every problem is a short, human-readable
    /// string suitable for showing directly in AddModuleSheet's error UI.
    static func validate(sections: [ModuleSection], projects: [Project]) -> [String] {
        var problems: [String] = []

        if sections.count > maxSections {
            problems.append("Too many sections (\(sections.count), max \(maxSections)).")
        }
        for section in sections {
            problems.append(contentsOf: validate(section: section, context: "Section \"\(section.title)\""))
        }

        if projects.count > maxProjects {
            problems.append("Too many projects (\(projects.count), max \(maxProjects)).")
        }
        for project in projects {
            if project.id.isEmpty {
                problems.append("A project is missing an id.")
            }
            if project.name.isEmpty || project.name.count > maxLabelLength {
                problems.append("Project \"\(project.name)\" has an invalid name.")
            }
            if project.sections.count > maxSections {
                problems.append("Project \"\(project.name)\" has too many sections (\(project.sections.count), max \(maxSections)).")
            }
            for section in project.sections {
                problems.append(contentsOf: validate(section: section, context: "Project \"\(project.name)\" section \"\(section.title)\""))
            }
        }

        return problems
    }

    private static func validate(section: ModuleSection, context: String) -> [String] {
        var problems: [String] = []

        if section.controls.count > maxControlsPerSection {
            problems.append("\(context) has too many controls (\(section.controls.count), max \(maxControlsPerSection)).")
        }

        for control in section.controls {
            guard control.type == "button" else {
                problems.append("\(context): control type \"\(control.type)\" isn't allowed here (only \"button\" is).")
                continue
            }
            guard let action = control.action else {
                problems.append("\(context): a button is missing an action.")
                continue
            }
            problems.append(contentsOf: validate(action: action, context: context))
        }

        return problems
    }

    private static func validate(action: ModuleAction, context: String) -> [String] {
        var problems: [String] = []

        switch action.kind {
        case "shortcut":
            let keys = action.keys ?? []
            if keys.isEmpty {
                problems.append("\(context): a shortcut action has no keys.")
            }
            for key in keys where !ActionExecutor.isKnownShortcutToken(key) {
                problems.append("\(context): unrecognized shortcut key \"\(key)\".")
            }
        case "paste":
            let text = action.text ?? ""
            if text.isEmpty {
                problems.append("\(context): a paste action has no text.")
            } else if text.count > maxPasteTextLength {
                problems.append("\(context): paste text is too long (\(text.count) chars, max \(maxPasteTextLength)).")
            }
        default:
            problems.append("\(context): action kind \"\(action.kind)\" isn't allowed here (only \"shortcut\" and \"paste\" are).")
        }

        return problems
    }
}
