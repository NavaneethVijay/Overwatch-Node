import AppKit
import CoreGraphics
import Foundation

/// Screen brightness has no public API, and every private route tried here
/// is currently non-functional on this machine's (very new) macOS version
/// when called from a normally-compiled Swift executable:
/// `DisplayServicesGetBrightness`/`SetBrightness` (the long-documented
/// technique used by tools like `brightness` (nriley)) loads but the calls
/// themselves fail; `CoreDisplay_Display_GetUserBrightness`/
/// `SetUserBrightness` works correctly when run via `swift script.swift`
/// (the interpreter) but `dlopen` itself fails ("not in dyld cache") from
/// this same code once compiled as a regular executable — true even
/// unsigned, so it isn't a code-signing/entitlements issue we introduced.
/// Root cause not yet identified; see macos-app/README.md. Left wired up so
/// fixing the loading issue (or finding a working symbol) is a one-file
/// change — currently a safe no-op (always reports 50%, setLevel does
/// nothing) rather than crashing.
enum DisplayBrightness {
    private typealias GetterFunc = @convention(c) (CGDirectDisplayID) -> Double
    private typealias SetterFunc = @convention(c) (CGDirectDisplayID, Double) -> Void

    private static let handle: UnsafeMutableRawPointer? = dlopen(
        "/System/Library/PrivateFrameworks/CoreDisplay.framework/CoreDisplay",
        RTLD_NOW
    )

    private static let getter: GetterFunc? = {
        guard let handle, let symbol = dlsym(handle, "CoreDisplay_Display_GetUserBrightness") else {
            return nil
        }
        return unsafeBitCast(symbol, to: GetterFunc.self)
    }()

    private static let setter: SetterFunc? = {
        guard let handle, let symbol = dlsym(handle, "CoreDisplay_Display_SetUserBrightness") else {
            return nil
        }
        return unsafeBitCast(symbol, to: SetterFunc.self)
    }()

    static func currentLevel() -> Int {
        guard let getter else { return 50 }
        return Int((getter(CGMainDisplayID()) * 100).rounded())
    }

    static func setLevel(_ percent: Int) {
        guard let setter else { return }
        setter(CGMainDisplayID(), Double(max(0, min(100, percent))) / 100.0)
    }
}

/// System output volume via AppleScript — public, stable, and the first
/// call prompts the standard one-time "Overwatch Node wants to control System
/// Events" automation permission, unlike brightness's private-API route.
enum SystemVolume {
    static func currentLevel() -> Int {
        guard let output = AppleScriptRunner.run("output volume of (get volume settings)") else { return 50 }
        return Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 50
    }

    static func setLevel(_ percent: Int) {
        AppleScriptRunner.run("set volume output volume \(max(0, min(100, percent)))")
    }
}

/// Opens the built-in Screenshot app (com.apple.screenshot.launcher) — the
/// same on-screen capture toolbar Cmd+Shift+5 opens — rather than
/// triggering a capture directly. No permission needed, unlike the
/// CGEvent-based key-simulation approach this replaced.
enum ScreenshotTrigger {
    private static let appURL = URL(fileURLWithPath: "/System/Applications/Utilities/Screenshot.app")

    static func trigger() {
        NSWorkspace.shared.open(appURL)
    }
}

/// Locks the screen via the real macOS Lock Screen shortcut
/// (Control+Command+Q) — reuses the same CGEvent injection Contextual
/// Controls shortcuts use (ActionExecutor.swift), so it needs the same
/// Accessibility permission that feature already requires. No new
/// permission category introduced.
enum ScreenLock {
    static func trigger() {
        ShortcutSender.send(keys: ["ctrl", "cmd", "q"])
    }
}

/// The same command as manually choosing Shut Down from the Apple menu, so
/// macOS's own confirmation/unsaved-changes-prompt behavior still applies —
/// this doesn't bypass it. First call prompts the standard one-time
/// "OverwatchNode wants to control System Events" Automation permission, the
/// same category `SystemVolume` already uses.
enum SystemPower {
    static func shutDown() {
        AppleScriptRunner.run("tell application \"System Events\" to shut down")
    }
}
