import Foundation

/// The `browser.tabs` dynamic provider and its `browser.tabs.activate`
/// capability, keyed by bundleId so the same module JSON (and the same
/// provider/capability names) work across browsers as they're added.
/// Chrome and Edge are both Chromium under the hood and expose the exact
/// same AppleScript scripting terms (`tabs of window`, `active tab index`,
/// `id of tab`), so one implementation covers both — only the target app
/// name differs. Firefox has no AppleScript scripting dictionary at all, so
/// it can't be added this way; Safari's Tab class has no persistent `id`
/// (would need window+index-based identification instead) and isn't
/// implemented yet.
enum BrowserTabs {
    /// bundleId -> the app name AppleScript's `tell application` needs.
    /// Values are our own constants, never external input, so interpolating
    /// them into a script below carries no injection risk.
    private static let chromiumAppNames: [String: String] = [
        "com.google.Chrome": "Google Chrome",
        "com.microsoft.edgemac": "Microsoft Edge",
    ]

    static func list(bundleId: String) -> [DynamicListItem] {
        guard let appName = chromiumAppNames[bundleId] else { return [] }
        return listChromiumTabs(appName: appName)
    }

    static func activate(bundleId: String, tabId: String?) {
        guard let tabId, tabId.allSatisfy(\.isNumber), let appName = chromiumAppNames[bundleId] else { return }
        activateChromiumTab(appName: appName, tabId: tabId)
    }

    /// ASCII Unit Separator — a real "|" or "\n" can legitimately appear in
    /// a page title (e.g. "Site Name | Article"), which would silently
    /// corrupt naive delimiter-based parsing. This control character never
    /// does.
    private static let fieldSeparator = "\u{1F}"

    private static func listChromiumTabs(appName: String) -> [DynamicListItem] {
        let script = """
        tell application "\(appName)"
            set out to ""
            repeat with w in windows
                set activeIdx to active tab index of w
                set tabList to tabs of w
                repeat with i from 1 to count of tabList
                    set t to item i of tabList
                    set out to out & (id of t as string) & "\(fieldSeparator)" & (title of t) & "\(fieldSeparator)" & (URL of t) & "\(fieldSeparator)" & (i = activeIdx) & "\\n"
                end repeat
            end repeat
            return out
        end tell
        """
        guard let output = AppleScriptRunner.run(script) else { return [] }
        return output
            .split(separator: "\n")
            .compactMap { line -> DynamicListItem? in
                let parts = String(line).components(separatedBy: fieldSeparator)
                guard parts.count == 4 else { return nil }
                return DynamicListItem(id: parts[0], title: parts[1], url: parts[2], active: parts[3] == "true")
            }
    }

    /// tabId is pre-validated as digits-only by `activate(bundleId:tabId:)`
    /// before reaching here, so it's safe to interpolate directly into the
    /// AppleScript source.
    private static func activateChromiumTab(appName: String, tabId: String) {
        let script = """
        tell application "\(appName)"
            repeat with w in windows
                set tabList to tabs of w
                repeat with i from 1 to count of tabList
                    if (id of item i of tabList as string) = "\(tabId)" then
                        set active tab index of w to i
                        set index of w to 1
                        activate
                        return
                    end if
                end repeat
            end repeat
        end tell
        """
        AppleScriptRunner.run(script)
    }
}
