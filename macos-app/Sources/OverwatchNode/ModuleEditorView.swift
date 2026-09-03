import SwiftUI

/// Edits a module's sections, buttons, and Projects — writing straight back
/// to its JSON file via ModuleStore.saveSchema. Add/remove/reorder is all
/// bound live in-memory (see SectionsEditor); Save persists the whole tree
/// in one shot.
struct ModuleEditorView: View {
    let module: ModuleStore.InstalledModule

    @Environment(\.dismiss) private var dismiss
    @State private var schema: ModuleSchema?
    @State private var loadFailed = false
    @State private var editingProjectIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Rectangle().fill(SettingsColor.divider).frame(height: 1)

            if let boundSchema = Binding($schema) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        SectionsEditor(sections: boundSchema.sections)
                        projectsSection(boundSchema)
                    }
                    .padding(EdgeInsets(top: 20, leading: 24, bottom: 24, trailing: 24))
                }
            } else {
                Spacer()
                if loadFailed {
                    Text("Couldn't load this module's file.")
                        .foregroundStyle(SettingsColor.textSecondary)
                } else {
                    ProgressView()
                }
                Spacer()
            }
        }
        .frame(width: 560, height: 640)
        .background(SettingsColor.bgContent)
        .onAppear(perform: load)
        .sheet(isPresented: projectSheetPresented) {
            if let boundSchema = Binding($schema), let index = editingProjectIndex {
                let projects = projectsBinding(boundSchema)
                if projects.wrappedValue.indices.contains(index) {
                    ProjectEditorView(project: projects[index])
                }
            }
        }
    }

    private var projectSheetPresented: Binding<Bool> {
        Binding(get: { editingProjectIndex != nil }, set: { if !$0 { editingProjectIndex = nil } })
    }

    /// `schema.projects` is optional (so existing seeded module files with
    /// no Projects keep decoding unchanged) — this presents it to the UI as
    /// a plain, always-present array.
    private func projectsBinding(_ schema: Binding<ModuleSchema>) -> Binding<[Project]> {
        Binding(
            get: { schema.wrappedValue.projects ?? [] },
            set: { schema.wrappedValue.projects = $0 }
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(module.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SettingsColor.text)
                Text("Sections, buttons, and Projects")
                    .font(.system(size: 11.5))
                    .foregroundStyle(SettingsColor.textTertiary)
            }
            Spacer()
            Button("Cancel") { dismiss() }
                .buttonStyle(.bordered)
            Button("Save", action: save)
                .buttonStyle(.borderedProminent)
                .disabled(schema == nil)
        }
        .padding(EdgeInsets(top: 18, leading: 24, bottom: 16, trailing: 24))
    }

    @ViewBuilder
    private func projectsSection(_ schema: Binding<ModuleSchema>) -> some View {
        let projects = projectsBinding(schema)

        VStack(alignment: .leading, spacing: 10) {
            SettingsSectionLabel(title: "Projects")
            SettingsCard {
                ForEach(Array(projects.wrappedValue.enumerated()), id: \.element.id) { index, project in
                    if index > 0 { SettingsCardDivider() }
                    ProjectRow(
                        name: project.name,
                        onMoveUp: index > 0 ? { projects.wrappedValue.swapAt(index, index - 1) } : nil,
                        onMoveDown: index < projects.wrappedValue.count - 1 ? { projects.wrappedValue.swapAt(index, index + 1) } : nil,
                        onEdit: { editingProjectIndex = index },
                        onDelete: { projects.wrappedValue.remove(at: index) }
                    )
                }
                if !projects.wrappedValue.isEmpty {
                    SettingsCardDivider()
                }
                Button {
                    projects.wrappedValue.append(Project(id: UUID().uuidString, name: "New Project", sections: []))
                } label: {
                    Label("Add Project", systemImage: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .foregroundStyle(SettingsColor.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    private func load() {
        schema = ModuleStore.loadSchema(filename: module.filename)
        loadFailed = schema == nil
    }

    private func save() {
        guard let schema else { return }
        try? ModuleStore.saveSchema(schema, filename: module.filename)
        dismiss()
    }
}

private struct ProjectRow: View {
    let name: String
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onEdit) {
                HStack(spacing: 10) {
                    Image(systemName: "folder")
                        .foregroundStyle(SettingsColor.textSecondary)
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SettingsColor.text)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            reorderButton(systemImage: "chevron.up", action: onMoveUp)
            reorderButton(systemImage: "chevron.down", action: onMoveDown)

            Button(action: onDelete) {
                Image(systemName: "trash").foregroundStyle(SettingsColor.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func reorderButton(systemImage: String, action: (() -> Void)?) -> some View {
        Button(action: { action?() }) {
            Image(systemName: systemImage)
                .foregroundStyle(action == nil ? SettingsColor.textTertiary : SettingsColor.textSecondary)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

/// Generic editor for a `[ModuleSection]` array — shared by a module's own
/// base sections (above) and a Project's sections (ProjectEditorView),
/// since both are exactly this same shape. Adds/removes/reorders sections
/// and their buttons; hand-rolled up/down arrows rather than native
/// List/.onMove, since this codebase has no drag-reorder pattern anywhere
/// yet and this keeps the existing SettingsCard/VStack styling instead of
/// introducing List chrome for just this one editor.
struct SectionsEditor: View {
    @Binding var sections: [ModuleSection]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                if isEditable(section) {
                    sectionCard(index: index)
                }
            }
            Button(action: addSection) {
                Label("Add Section", systemImage: "plus")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(SettingsColor.accent)
        }
    }

    /// A section is only shown here if EVERY control in it is something
    /// this generic editor can safely own — a plain button whose action
    /// isn't `capability`-kind. This hides two different kinds of built-in
    /// content this editor has no safe way to create or edit: Chrome/
    /// Edge's dynamicList-only "Tabs" section (non-button controls), and
    /// Window Management's Tiling/Spaces & Windows sections (button
    /// controls, but every action is `capability`-kind — `window.tile`/
    /// `system.symbolicHotkey` — which would otherwise get silently
    /// corrupted the moment the Shortcut/Paste-only action picker touched
    /// them, since neither of its two options can represent `capability`).
    /// A freshly added section starts with zero controls of any kind and
    /// must NOT be hidden by this rule — `allSatisfy` on an empty array is
    /// vacuously true, so a brand-new empty section stays visible instead
    /// of vanishing before you could add anything to it.
    private func isEditable(_ section: ModuleSection) -> Bool {
        section.controls.allSatisfy { $0.type == "button" && $0.action?.kind != "capability" }
    }

    @ViewBuilder
    private func sectionCard(index: Int) -> some View {
        let sectionBinding = $sections[index]
        let buttonIndices = sectionBinding.wrappedValue.controls.indices.filter {
            sectionBinding.wrappedValue.controls[$0].type == "button"
        }

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Section title", text: sectionBinding.title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SettingsColor.textTertiary)
                    .textCase(.uppercase)
                Spacer()
                Button(action: { sections.swapAt(index, index - 1) }) {
                    Image(systemName: "chevron.up")
                        .foregroundStyle(index > 0 ? SettingsColor.textSecondary : SettingsColor.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(index == 0)
                Button(action: { sections.swapAt(index, index + 1) }) {
                    Image(systemName: "chevron.down")
                        .foregroundStyle(index < sections.count - 1 ? SettingsColor.textSecondary : SettingsColor.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(index == sections.count - 1)
                Button(action: { sections.remove(at: index) }) {
                    Image(systemName: "trash").foregroundStyle(SettingsColor.textSecondary)
                }
                .buttonStyle(.plain)
            }

            SettingsCard {
                ForEach(Array(buttonIndices.enumerated()), id: \.element) { displayIndex, controlIndex in
                    if displayIndex > 0 { SettingsCardDivider() }
                    ButtonEditorRow(
                        control: sectionBinding.controls[controlIndex],
                        onMoveUp: displayIndex > 0
                            ? { sections[index].controls.swapAt(controlIndex, buttonIndices[displayIndex - 1]) }
                            : nil,
                        onMoveDown: displayIndex < buttonIndices.count - 1
                            ? { sections[index].controls.swapAt(controlIndex, buttonIndices[displayIndex + 1]) }
                            : nil,
                        onDelete: { sections[index].controls.remove(at: controlIndex) }
                    )
                }
                if !buttonIndices.isEmpty {
                    SettingsCardDivider()
                }
                Button(action: { addButton(sectionIndex: index) }) {
                    Label("Add Button", systemImage: "plus")
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .foregroundStyle(SettingsColor.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    private func addSection() {
        sections.append(ModuleSection(title: "New Section", controls: []))
    }

    private func addButton(sectionIndex: Int) {
        sections[sectionIndex].controls.append(
            ModuleControl(
                type: "button",
                label: "New Button",
                icon: nil,
                action: ModuleAction(kind: "shortcut", keys: [], id: nil, params: nil, text: nil, pressReturn: nil),
                provider: nil,
                itemAction: nil
            )
        )
    }
}

/// One editable button: label, icon, reorder/delete, and its action.
/// Shortcut actions get modifier checkboxes + a main-key picker; Paste
/// actions get the literal text to type + an auto-Enter toggle. Capability
/// actions are never offered here — reserved for built-in modules, never
/// something the module builder can create (see ModuleAction's doc comment
/// and ModuleValidator).
private struct ButtonEditorRow: View {
    @Binding var control: ModuleControl
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    let onDelete: () -> Void

    private static let knownMainKeys = [
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "tab", "space", "return", "delete", "escape", "[", "]", "backtick",
        "left", "right", "down", "up",
    ]
    private static let modifierOrder = ["cmd", "shift", "option", "control"]

    private var labelBinding: Binding<String> {
        Binding(get: { control.label ?? "" }, set: { control.label = $0 })
    }

    private var iconBinding: Binding<String> {
        Binding(get: { control.icon ?? "" }, set: { control.icon = $0 })
    }

    private var actionKind: Binding<String> {
        Binding(
            get: { control.action?.kind ?? "shortcut" },
            set: { newKind in
                var action = control.action ?? ModuleAction(kind: newKind, keys: nil, id: nil, params: nil, text: nil, pressReturn: nil)
                action.kind = newKind
                control.action = action
            }
        )
    }

    private var modifiers: Binding<Set<String>> {
        Binding(
            get: { Set((control.action?.keys ?? []).filter { Self.modifierOrder.contains($0) }) },
            set: { newMods in
                var action = control.action ?? ModuleAction(kind: "shortcut", keys: [], id: nil, params: nil, text: nil, pressReturn: nil)
                let key = mainKey.wrappedValue
                action.keys = Self.modifierOrder.filter { newMods.contains($0) } + (key.isEmpty ? [] : [key])
                control.action = action
            }
        )
    }

    private var mainKey: Binding<String> {
        Binding(
            get: { (control.action?.keys ?? []).first { !Self.modifierOrder.contains($0) } ?? "" },
            set: { newKey in
                var action = control.action ?? ModuleAction(kind: "shortcut", keys: [], id: nil, params: nil, text: nil, pressReturn: nil)
                let mods = Self.modifierOrder.filter { modifiers.wrappedValue.contains($0) }
                action.keys = mods + (newKey.isEmpty ? [] : [newKey])
                control.action = action
            }
        )
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { control.action?.text ?? "" },
            set: { newValue in
                var action = control.action ?? ModuleAction(kind: "paste", keys: nil, id: nil, params: nil, text: nil, pressReturn: nil)
                action.text = newValue
                control.action = action
            }
        )
    }

    private var pressReturnBinding: Binding<Bool> {
        Binding(
            get: { control.action?.pressReturn ?? false },
            set: { newValue in
                var action = control.action ?? ModuleAction(kind: "paste", keys: nil, id: nil, params: nil, text: nil, pressReturn: nil)
                action.pressReturn = newValue
                control.action = action
            }
        )
    }

    private func options(_ known: [String], including current: String) -> [String] {
        current.isEmpty || known.contains(current) ? known : [current] + known
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                TextField("Label", text: labelBinding)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SettingsColor.text)

                Picker("", selection: iconBinding) {
                    Text("None").tag("")
                    ForEach(options(ModuleIconCatalog.entries.map(\.key), including: iconBinding.wrappedValue), id: \.self) { key in
                        if let entry = ModuleIconCatalog.entry(for: key) {
                            Label(entry.label, systemImage: entry.sfSymbol).tag(key)
                        } else {
                            Text(key).tag(key)
                        }
                    }
                }
                .labelsHidden()
                .frame(width: 170)

                Button(action: { onMoveUp?() }) { Image(systemName: "chevron.up") }
                    .buttonStyle(.plain)
                    .foregroundStyle(onMoveUp == nil ? SettingsColor.textTertiary : SettingsColor.textSecondary)
                    .disabled(onMoveUp == nil)
                Button(action: { onMoveDown?() }) { Image(systemName: "chevron.down") }
                    .buttonStyle(.plain)
                    .foregroundStyle(onMoveDown == nil ? SettingsColor.textTertiary : SettingsColor.textSecondary)
                    .disabled(onMoveDown == nil)
                Button(action: onDelete) { Image(systemName: "trash") }
                    .buttonStyle(.plain)
                    .foregroundStyle(SettingsColor.textSecondary)
            }

            Picker("", selection: actionKind) {
                Text("Shortcut").tag("shortcut")
                Text("Paste").tag("paste")
            }
            .labelsHidden()
            .pickerStyle(.segmented)

            if actionKind.wrappedValue == "shortcut" {
                HStack(spacing: 16) {
                    ForEach(Self.modifierOrder, id: \.self) { mod in
                        Toggle(symbol(for: mod), isOn: Binding(
                            get: { modifiers.wrappedValue.contains(mod) },
                            set: { isOn in
                                var mods = modifiers.wrappedValue
                                if isOn { mods.insert(mod) } else { mods.remove(mod) }
                                modifiers.wrappedValue = mods
                            }
                        ))
                        .toggleStyle(.checkbox)
                    }
                    Spacer()
                    Picker("", selection: mainKey) {
                        Text("—").tag("")
                        ForEach(options(Self.knownMainKeys, including: mainKey.wrappedValue), id: \.self) { key in
                            Text(key).tag(key)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100)
                }
            } else if actionKind.wrappedValue == "paste" {
                TextField("Text to type", text: textBinding, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .lineLimit(1...4)
                Toggle("Press Enter automatically", isOn: pressReturnBinding)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
                    .foregroundStyle(SettingsColor.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func symbol(for modifier: String) -> String {
        switch modifier {
        case "cmd": "⌘"
        case "shift": "⇧"
        case "option": "⌥"
        case "control": "⌃"
        default: modifier
        }
    }
}
