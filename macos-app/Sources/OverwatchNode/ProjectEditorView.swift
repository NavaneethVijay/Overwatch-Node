import SwiftUI

/// Edits one Project's name and sections. Reuses SectionsEditor (the same
/// add/remove/reorder editor ModuleEditorView.swift uses for a module's own
/// base sections), since a Project is exactly that same
/// `sections: [ModuleSection]` shape. No independent save/cancel — `project`
/// is bound straight into the parent ModuleEditorView's `schema`, so the
/// outer editor's own Save persists everything, Project edits included;
/// this is just a "Done" dismiss.
struct ProjectEditorView: View {
    @Binding var project: Project

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                TextField("Project name", text: $project.name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SettingsColor.text)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(EdgeInsets(top: 18, leading: 24, bottom: 16, trailing: 24))

            Rectangle().fill(SettingsColor.divider).frame(height: 1)

            ScrollView {
                SectionsEditor(sections: $project.sections)
                    .padding(EdgeInsets(top: 20, leading: 24, bottom: 24, trailing: 24))
            }
        }
        .frame(width: 520, height: 560)
        .background(SettingsColor.bgContent)
    }
}
