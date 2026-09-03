import AppKit

/// Wraps NSWorkspace: lists the currently open apps and notifies whenever
/// that list or the frontmost app could have changed, so the phone can be
/// sent a fresh snapshot.
final class AppMonitor: NSObject {
    /// Fired on activation, launch, *and* termination — a phone that only
    /// hears about focus changes never learns about a newly launched app
    /// until something happens to reactivate an app it already knew about.
    var onAppsChanged: (() -> Void)?

    func start() {
        let center = NSWorkspace.shared.notificationCenter
        for name: Notification.Name in [
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
        ] {
            center.addObserver(self, selector: #selector(appsChanged), name: name, object: nil)
        }
    }

    @objc private func appsChanged() {
        onAppsChanged?()
    }

    /// Only "regular" apps (the ones with a Dock icon) — background agents
    /// and helpers would just be noise in the grid.
    func runningApps() -> [AppInfo] {
        let frontmostId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> AppInfo? in
                guard let bundleId = app.bundleIdentifier, let name = app.localizedName else {
                    return nil
                }
                return AppInfo(
                    bundleId: bundleId,
                    name: name,
                    iconPngBase64: pngBase64(for: app.icon),
                    isFrontmost: bundleId == frontmostId,
                    isRunning: true
                )
            }
    }

    /// Every installed app, not just running ones — the "All Nodes" launcher
    /// list. There's no public API that just hands this back, so this scans
    /// the same directories the Dock/Spotlight draw from. Misses apps
    /// installed somewhere non-standard, which is an acceptable v1 gap.
    private static let searchDirectories = [
        "/Applications",
        "/System/Applications",
        "/System/Applications/Utilities",
        NSHomeDirectory() + "/Applications",
    ]

    /// The expensive part (directory scan + `Bundle` load + icon render/
    /// encode for every installed app — ~93 apps on this Mac) doesn't
    /// change between calls except when something is actually installed, so
    /// it's cached here rather than redone on every `installedApps()` call.
    /// Previously this ran in full on *every* app activation/launch/
    /// termination system-wide (`AppDelegate.broadcastSnapshot`, fired via
    /// `onAppsChanged`), which was the actual source of general Mac-app
    /// lagginess — not a hang, just real per-switch cost multiplied by every
    /// app switch on the whole machine, phone connected or not.
    ///
    /// `static` rather than per-instance: `ModulesView`'s "Add Module" sheet
    /// creates its own throwaway `AppMonitor()` (`.onAppear { AppMonitor().
    /// installedApps() }`), which would otherwise never benefit from
    /// AppDelegate's long-lived instance already having scanned. Every
    /// current call site runs on main (NSWorkspace notifications always post
    /// on main; SwiftUI's `onAppear` runs on main), so this needs no locking
    /// — same invariant as `AppDelegate`'s `currentModuleBundleId`. The
    /// pngBase64 rendering behind this cache uses `NSGraphicsContext`, which
    /// must stay on main (see NowPlayingArtwork's doc for the confirmed real
    /// bug this project already hit doing image rendering off main) — so
    /// this cache is the fix for the sheet's stall, not a background
    /// dispatch.
    private static var installedAppsCache: [(bundleId: String, name: String, iconPngBase64: String)]?

    func installedApps() -> [AppInfo] {
        let frontmostId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        let runningByBundleId = Dictionary(
            NSWorkspace.shared.runningApplications.compactMap { app -> (String, NSRunningApplication)? in
                guard let id = app.bundleIdentifier else { return nil }
                return (id, app)
            },
            uniquingKeysWith: { first, _ in first }
        )

        var base = Self.installedAppsCache ?? scanInstalledApps()
        // A bundle id that's running but missing from the cache means a
        // genuinely new app was installed and launched since the last scan
        // (or this is the very first call) — rescan once so it shows up,
        // rather than staying invisible until some unrelated cache miss.
        let cachedIds = Set(base.map(\.bundleId))
        if !runningByBundleId.keys.allSatisfy({ cachedIds.contains($0) }) {
            base = scanInstalledApps()
        }

        let results: [AppInfo] = base.map { app in
            AppInfo(
                bundleId: app.bundleId,
                name: app.name,
                iconPngBase64: app.iconPngBase64,
                isFrontmost: app.bundleId == frontmostId,
                isRunning: runningByBundleId[app.bundleId] != nil
            )
        }
        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    @discardableResult
    private func scanInstalledApps() -> [(bundleId: String, name: String, iconPngBase64: String)] {
        var seenBundleIds = Set<String>()
        var results: [(bundleId: String, name: String, iconPngBase64: String)] = []

        for directory in Self.searchDirectories {
            guard let entries = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
                continue
            }
            for entry in entries where entry.hasSuffix(".app") {
                let path = directory + "/" + entry
                guard let bundle = Bundle(path: path), let bundleId = bundle.bundleIdentifier else {
                    continue
                }
                guard seenBundleIds.insert(bundleId).inserted else { continue }

                let name = (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
                    ?? (bundle.infoDictionary?["CFBundleName"] as? String)
                    ?? (entry as NSString).deletingPathExtension

                results.append((
                    bundleId: bundleId,
                    name: name,
                    iconPngBase64: pngBase64(for: NSWorkspace.shared.icon(forFile: path))
                ))
            }
        }

        Self.installedAppsCache = results
        return results
    }

    func activate(bundleId: String) {
        NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == bundleId })?
            .activate(options: [.activateIgnoringOtherApps])
    }

    /// Activates if already running; otherwise launches it. Used by the "All
    /// Nodes" tab, where tapping an app that isn't open yet should open it.
    func open(bundleId: String) {
        if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) {
            running.activate(options: [.activateIgnoringOtherApps])
            return
        }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else { return }
        NSWorkspace.shared.open(url)
    }

    /// A normal, cancelable quit (same as Cmd+Q) — respects an app's own
    /// "unsaved changes?" prompt rather than force-killing it.
    func close(bundleId: String) {
        NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == bundleId })?
            .terminate()
    }

    /// `NSRunningApplication.icon` hands back whatever resolution the app
    /// bundle ships (often 1024x1024 or larger) — PNG-encoding that
    /// unresized bloated a 7-app list to a 16+ MB JSON payload, which is
    /// what was actually behind every "laggy/buggy" connection symptom.
    /// Render into a small fixed-size bitmap first so each icon is a few KB.
    private func pngBase64(for image: NSImage?, pixelSize: Int = 64) -> String {
        guard
            let image,
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: pixelSize,
                pixelsHigh: pixelSize,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        else { return "" }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(
            in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
        NSGraphicsContext.restoreGraphicsState()

        guard let png = rep.representation(using: .png, properties: [:]) else { return "" }
        return png.base64EncodedString()
    }
}
