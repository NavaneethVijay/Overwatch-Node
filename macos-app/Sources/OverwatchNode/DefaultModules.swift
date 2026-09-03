import Foundation

/// Modules that ship "in the box" — copied out to ModuleStore.directory once
/// on first launch (never overwritten after that, so hand-editing a seeded
/// file sticks). Adding another built-in app later is just another entry
/// here; it needs no other Swift changes, same as a fully external module.
enum DefaultModules {
    static let all: [(filename: String, json: String)] = [
        ("chrome.json", chrome),
        ("edge.json", edge),
        ("warp.json", warp),
        ("window-management.json", windowManagement),
    ]

    /// The only entry in `protectedBundleIds` (see ModuleStore) — a
    /// permanent, non-deletable built-in, not tied to any real macOS app.
    /// `"com.overwatchnode.windowManagement"` is a made-up id namespaced under
    /// this app's own bundle id (`com.navaneeth.overwatchnode`), never a real
    /// app's bundle id, so it can never collide with an actual frontmost
    /// app. Ported near-verbatim (2026-09-02) from what was previously
    /// `mobile-app/src/modules/windowManagement.ts` — a client-owned TS
    /// constant — now real Mac-JSON so it's editable via ModuleEditorView
    /// like any other module (the user can add custom sections/buttons/
    /// Projects on top; the Tiling/Spaces & Windows sections below are
    /// invisible to that editor since every control in them is
    /// `capability`-kind, same protection Chrome/Edge's dynamicList Tabs
    /// section already gets — see SectionsEditor.isEditable).
    ///
    /// `window.tile` = real Accessibility-API tiling (WindowTiler.swift).
    /// `system.symbolicHotkey` = the AppleScript System-Events workaround
    /// for macOS's Mission Control/Spaces/App Exposé shortcuts, which
    /// plain CGEvent-posted keystrokes were confirmed not to trigger even
    /// with the exact correct, enabled key combo (see SymbolicHotkeySender
    /// in ActionExecutor.swift) — keyCode values match KeyCode.map.
    private static let windowManagement = """
    {
      "bundleId": "com.overwatchnode.windowManagement",
      "displayName": "Window Management",
      "sections": [
        {
          "title": "Tiling",
          "controls": [
            { "type": "button", "label": "Left Half", "icon": "tile-left-half", "action": { "kind": "capability", "id": "window.tile", "params": { "preset": "leftHalf" } } },
            { "type": "button", "label": "Right Half", "icon": "tile-right-half", "action": { "kind": "capability", "id": "window.tile", "params": { "preset": "rightHalf" } } },
            { "type": "button", "label": "Top Half", "icon": "tile-top-half", "action": { "kind": "capability", "id": "window.tile", "params": { "preset": "topHalf" } } },
            { "type": "button", "label": "Bottom Half", "icon": "tile-bottom-half", "action": { "kind": "capability", "id": "window.tile", "params": { "preset": "bottomHalf" } } },
            { "type": "button", "label": "Top Left", "icon": "tile-top-left", "action": { "kind": "capability", "id": "window.tile", "params": { "preset": "topLeft" } } },
            { "type": "button", "label": "Top Right", "icon": "tile-top-right", "action": { "kind": "capability", "id": "window.tile", "params": { "preset": "topRight" } } },
            { "type": "button", "label": "Bottom Left", "icon": "tile-bottom-left", "action": { "kind": "capability", "id": "window.tile", "params": { "preset": "bottomLeft" } } },
            { "type": "button", "label": "Bottom Right", "icon": "tile-bottom-right", "action": { "kind": "capability", "id": "window.tile", "params": { "preset": "bottomRight" } } },
            { "type": "button", "label": "Maximize", "icon": "tile-maximize", "action": { "kind": "capability", "id": "window.tile", "params": { "preset": "maximize" } } },
            { "type": "button", "label": "Center", "icon": "tile-center", "action": { "kind": "capability", "id": "window.tile", "params": { "preset": "center" } } }
          ]
        },
        {
          "title": "Spaces & Windows",
          "controls": [
            { "type": "button", "label": "Previous Space", "icon": "space-prev", "action": { "kind": "capability", "id": "system.symbolicHotkey", "params": { "keyCode": "123", "modifiers": "control" } } },
            { "type": "button", "label": "Next Space", "icon": "space-next", "action": { "kind": "capability", "id": "system.symbolicHotkey", "params": { "keyCode": "124", "modifiers": "control" } } },
            { "type": "button", "label": "Cycle Windows", "icon": "cycle-windows", "action": { "kind": "capability", "id": "system.symbolicHotkey", "params": { "keyCode": "50", "modifiers": "cmd" } } },
            { "type": "button", "label": "Mission Control", "icon": "mission-control", "action": { "kind": "capability", "id": "system.symbolicHotkey", "params": { "keyCode": "126", "modifiers": "control" } } },
            { "type": "button", "label": "App Exposé", "icon": "app-expose", "action": { "kind": "capability", "id": "system.symbolicHotkey", "params": { "keyCode": "125", "modifiers": "control" } } }
          ]
        }
      ]
    }
    """

    private static let chrome = """
    {
      "bundleId": "com.google.Chrome",
      "displayName": "Chrome",
      "sections": [
        {
          "title": "Tab Controls",
          "controls": [
            { "type": "button", "label": "New Tab", "icon": "new-tab", "action": { "kind": "shortcut", "keys": ["cmd", "t"] } },
            { "type": "button", "label": "Close Tab", "icon": "close-tab", "action": { "kind": "shortcut", "keys": ["cmd", "w"] } },
            { "type": "button", "label": "Reload", "icon": "reload", "action": { "kind": "shortcut", "keys": ["cmd", "r"] } }
          ]
        },
        {
          "title": "Tabs",
          "controls": [
            { "type": "dynamicList", "provider": "browser.tabs", "itemAction": { "kind": "capability", "id": "browser.tabs.activate" } }
          ]
        }
      ]
    }
    """

    /// Identical shape to Chrome's — same shortcuts (standard macOS browser
    /// conventions, honored identically by every browser), same
    /// `browser.tabs` provider/capability names (BrowserTabs.swift dispatches
    /// internally by bundleId). Only bundleId/displayName differ.
    private static let edge = """
    {
      "bundleId": "com.microsoft.edgemac",
      "displayName": "Edge",
      "sections": [
        {
          "title": "Tab Controls",
          "controls": [
            { "type": "button", "label": "New Tab", "icon": "new-tab", "action": { "kind": "shortcut", "keys": ["cmd", "t"] } },
            { "type": "button", "label": "Close Tab", "icon": "close-tab", "action": { "kind": "shortcut", "keys": ["cmd", "w"] } },
            { "type": "button", "label": "Reload", "icon": "reload", "action": { "kind": "shortcut", "keys": ["cmd", "r"] } }
          ]
        },
        {
          "title": "Tabs",
          "controls": [
            { "type": "dynamicList", "provider": "browser.tabs", "itemAction": { "kind": "capability", "id": "browser.tabs.activate" } }
          ]
        }
      ]
    }
    """

    /// Brought back (2026-09-01), but only ever pure keyboard shortcuts this
    /// time — ported from a user-supplied Deckpilot (a separate macOS
    /// StreamDeck-style app) template at ~/Downloads/warp/layout.json.
    /// Deliberately dropped from the port: per-button `color` (clashes with
    /// the app's cyan/magenta-only palette — no other module gets a custom
    /// accent either) and the fixed row/column grid positions (this app's
    /// controls just flow in listed order via flexWrap, unlike Deckpilot's
    /// grid). Since every control here is a plain CGEvent shortcut, none of
    /// the pid/tty-heuristic problems that came up building Warp's old
    /// Tabs/Scripts/Git sections apply — this is the exact same "generic
    /// shortcut button" mechanism Chrome/Edge's Tab Controls already use.
    private static let warp = """
    {
      "bundleId": "dev.warp.Warp-Stable",
      "displayName": "Warp",
      "sections": [
        {
          "title": "Shortcuts",
          "controls": [
            { "type": "button", "label": "New Tab", "icon": "new-tab", "action": { "kind": "shortcut", "keys": ["cmd", "t"] } },
            { "type": "button", "label": "Split Pane", "icon": "split-pane", "action": { "kind": "shortcut", "keys": ["cmd", "d"] } },
            { "type": "button", "label": "Block Up", "icon": "block-up", "action": { "kind": "shortcut", "keys": ["cmd", "up"] } },
            { "type": "button", "label": "Block Down", "icon": "block-down", "action": { "kind": "shortcut", "keys": ["cmd", "down"] } },
            { "type": "button", "label": "Search", "icon": "search", "action": { "kind": "shortcut", "keys": ["cmd", "f"] } },
            { "type": "button", "label": "Clear", "icon": "clear", "action": { "kind": "shortcut", "keys": ["cmd", "k"] } },
            { "type": "button", "label": "Previous Tab", "icon": "tab-prev", "action": { "kind": "shortcut", "keys": ["cmd", "shift", "["] } },
            { "type": "button", "label": "Next Tab", "icon": "tab-next", "action": { "kind": "shortcut", "keys": ["cmd", "shift", "]"] } }
          ]
        }
      ]
    }
    """
}
