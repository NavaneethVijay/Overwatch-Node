import Foundation

/// Wire protocol shared with the Android app. Keep this in sync with
/// `mobile-app/src/net/connection.ts` — see design/DESIGN_SYSTEM.md and the
/// project plan for the message set this MVP implements.

struct AppInfo: Encodable {
    let bundleId: String
    let name: String
    let iconPngBase64: String
    let isFrontmost: Bool
    let isRunning: Bool
}

struct AppListMessage: Encodable {
    let type: String = "app_list"
    let apps: [AppInfo]
}

/// Every installed app (not just running ones) — the phone's "All Nodes"
/// launcher tab. Each entry still carries isRunning/isFrontmost so the phone
/// can show live status without a second lookup.
struct InstalledAppsMessage: Encodable {
    let type: String = "installed_apps"
    let apps: [AppInfo]
}

struct BrightnessMessage: Encodable {
    let type: String = "brightness_state"
    let level: Int
}

struct VolumeMessage: Encodable {
    let type: String = "volume_state"
    let level: Int
}

struct BluetoothDevice: Encodable {
    let name: String
    let connected: Bool
}

struct BluetoothDevicesMessage: Encodable {
    let type: String = "bluetooth_devices"
    let devices: [BluetoothDevice]
}

/// Sent right after `client_hello` when the phone's `deviceId` isn't
/// trusted yet — the phone should show a "enter the code shown on your
/// Mac" screen and hold everything else until `pairing_status` confirms.
struct PairingRequiredMessage: Encodable {
    let type: String = "pairing_required"
}

/// Reply to `submit_pairing_code`. `paired: true` means the device is now
/// trusted (and the normal connection snapshot follows immediately after);
/// `false` carries a human-readable `error` for the phone to show, and the
/// phone may retry (up to WebSocketServer's maxPairingAttempts) without
/// reconnecting.
struct PairingStatusMessage: Encodable {
    let type: String = "pairing_status"
    let paired: Bool
    let error: String?
}

/// Broadcast on a poll tick (see AppDelegate's nowPlayingTimer) whenever
/// Now Playing metadata has actually changed since the last broadcast —
/// see NowPlayingClient for how this gets read. All fields but `playing`
/// are nil when nothing is currently playing.
struct NowPlayingMessage: Encodable {
    let type: String = "now_playing_state"
    let title: String?
    let artist: String?
    let album: String?
    let bundleIdentifier: String?
    /// Base64 PNG, already resized to a small fixed size — see
    /// NowPlayingArtwork.resizedPngBase64. Never the raw artwork bytes.
    let artworkPngBase64: String?
    let playing: Bool
}

/// One control's action. `"shortcut"` is executed generically (CGEvent key
/// injection, see ActionExecutor) with zero per-app Swift code; `"capability"`
/// calls a named Swift function (see CapabilityRegistry) for anything a
/// keystroke can't do — reserved for built-in modules, never offered by the
/// module builder UI or accepted from an uploaded file (see
/// ModuleValidator). `"paste"` types `text` into whatever's currently
/// frontmost (see TextPaster), optionally pressing Enter afterward if
/// `pressReturn` is true — the module-builder/Projects equivalent of a
/// shortcut for actions that aren't a single keystroke. `params` is only
/// ever populated by the phone, echoing a dynamic list item's id back (e.g.
/// which browser tab was tapped) — module JSON itself never sets it.
/// `var`, not `let` — ModuleEditorView.swift edits these in place through
/// SwiftUI bindings (`~/Library/Application Support/OverwatchNode/Modules/*.json`
/// is otherwise hand-edited or generated once at import time, never
/// mutated in-process elsewhere, so this doesn't change behavior anywhere
/// outside that editor).
struct ModuleAction: Codable {
    var kind: String
    var keys: [String]?
    var id: String?
    var params: [String: String]?
    var text: String?
    var pressReturn: Bool?
}

/// A single control in a module's UI — either a static button or a
/// server-populated list (see `provider`/`dynamicData` on ActiveModuleMessage).
/// `var` fields for the same reason as `ModuleAction` above.
struct ModuleControl: Codable {
    var type: String
    var label: String?
    var icon: String?
    var action: ModuleAction?
    var provider: String?
    var itemAction: ModuleAction?
}

struct ModuleSection: Codable {
    var title: String
    var controls: [ModuleControl]
}

/// A named, reorderable set of custom sections attached to one app's
/// module — e.g. Warp shows a "Projects" list; tapping one shows that
/// project's own buttons. Always user-authored (via the module builder or
/// an uploaded file), never seeded by a built-in module, so its sections
/// are restricted the same way the builder restricts any user-created
/// content — see ModuleValidator.
struct Project: Codable, Identifiable {
    var id: String
    var name: String
    var sections: [ModuleSection]
}

/// A module's static definition, loaded from a JSON file in
/// ModuleStore.directory — see that file for where these live and how
/// defaults get seeded there. `projects`/`currentProjectId` are optional so
/// every existing seeded module file (chrome/edge/warp) keeps decoding
/// unchanged with no Projects at all.
struct ModuleSchema: Codable {
    var bundleId: String
    var displayName: String
    var sections: [ModuleSection]
    var projects: [Project]?
    var currentProjectId: String?
}

/// One row of a dynamic list (e.g. one browser tab). `url` is
/// browser.tabs-specific (used by the phone to look up a favicon) — empty
/// string for any future provider that has no notion of a URL.
struct DynamicListItem: Codable {
    let id: String
    let title: String
    let url: String
    let active: Bool
}

/// Sent whenever the frontmost app changes. `hasModule: false` (sections
/// empty) tells the phone plainly "no controls for this app" rather than
/// leaving the previous app's module showing stale. `dynamicData` is keyed
/// by provider name and only populated for sections that declare one.
/// `projects`/`currentProjectId` mirror ModuleSchema's fields directly —
/// always the full list (empty array, not omitted, when there are none),
/// since Projects never contain a dynamicList control, so unlike
/// `dynamicData` there's no per-project data to resolve separately.
struct ActiveModuleMessage: Encodable {
    let type: String = "active_module"
    let bundleId: String
    let displayName: String
    let hasModule: Bool
    let sections: [ModuleSection]
    let dynamicData: [String: [DynamicListItem]]
    let projects: [Project]
    let currentProjectId: String?
}

/// Full data for a "built-in" module — one that's part of OverwatchNode itself
/// rather than tied to whichever app happens to be frontmost (Window
/// Management's Tiling/Spaces buttons, so far the only one) — fetched
/// on-demand (`request_builtin_module`) rather than pushed on a
/// frontmost-app change, since there's no "frontmost app" event to hang
/// that push off of. Otherwise the exact same shape as ActiveModuleMessage
/// minus `hasModule` (always true here — the phone only asks for a
/// built-in module it already knows exists, see modules/builtInApps.ts).
struct BuiltinModuleMessage: Encodable {
    let type: String = "builtin_module_data"
    let bundleId: String
    let displayName: String
    let sections: [ModuleSection]
    let dynamicData: [String: [DynamicListItem]]
    let projects: [Project]
    let currentProjectId: String?
}

/// Envelope for messages arriving from the phone: `activate_app` (bring an
/// already-running app to front), `open_app` (activate if running, else
/// launch), `close_app` (quit a running app), `set_brightness`/`set_volume`
/// (0-100, via `level`), `trigger_screenshot`, `request_bluetooth` (manual
/// refresh), `invoke_control_action` (a module control was tapped, via
/// `action`), `trigger_lock_screen`, `trigger_shutdown`,
/// `trigger_media_play_pause`/`trigger_media_next`/`trigger_media_previous`
/// (Now Playing transport controls, see MediaKeySender), `select_project`
/// (via `bundleId` + `projectId` — persists and rebroadcasts which Project
/// is "current" for that app, see ModuleStore.setCurrentProject),
/// `request_builtin_module` (via `bundleId` — replies directly to the
/// requesting session with a `BuiltinModuleMessage`, see
/// AppDelegate.handleRequestBuiltinModule), `client_hello` (sent once right
/// after connecting, via `deviceName` + a
/// stable `deviceId` the phone generates once and persists — this is the
/// pairing identity WebSocketServer checks against DevicePairing's trust
/// store), `submit_pairing_code` (via `code` — see WebSocketServer's
/// pairing flow). Unknown types are ignored rather than erroring, since the
/// protocol will keep growing. Every type except `client_hello` and
/// `submit_pairing_code` is ignored outright from a session that hasn't
/// completed pairing yet — see WebSocketServer.handleIncoming.
struct IncomingMessage: Decodable {
    let type: String
    let bundleId: String?
    let level: Int?
    let action: ModuleAction?
    let deviceName: String?
    let deviceId: String?
    let code: String?
    let projectId: String?
}

enum Wire {
    static func encode(_ value: some Encodable) -> String? {
        guard let data = try? JSONEncoder().encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func decodeIncoming(_ text: String) -> IncomingMessage? {
        guard let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(IncomingMessage.self, from: data)
    }
}
