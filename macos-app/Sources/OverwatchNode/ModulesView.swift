import SwiftUI
import UniformTypeIdentifiers

/// Lists what's currently in ModuleStore.directory. Add (pick an installed
/// app, then either build its sections/buttons/Projects right in the app —
/// see ModuleEditorView's SectionsEditor — or import a JSON file that
/// already has them), remove, or — tap a row — edit an existing module in
/// place. The whole point of all three being you never need to touch Swift
/// or rebuild the app to support or tweak a module.
struct ModulesView: View {
    @State private var modules: [ModuleStore.InstalledModule] = []
    @State private var showingAddSheet = false
    @State private var editingModule: ModuleStore.InstalledModule?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text("Modules")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(SettingsColor.text)
                Spacer()
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Module…", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }

            if modules.isEmpty {
                Text("No modules yet — add one for an app on your Mac.")
                    .font(.system(size: 13))
                    .foregroundStyle(SettingsColor.textSecondary)
            } else {
                SettingsSectionLabel(title: "Installed")
                SettingsCard {
                    ForEach(Array(modules.enumerated()), id: \.element.id) { index, module in
                        if index > 0 { SettingsCardDivider() }
                        ModuleRow(
                            module: module,
                            onEdit: { editingModule = module },
                            onDelete: {
                                try? ModuleStore.removeModule(filename: module.filename)
                                reload()
                            }
                        )
                    }
                }
            }

            Spacer()
        }
        .padding(EdgeInsets(top: 34, leading: 38, bottom: 34, trailing: 38))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear(perform: reload)
        .sheet(isPresented: $showingAddSheet) {
            AddModuleSheet(onCreated: { module in
                reload()
                editingModule = module
            })
        }
        .sheet(item: $editingModule) { module in
            ModuleEditorView(module: module)
        }
    }

    private func reload() {
        modules = ModuleStore.installedModules()
    }
}

private struct ModuleRow: View {
    let module: ModuleStore.InstalledModule
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 13) {
                AppIconView(bundleId: module.bundleId, size: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(module.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SettingsColor.text)
                    Text(module.bundleId)
                        .font(.system(size: 11.5))
                        .foregroundStyle(SettingsColor.textTertiary)
                }
                Spacer()
                if module.isProtected {
                    // Built into the app — see ModuleStore.protectedBundleIds.
                    // No delete affordance at all, rather than a disabled
                    // trash button that invites "why won't this work?".
                    Image(systemName: "lock.fill")
                        .foregroundStyle(SettingsColor.textTertiary)
                } else {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundStyle(SettingsColor.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// The real installed app icon (NSWorkspace lookup by bundle id), not a
/// placeholder colored square — the icon data is already sitting in
/// AppMonitor's icon-rendering path for the exact same purpose, just
/// resolved directly here since a module's bundleId is all this needs.
struct AppIconView: View {
    let bundleId: String
    var size: CGFloat = 24

    var body: some View {
        Group {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
            } else {
                Image(systemName: "app.dashed")
                    .resizable()
                    .foregroundStyle(SettingsColor.textTertiary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}

private struct AddModuleSheet: View {
    /// Fired once a module actually exists on disk for the picked app —
    /// either freshly created (empty, ready for the builder) or imported
    /// from a JSON file. The caller opens ModuleEditorView on the result
    /// either way, so a builder-created module lands straight in the editor
    /// instead of leaving the user to find and tap it in the list.
    let onCreated: (ModuleStore.InstalledModule) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var apps: [AppInfo] = []
    @State private var searchText = ""
    @State private var selectedApp: AppInfo?
    @State private var errorMessage: String?

    private var filteredApps: [AppInfo] {
        guard !searchText.isEmpty else { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add Module")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SettingsColor.text)

            if let selectedApp {
                HStack(spacing: 11) {
                    appRow(selectedApp)
                    Spacer()
                    Button("Change") { self.selectedApp = nil }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(SettingsColor.accent)
                }
                .padding(11)
                .background(Color.white.opacity(0.045))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(SettingsColor.cardBorder, lineWidth: 1))

                Text("Build its sections and buttons right here, or import a JSON file that already has them — its own bundleId/displayName, if any, is ignored in favor of the app selected here.")
                    .font(.system(size: 12))
                    .foregroundStyle(SettingsColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(SettingsColor.textSecondary)
                    TextField("Search apps…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(SettingsColor.cardBorder, lineWidth: 1))

                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredApps, id: \.bundleId) { app in
                            Button {
                                selectedApp = app
                            } label: {
                                appRow(app)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage).font(.system(size: 12)).foregroundStyle(SettingsColor.red)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Button("Import JSON File…", action: chooseFileAndImport)
                    .disabled(selectedApp == nil)
                    .buttonStyle(.bordered)
                Button("Create Module", action: createEmptyModule)
                    .disabled(selectedApp == nil)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 400, height: 480)
        .background(SettingsColor.bgContent)
        .onAppear { apps = AppMonitor().installedApps() }
    }

    @ViewBuilder
    private func appRow(_ app: AppInfo) -> some View {
        HStack(spacing: 11) {
            // AppInfo already carries a pre-resized icon from AppMonitor —
            // reuse it rather than doing a second NSWorkspace lookup
            // (that's only actually needed in ModuleRow below, where
            // InstalledModule has no icon data of its own, just a bundleId).
            if let image = NSImage(base64PNG: app.iconPngBase64) {
                Image(nsImage: image).resizable().frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                AppIconView(bundleId: app.bundleId, size: 24)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(app.name)
                    .font(.system(size: 12.5))
                    .foregroundStyle(SettingsColor.text)
                Text(app.bundleId)
                    .font(.system(size: 10.5))
                    .foregroundStyle(SettingsColor.textTertiary)
            }
        }
    }

    private func chooseFileAndImport() {
        guard let selectedApp else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try ModuleStore.importModule(from: url, bundleId: selectedApp.bundleId, displayName: selectedApp.name)
            guard let module = ModuleStore.installedModules().first(where: { $0.bundleId == selectedApp.bundleId }) else {
                dismiss()
                return
            }
            onCreated(module)
            dismiss()
        } catch {
            errorMessage = "Couldn't import that file: \(error.localizedDescription)"
        }
    }

    private func createEmptyModule() {
        guard let selectedApp else { return }
        do {
            let module = try ModuleStore.createEmptyModule(bundleId: selectedApp.bundleId, displayName: selectedApp.name)
            onCreated(module)
            dismiss()
        } catch {
            errorMessage = "Couldn't create that module: \(error.localizedDescription)"
        }
    }
}

private extension NSImage {
    convenience init?(base64PNG: String) {
        guard !base64PNG.isEmpty, let data = Data(base64Encoded: base64PNG) else { return nil }
        self.init(data: data)
    }
}
