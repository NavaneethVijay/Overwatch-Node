import Foundation

/// The canonical, shared set of module icon keys — each paired with a
/// human label and an SF Symbol for the Mac-side picker preview (Android's
/// hand-drawn SVGs, keyed by the same `key`, can't be reused here — see
/// `mobile-app/src/components/icons/index.tsx`'s `MODULE_ICONS`, which
/// this list must be kept in sync with by hand; there's no auto-sync
/// mechanism). Restricting the picker to this list avoids a typo silently
/// producing a dead/fallback-icon button — the current value is always
/// included even if it's outside this list (see ModuleEditorView's
/// `options(_:including:)`), so a hand-authored module using something
/// unlisted never gets hidden from the picker.
enum ModuleIconCatalog {
    struct Entry {
        let key: String
        let label: String
        let sfSymbol: String
    }

    static let entries: [Entry] = [
        Entry(key: "new-tab", label: "New Tab", sfSymbol: "plus.square"),
        Entry(key: "close-tab", label: "Close Tab", sfSymbol: "xmark.square"),
        Entry(key: "reload", label: "Reload", sfSymbol: "arrow.clockwise"),
        Entry(key: "tabs", label: "Tabs", sfSymbol: "square.on.square"),
        Entry(key: "git-pull", label: "Git Pull", sfSymbol: "arrow.down.circle"),
        Entry(key: "git-push", label: "Git Push", sfSymbol: "arrow.up.circle"),
        Entry(key: "git-branch", label: "Git Branch", sfSymbol: "arrow.triangle.branch"),
        Entry(key: "tab-prev", label: "Previous Tab", sfSymbol: "chevron.left"),
        Entry(key: "tab-next", label: "Next Tab", sfSymbol: "chevron.right"),
        Entry(key: "split-pane", label: "Split Pane", sfSymbol: "rectangle.split.2x1"),
        Entry(key: "ai-command", label: "AI Command", sfSymbol: "sparkles"),
        Entry(key: "block-up", label: "Block Up", sfSymbol: "chevron.up"),
        Entry(key: "block-down", label: "Block Down", sfSymbol: "chevron.down"),
        Entry(key: "search", label: "Search", sfSymbol: "magnifyingglass"),
        Entry(key: "workflows", label: "Workflows", sfSymbol: "square.stack.3d.up"),
        Entry(key: "clear", label: "Clear", sfSymbol: "xmark.circle"),
        Entry(key: "tile-left-half", label: "Tile Left Half", sfSymbol: "rectangle.lefthalf.filled"),
        Entry(key: "tile-right-half", label: "Tile Right Half", sfSymbol: "rectangle.righthalf.filled"),
        Entry(key: "tile-top-half", label: "Tile Top Half", sfSymbol: "rectangle.tophalf.filled"),
        Entry(key: "tile-bottom-half", label: "Tile Bottom Half", sfSymbol: "rectangle.bottomhalf.filled"),
        Entry(key: "tile-top-left", label: "Tile Top Left", sfSymbol: "rectangle.inset.topleft.filled"),
        Entry(key: "tile-top-right", label: "Tile Top Right", sfSymbol: "rectangle.inset.topright.filled"),
        Entry(key: "tile-bottom-left", label: "Tile Bottom Left", sfSymbol: "rectangle.inset.bottomleft.filled"),
        Entry(key: "tile-bottom-right", label: "Tile Bottom Right", sfSymbol: "rectangle.inset.bottomright.filled"),
        Entry(key: "tile-maximize", label: "Maximize", sfSymbol: "rectangle.expand.vertical"),
        Entry(key: "tile-center", label: "Center", sfSymbol: "rectangle.center.inset.filled"),
        Entry(key: "space-prev", label: "Previous Space", sfSymbol: "arrow.left.square"),
        Entry(key: "space-next", label: "Next Space", sfSymbol: "arrow.right.square"),
        Entry(key: "cycle-windows", label: "Cycle Windows", sfSymbol: "square.stack"),
        Entry(key: "mission-control", label: "Mission Control", sfSymbol: "square.grid.3x3"),
        Entry(key: "app-expose", label: "App Exposé", sfSymbol: "square.on.square.dashed"),
        Entry(key: "project", label: "Project", sfSymbol: "folder"),

        // General-purpose IDE/common-action icons — for hand-authored or
        // builder-created buttons that aren't tied to a specific built-in
        // app (e.g. a custom "Build" or "Copy" button in a Project). Kept
        // in sync by hand with android-app's MODULE_ICONS, same as every
        // other entry here.
        Entry(key: "build", label: "Build", sfSymbol: "hammer"),
        Entry(key: "run", label: "Run", sfSymbol: "play"),
        Entry(key: "debug", label: "Debug", sfSymbol: "ladybug"),
        Entry(key: "stop", label: "Stop", sfSymbol: "stop.fill"),
        Entry(key: "save", label: "Save", sfSymbol: "square.and.arrow.down"),
        Entry(key: "console", label: "Console", sfSymbol: "terminal"),
        Entry(key: "copy", label: "Copy", sfSymbol: "doc.on.doc"),
        Entry(key: "paste", label: "Paste", sfSymbol: "doc.on.clipboard"),
        Entry(key: "cut", label: "Cut", sfSymbol: "scissors"),
        Entry(key: "undo", label: "Undo", sfSymbol: "arrow.uturn.backward"),
        Entry(key: "redo", label: "Redo", sfSymbol: "arrow.uturn.forward"),
        Entry(key: "delete", label: "Delete", sfSymbol: "trash"),
        Entry(key: "lock", label: "Lock", sfSymbol: "lock.fill"),
        Entry(key: "star", label: "Star", sfSymbol: "star.fill"),
        Entry(key: "settings", label: "Settings", sfSymbol: "gearshape"),
    ]

    static func entry(for key: String) -> Entry? {
        entries.first { $0.key == key }
    }
}
