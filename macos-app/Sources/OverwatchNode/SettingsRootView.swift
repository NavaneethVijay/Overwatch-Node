import SwiftUI

private enum SettingsPage: String, CaseIterable, Identifiable {
    case status = "Status"
    case modules = "Modules"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .status: "antenna.radiowaves.left.and.right"
        case .modules: "square.stack.3d.up"
        }
    }
}

/// The settings window's whole contents — opened on demand from the menu
/// bar (see AppDelegate.showSettingsWindow); this file has zero AppKit
/// window-management logic itself.
///
/// Uses a real `NavigationSplitView` + `.listStyle(.sidebar)` for the
/// sidebar rather than hand-styling one to match the approved mockup pixel
/// for pixel — the mockup was drawn in HTML, which can only approximate
/// macOS's actual sidebar vibrancy/material, so the genuine native
/// component is truer to "native premium utility-app look" than copying
/// its HTML approximation would be. The content area (Status/Modules
/// screens) matches the mockup's colors/spacing exactly instead, since
/// HTML could express those precisely — see SettingsTheme.swift.
struct SettingsRootView: View {
    let port: UInt16
    let fetchDeviceNames: () -> [String]
    let fetchPendingPairingCode: () -> (deviceName: String, code: String)?

    @State private var selection: SettingsPage? = .status

    var body: some View {
        NavigationSplitView {
            List(SettingsPage.allCases, selection: $selection) { page in
                Label(page.rawValue, systemImage: page.systemImage).tag(page)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(200)
            .safeAreaInset(edge: .bottom) {
                Text("Overwatch Node")
                    .font(.system(size: 10.5))
                    .foregroundStyle(SettingsColor.textTertiary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } detail: {
            Group {
                switch selection ?? .status {
                case .status:
                    StatusView(
                        port: port,
                        fetchDeviceNames: fetchDeviceNames,
                        fetchPendingPairingCode: fetchPendingPairingCode
                    )
                case .modules:
                    ModulesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(SettingsColor.bgContent)
        }
        .navigationSplitViewStyle(.balanced)
        // idealWidth/idealHeight (not just min) is what actually sizes the
        // window on first open — without it, NSWindow(contentViewController:)
        // sizes to the *minimum*, which is why this was opening far too
        // small. 860 matches the original approved mockup's width; 720
        // (taller than the mockup's own 560) accounts for the Pairing
        // Request + Paired Devices sections added to Status since that
        // mockup was drawn — there's more content to show now.
        .frame(minWidth: 720, idealWidth: 860, minHeight: 480, idealHeight: 720)
    }
}
