import ApplicationServices
import Cocoa
import CoreGraphics

/// Standard ANSI-US virtual keycodes for the keys a module's keyboard
/// shortcuts are likely to need. Not exhaustive — add to this as new
/// modules need a key it doesn't cover yet.
private enum KeyCode {
    static let map: [String: CGKeyCode] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9,
        "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17,
        "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23, "9": 25, "7": 26, "8": 28, "0": 29,
        "o": 31, "u": 32, "i": 34, "p": 35, "l": 37, "j": 38, "k": 40, "n": 45, "m": 46,
        "tab": 48, "space": 49, "return": 36, "delete": 51, "escape": 53,
        "[": 33, "]": 30, "backtick": 50,
        "left": 123, "right": 124, "down": 125, "up": 126,
    ]
}

/// Interprets a `ModuleAction` in the context of whichever app is currently
/// the active module (see AppDelegate) — module JSON never names a bundle
/// id in its actions, so capabilities that need one (browser tabs, etc.)
/// receive it as a parameter here rather than encoding it themselves.
enum ActionExecutor {
    /// Capability ids that touch AppKit (`NSScreen`, `NSWorkspace`, ...)
    /// and must run on the main thread. Everything else here — plain
    /// shortcuts (CGEvent posting) and every other capability (AppleScript
    /// via AppleScriptRunner, CGEvent typing via KeyboardTyper) — doesn't
    /// touch AppKit and must NOT be forced onto main: a blocking osascript
    /// call there can deadlock the whole app if it needs to show a
    /// permission dialog (see AppDelegate's sendSnapshot/onSetVolume,
    /// which hit exactly this and were fixed the same way). AppDelegate's
    /// `onInvokeControlAction` reads this to pick the right queue.
    private static let mainThreadCapabilityIds: Set<String> = ["window.tile"]

    static func requiresMainThread(_ action: ModuleAction) -> Bool {
        guard action.kind == "capability", let id = action.id else { return false }
        return mainThreadCapabilityIds.contains(id)
    }

    private static let knownModifiers: Set<String> = ["cmd", "command", "shift", "option", "alt", "ctrl", "control"]

    /// Whether a single shortcut token (one entry of `ModuleAction.keys`) is
    /// something `ShortcutSender` actually knows how to send — either a
    /// recognized modifier name or a key in `KeyCode.map`. Used by
    /// ModuleValidator to reject an uploaded module referencing an unknown
    /// key, the same reasoning ModuleEditorView's `knownMainKeys` picker
    /// already applies at the authoring end.
    static func isKnownShortcutToken(_ token: String) -> Bool {
        let lowered = token.lowercased()
        return knownModifiers.contains(lowered) || KeyCode.map[lowered] != nil
    }

    static func execute(_ action: ModuleAction, contextBundleId: String) {
        switch action.kind {
        case "shortcut":
            guard let keys = action.keys else { return }
            ShortcutSender.send(keys: keys)
        case "paste":
            guard let text = action.text, !text.isEmpty else { return }
            TextPaster.paste(text, contextBundleId: contextBundleId, pressReturn: action.pressReturn ?? false)
        case "capability":
            guard let id = action.id else { return }
            CapabilityRegistry.run(id: id, bundleId: contextBundleId, params: action.params ?? [:])
        default:
            AppLog.lifecycle.error("unknown action kind: \(action.kind, privacy: .public)")
        }
    }
}

/// Generic keyboard-shortcut injection via CGEvent — this is what lets most
/// module buttons be pure JSON with zero per-app Swift code. Requires the
/// Accessibility permission (System Settings > Privacy & Security >
/// Accessibility); until the proper companion-app permissions UI exists,
/// this just logs and opens that settings pane on first denial rather than
/// silently doing nothing.
enum ShortcutSender {
    static func send(keys: [String]) {
        guard AXIsProcessTrusted() else {
            AppLog.lifecycle.error("Accessibility permission not granted — cannot send shortcut \(keys, privacy: .public)")
            requestPermission()
            return
        }

        var flags: CGEventFlags = []
        var mainKey: String?
        for key in keys {
            switch key.lowercased() {
            case "cmd", "command": flags.insert(.maskCommand)
            case "shift": flags.insert(.maskShift)
            case "option", "alt": flags.insert(.maskAlternate)
            case "ctrl", "control": flags.insert(.maskControl)
            default: mainKey = key.lowercased()
            }
        }

        guard let mainKey, let keyCode = KeyCode.map[mainKey] else {
            AppLog.lifecycle.error("shortcut has no recognized main key: \(keys, privacy: .public)")
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)
        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else { return }

        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    /// Prompts once via the system's own "OverwatchNode wants to control your
    /// computer" dialog, which — if allowed — drops the app straight into
    /// the Accessibility settings list already toggled on.
    private static func requestPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }
}

/// Sends a keystroke via AppleScript's `System Events` `key code ... using
/// {...}` instead of `ShortcutSender`'s CGEvent injection.
///
/// Why this exists as a *separate* mechanism rather than just fixing
/// `ShortcutSender`: macOS's "symbolic hotkeys" — Mission Control, Spaces
/// navigation, App Exposé, and similar system-reserved combos — are
/// resolved by a low-level system component that, per multiple independent
/// reports from other macOS automation tool authors, often does not
/// respond to a plain synthetic `CGEventPost` the way an ordinary app-level
/// shortcut does, even though the exact same modifier+keycode is correct
/// and the combo is confirmed enabled in System Settings. Routing through
/// `System Events` instead (the same automation pathway this app already
/// uses for AppleScript-based capabilities, and already gated on the
/// existing Automation permission) is the documented workaround. This is
/// deliberately NOT used for ordinary app shortcuts (Cmd+T etc., still
/// `ShortcutSender`) — those already work fine via CGEvent, and an
/// `osascript` subprocess per keystroke is meaningfully slower than an
/// in-process CGEvent post, which would make already-working shortcut
/// buttons feel more sluggish for no benefit.
enum SymbolicHotkeySender {
    private static let modifierClauses: [String: String] = [
        "cmd": "command down", "command": "command down",
        "shift": "shift down",
        "option": "option down", "alt": "option down",
        "ctrl": "control down", "control": "control down",
    ]

    static func send(keyCode: Int, modifiers: [String]) {
        let clauses = modifiers.compactMap { modifierClauses[$0.lowercased()] }
        let usingClause = clauses.isEmpty ? "" : " using {\(clauses.joined(separator: ", "))}"
        AppleScriptRunner.run("tell application \"System Events\" to key code \(keyCode)\(usingClause)")
    }
}

/// Named Swift functions a `"capability"` action can invoke — the escape
/// hatch for anything a keystroke can't do. Unknown ids are logged and
/// ignored rather than crashing, since module JSON can reference a
/// capability id that a future Mac-app version hasn't implemented yet.
enum CapabilityRegistry {
    static func run(id: String, bundleId: String, params: [String: String]) {
        switch id {
        case "browser.tabs.activate":
            BrowserTabs.activate(bundleId: bundleId, tabId: params["id"])
        case "window.tile":
            WindowTiler.tile(preset: params["preset"])
        case "system.symbolicHotkey":
            guard let keyCodeString = params["keyCode"], let keyCode = Int(keyCodeString) else { return }
            let modifiers = (params["modifiers"] ?? "").split(separator: ",").map(String.init)
            SymbolicHotkeySender.send(keyCode: keyCode, modifiers: modifiers)
        default:
            AppLog.lifecycle.error("unknown capability id: \(id, privacy: .public)")
        }
    }
}

/// Named data sources a `dynamicList` control can bind to.
enum DynamicProviders {
    static func resolve(_ provider: String, bundleId: String) -> [DynamicListItem] {
        switch provider {
        case "browser.tabs":
            return BrowserTabs.list(bundleId: bundleId)
        default:
            AppLog.lifecycle.error("unknown dynamic provider: \(provider, privacy: .public)")
            return []
        }
    }
}

/// Checks the target app is still actually frontmost immediately before
/// typing into it — the phone's view of "what's active" can be stale by the
/// time a `"paste"` button is tapped if the user has since switched apps on
/// the Mac, and blindly injecting keystrokes into whatever's now frontmost
/// would be a real hazard. This is what backs every `"paste"` action
/// (module builder / Projects buttons) — see ModuleAction's doc comment.
enum TextPaster {
    static func paste(_ text: String, contextBundleId: String, pressReturn: Bool) {
        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == contextBundleId else {
            AppLog.lifecycle.error("refusing paste — \(contextBundleId, privacy: .public) is no longer frontmost")
            return
        }
        KeyboardTyper.type(text, pressReturn: pressReturn)
    }
}

/// Generic keyboard text injection via CGEvent unicode-string events — works
/// regardless of whether the target app has any scripting support (Warp has
/// none). Originally built just for terminal "run" actions (git pull/push,
/// npm scripts, hence the old name "TerminalTyper"), now the mechanism
/// behind any `"paste"` action for any app.
enum KeyboardTyper {
    static func type(_ text: String, pressReturn: Bool = true) {
        guard AXIsProcessTrusted() else {
            AppLog.lifecycle.error("Accessibility permission not granted — cannot type into terminal")
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)
        let utf16 = Array(text.utf16)

        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        else { return }

        keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        guard pressReturn else { return }
        guard
            let returnDown = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: true),
            let returnUp = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: false)
        else { return }
        returnDown.post(tap: .cghidEventTap)
        returnUp.post(tap: .cghidEventTap)
    }
}
