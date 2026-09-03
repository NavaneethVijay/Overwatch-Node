import SwiftUI

/// "What's connected, and what do I need to enable" — the first thing
/// someone should see when they open the app, since every other feature
/// silently depends on these permissions being granted. Queries live OS
/// state on every appear/refresh (never a cached/remembered result), so
/// this is correct whether the app has been running for weeks or was just
/// installed fresh — a fresh install just means every row starts red,
/// each with its own "Open Settings" fix button; nothing else to build
/// for that case specifically.
struct StatusView: View {
    let port: UInt16
    let fetchDeviceNames: () -> [String]
    let fetchPendingPairingCode: () -> (deviceName: String, code: String)?

    @State private var deviceNames: [String] = []
    @State private var accessibilityGranted = PermissionsStatus.accessibilityGranted
    @State private var automationGranted: Bool?
    @State private var pendingPairingCode: (deviceName: String, code: String)?
    @State private var pairedDevices: [TrustedDevice] = []

    // Polled rather than pushed — WebSocketServer has no notification
    // mechanism for "a new pairing request just arrived" or "a device just
    // connected/disconnected", and a 2s poll is plenty responsive for
    // something a person is actively looking at this screen to catch. Also
    // drives the Connection/Paired Devices sections below, not just pairing
    // — those used to be populated only in `refresh()` (`.onAppear`), so a
    // device connecting or dropping while this screen was already open
    // never showed up until the window was closed and reopened.
    private let connectionPollTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    private var missingCount: Int {
        (accessibilityGranted ? 0 : 1) + (automationGranted == false ? 1 : 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(SettingsColor.text)
                    if missingCount > 0 {
                        Text("\(missingCount) permission\(missingCount == 1 ? "" : "s") needed below for full functionality.")
                            .font(.system(size: 12))
                            .foregroundStyle(SettingsColor.textSecondary)
                    }
                }

                if let pendingPairingCode {
                    VStack(alignment: .leading, spacing: 10) {
                        SettingsSectionLabel(title: "Pairing Request")
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\(pendingPairingCode.deviceName) wants to connect")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(SettingsColor.text)
                                Text(pendingPairingCode.code)
                                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                                    .foregroundStyle(SettingsColor.accent)
                                    .tracking(5)
                                Text("Enter this code on the phone to approve it.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(SettingsColor.textSecondary)
                            }
                            .padding(16)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SettingsSectionLabel(title: "Connection")
                    SettingsCard {
                        StatusRow(label: "Listening on") {
                            Text("Port \(port)")
                                .font(.system(size: 13))
                                .foregroundStyle(SettingsColor.textSecondary)
                        }
                        if deviceNames.isEmpty {
                            SettingsCardDivider()
                            StatusRow(label: "Connected Device") {
                                Text("None")
                                    .font(.system(size: 13))
                                    .foregroundStyle(SettingsColor.textSecondary)
                            }
                        } else {
                            ForEach(deviceNames, id: \.self) { name in
                                SettingsCardDivider()
                                StatusRow(label: "Connected Device") {
                                    HStack(spacing: 7) {
                                        Circle().fill(SettingsColor.green).frame(width: 6, height: 6)
                                        Text(name)
                                            .font(.system(size: 13))
                                            .foregroundStyle(SettingsColor.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                }

                // Same content/purpose as the standalone Devices sidebar
                // page, embedded here instead — a diagnostic (does this
                // work when it's not its own NavigationSplitView case?)
                // that turned out to also just be a reasonable permanent
                // home for it: pairing and paired-device management live
                // together on the one screen this is all actually about.
                VStack(alignment: .leading, spacing: 10) {
                    SettingsSectionLabel(title: "Paired Devices")
                    if pairedDevices.isEmpty {
                        SettingsCard {
                            StatusRow(label: "No devices paired yet") {
                                EmptyView()
                            }
                        }
                    } else {
                        SettingsCard {
                            ForEach(Array(pairedDevices.enumerated()), id: \.element.id) { index, device in
                                if index > 0 { SettingsCardDivider() }
                                PairedDeviceRow(device: device, onRevoke: { revoke(device) })
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        SettingsSectionLabel(title: "Permissions")
                        Spacer()
                        Button("Refresh", action: refresh)
                            .buttonStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundStyle(SettingsColor.accent)
                    }
                    SettingsCard {
                        PermissionRow(
                            title: "Accessibility",
                            detail: "Needed for Contextual Controls keyboard shortcuts and Lock Screen.",
                            granted: accessibilityGranted,
                            onOpenSettings: SettingsPane.openAccessibility
                        )
                        SettingsCardDivider()
                        PermissionRow(
                            title: "Automation (System Events)",
                            detail: "Needed for Volume, browser tab controls, and Shut Down.",
                            granted: automationGranted ?? false,
                            unknown: automationGranted == nil,
                            onOpenSettings: SettingsPane.openAutomation
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("Local Network")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SettingsColor.text)
                    Text("Can't be checked automatically. If the phone shows “host unreachable,” confirm Overwatch Node is allowed here.")
                        .font(.system(size: 12))
                        .foregroundStyle(SettingsColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Open Local Network Settings", action: SettingsPane.openLocalNetwork)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .padding(.top, 2)
                }
                .padding(15)
                .background(SettingsColor.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(SettingsColor.cardBorder, lineWidth: 1))
            }
            .padding(EdgeInsets(top: 34, leading: 38, bottom: 34, trailing: 38))
        }
        .onAppear(perform: refresh)
        .onReceive(connectionPollTimer) { _ in
            pendingPairingCode = fetchPendingPairingCode()
            deviceNames = fetchDeviceNames()
            pairedDevices = DevicePairing.loadTrusted().sorted { $0.pairedAt > $1.pairedAt }
        }
    }

    private func revoke(_ device: TrustedDevice) {
        DevicePairing.revoke(deviceId: device.deviceId)
        pairedDevices = DevicePairing.loadTrusted().sorted { $0.pairedAt > $1.pairedAt }
    }

    private func refresh() {
        deviceNames = fetchDeviceNames()
        pendingPairingCode = fetchPendingPairingCode()
        pairedDevices = DevicePairing.loadTrusted().sorted { $0.pairedAt > $1.pairedAt }
        accessibilityGranted = PermissionsStatus.accessibilityGranted
        // automationGranted runs a blocking NSAppleScript call (can trigger
        // a one-time permission dialog on first use) — off main so a
        // pending dialog can't freeze this screen while it resolves, same
        // reasoning as AppDelegate's AppleScript-based handlers.
        DispatchQueue.global(qos: .userInitiated).async {
            let granted = PermissionsStatus.automationGranted
            DispatchQueue.main.async {
                automationGranted = granted
            }
        }
    }
}

private struct StatusRow<Trailing: View>: View {
    let label: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(SettingsColor.text)
            Spacer()
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

private struct PairedDeviceRow: View {
    let device: TrustedDevice
    let onRevoke: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "iphone")
                .font(.system(size: 14))
                .foregroundStyle(SettingsColor.textSecondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(device.deviceName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SettingsColor.text)
                Text("Paired \(device.pairedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 11.5))
                    .foregroundStyle(SettingsColor.textTertiary)
            }

            Spacer()

            Button(action: onRevoke) {
                Image(systemName: "trash")
                    .foregroundStyle(SettingsColor.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

private struct PermissionRow: View {
    let title: String
    let detail: String
    let granted: Bool
    var unknown: Bool = false
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(unknown ? Color.gray : (granted ? SettingsColor.green : SettingsColor.red))
                .frame(width: 9, height: 9)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SettingsColor.text)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(SettingsColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if granted {
                Text("Granted")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SettingsColor.green)
                    .padding(.top, 2)
            } else {
                Button("Open Settings", action: onOpenSettings)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
