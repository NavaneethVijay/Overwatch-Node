import ApplicationServices
import Cocoa

/// Live-checked status for every OS permission this app can need — backs
/// the settings window's Status tab ("what do I need to enable"). Bluetooth
/// has no entry here: BluetoothStatus.swift deliberately shells out to
/// `system_profiler` specifically to avoid ever touching the TCC-protected
/// IOBluetooth API, so there's no permission state to report for it.
enum PermissionsStatus {
    static var accessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    /// No public API reports Automation authorization directly, so this
    /// makes a harmless trial AppleScript call to System Events — the same
    /// target volume/browser-tabs/shutdown already use — and checks for
    /// error -1743 (errAEEventNotPermitted), exactly the failure any real
    /// command would hit if this isn't granted. Calling this is also what
    /// triggers the OS's one-time consent dialog if the user hasn't been
    /// asked yet, same as it would on first real use.
    static var automationGranted: Bool {
        var errorDict: NSDictionary?
        let script = NSAppleScript(source: "tell application \"System Events\" to return name")
        script?.executeAndReturnError(&errorDict)
        if let code = errorDict?[NSAppleScript.errorNumber] as? Int, code == -1743 {
            return false
        }
        return true
    }
}

/// Deep links into System Settings' privacy panes. These `x-apple.
/// systempreferences:` URLs are an old, informally-supported scheme —
/// still working today via a compatibility shim, but not documented API.
/// Worst case if Apple ever drops it: `NSWorkspace` silently does nothing,
/// so this never crashes, it just stops deep-linking.
enum SettingsPane {
    static func openAccessibility() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    static func openAutomation() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
    }

    static func openLocalNetwork() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_LocalNetwork")
    }

    private static func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
