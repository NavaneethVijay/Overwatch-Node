import Cocoa
import Swifter
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private let server = WebSocketServer()
    private let bonjour = BonjourAdvertiser()
    private let monitor = AppMonitor()
    private var bluetoothRefreshTimer: Timer?
    private var settingsWindow: NSWindow?

    // Now Playing — see NowPlaying.swift.
    private var nowPlayingTimer: Timer?
    private var lastNowPlaying: NowPlayingInfo?

    // Contextual Controls module state — see ModuleStore.swift.
    private var currentModuleBundleId: String?
    private var moduleRefreshTimer: Timer?
    private var lastActiveModuleJSON: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar utility, no Dock icon.
        NSApp.setActivationPolicy(.accessory)
        setUpStatusItem()

        ModuleStore.ensureSeeded()

        monitor.onAppsChanged = { [weak self] in
            self?.broadcastSnapshot()
            self?.broadcastActiveModuleIfNeeded()
        }
        monitor.start()

        // Swifter invokes all of these from its own background connection
        // threads, but everything they touch (NSWorkspace, NSRunningApplication,
        // icon rendering) is AppKit — only safe to call from the main thread.
        // Left as-is, this doesn't crash; it just hangs or misbehaves
        // intermittently, which is worse.
        server.onActivateApp = { [weak self] bundleId in
            DispatchQueue.main.async {
                self?.monitor.activate(bundleId: bundleId)
            }
        }
        server.onOpenApp = { [weak self] bundleId in
            DispatchQueue.main.async {
                self?.monitor.open(bundleId: bundleId)
            }
        }
        server.onCloseApp = { [weak self] bundleId in
            DispatchQueue.main.async {
                self?.monitor.close(bundleId: bundleId)
            }
        }
        server.onSetBrightness = { [weak self] level in
            DispatchQueue.main.async {
                DisplayBrightness.setLevel(level)
                // Echo back the level we were *asked* to set, not a fresh
                // read — re-querying was both slow (volume's re-query spawns
                // a whole extra osascript process per drag update) and
                // actively wrong for brightness, whose getter doesn't work
                // in this build (see SystemUtility.swift) and would always
                // echo back a stale fallback, snapping the phone's slider
                // back mid-drag.
                self?.broadcastBrightness(level: level)
            }
        }
        // SystemVolume.setLevel is a blocking osascript call, not AppKit —
        // it doesn't need main, and (see sendSnapshot's comment) running it
        // there is how a pending permission dialog can deadlock the whole
        // app. Global queue throughout; broadcastVolume is just JSON encode
        // + a socket write, no AppKit either.
        server.onSetVolume = { [weak self] level in
            DispatchQueue.global(qos: .userInitiated).async {
                SystemVolume.setLevel(level)
                self?.broadcastVolume(level: level)
            }
        }
        server.onTriggerScreenshot = {
            DispatchQueue.main.async {
                ScreenshotTrigger.trigger()
            }
        }
        // broadcastBluetooth (below) now dispatches its own blocking
        // system_profiler call off main, so this can call it directly —
        // already running on a Swifter background thread here anyway.
        server.onRequestBluetooth = { [weak self] in
            self?.broadcastBluetooth()
        }
        // currentModuleBundleId is only ever read/written on main (see
        // broadcastActiveModuleIfNeeded), so it's captured here first
        // rather than from whatever thread this closure fires on. From
        // there, only `window.tile`-style AppKit-dependent capabilities
        // actually need main — most module actions are AppleScript/CGEvent
        // based and must NOT be forced onto main, same reasoning (and same
        // real bug, already hit once) as sendSnapshot/onSetVolume above.
        server.onInvokeControlAction = { [weak self] action in
            DispatchQueue.main.async {
                guard let self, let bundleId = self.currentModuleBundleId else { return }
                if ActionExecutor.requiresMainThread(action) {
                    ActionExecutor.execute(action, contextBundleId: bundleId)
                } else {
                    DispatchQueue.global(qos: .userInitiated).async {
                        ActionExecutor.execute(action, contextBundleId: bundleId)
                    }
                }
            }
        }
        server.onSelectProject = { [weak self] bundleId, projectId in
            self?.handleSelectProject(bundleId: bundleId, projectId: projectId)
        }
        server.onRequestBuiltinModule = { [weak self] bundleId, session in
            self?.handleRequestBuiltinModule(bundleId: bundleId, to: session)
        }
        server.onTriggerLockScreen = {
            DispatchQueue.main.async {
                ScreenLock.trigger()
            }
        }
        // SystemPower.shutDown is a blocking osascript call — same
        // reasoning as onSetVolume above, doesn't touch AppKit, doesn't
        // need main.
        server.onTriggerShutdown = {
            DispatchQueue.global(qos: .userInitiated).async {
                SystemPower.shutDown()
            }
        }
        server.onTriggerMediaPlayPause = { [weak self] in
            DispatchQueue.main.async {
                MediaKeySender.playPause()
                self?.scheduleNowPlayingRefresh()
            }
        }
        server.onTriggerMediaNext = { [weak self] in
            DispatchQueue.main.async {
                MediaKeySender.next()
                self?.scheduleNowPlayingRefresh()
            }
        }
        server.onTriggerMediaPrevious = { [weak self] in
            DispatchQueue.main.async {
                MediaKeySender.previous()
                self?.scheduleNowPlayingRefresh()
            }
        }
        server.onClientConnected = { [weak self] session in
            DispatchQueue.main.async {
                self?.sendSnapshot(to: session)
            }
        }
        server.onPairingRequested = { deviceName, code in
            DispatchQueue.main.async {
                PairingNotifier.notify(deviceName: deviceName, code: code)
            }
        }

        do {
            try server.start()
            let name = Host.current().localizedName ?? "OverwatchNode"
            bonjour.publish(port: server.port, name: name)
            AppLog.lifecycle.info("OverwatchNode listening on port \(self.server.port, privacy: .public), local addresses: \(Host.current().addresses.joined(separator: ", "), privacy: .public)")
        } catch {
            AppLog.lifecycle.error("Failed to start server: \(String(describing: error), privacy: .public)")
        }

        // Bluetooth connect/disconnect has no notification we hook into, so
        // it's polled — cheap, tiny payload, keeps the utility tab's device
        // list live without a manual refresh.
        let timer = Timer(timeInterval: 10, repeats: true) { [weak self] _ in
            self?.broadcastBluetooth()
        }
        RunLoop.main.add(timer, forMode: .common)
        bluetoothRefreshTimer = timer

        // Now Playing has no change notification we can hook into (the perl
        // round-trip is poll-per-invocation, see NowPlaying.swift) — same
        // reasoning as Bluetooth above, poll every 4s (matches the upstream
        // reference this was ported from). scheduleNowPlayingRefresh adds
        // quick follow-up polls after a control command so the UI doesn't
        // wait a full tick to reflect it.
        let nowPlayingTimer = Timer(timeInterval: 4, repeats: true) { [weak self] _ in
            self?.pollNowPlaying()
        }
        RunLoop.main.add(nowPlayingTimer, forMode: .common)
        self.nowPlayingTimer = nowPlayingTimer
        pollNowPlaying()

        // Populate module state for whatever app is already frontmost —
        // onAppsChanged only fires on a subsequent activate/launch/terminate,
        // so without this the phone would see nothing until the next switch.
        broadcastActiveModuleIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        bluetoothRefreshTimer?.invalidate()
        nowPlayingTimer?.invalidate()
        bonjour.stop()
        server.stop()
    }

    /// Explicit, not relying on AppKit's default (which is already "don't
    /// terminate" when this isn't implemented) — this is a menu-bar
    /// accessory app; closing the Settings window's red button should only
    /// ever close that window (windowWillClose already reverts to
    /// .accessory activation policy), never quit the whole app. Quitting
    /// is exclusively the menu bar's "Quit" item.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "antenna.radiowaves.left.and.right",
            accessibilityDescription: "Overwatch Node"
        )

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item

        rebuildMenu(menu)
    }

    /// Rebuilt from scratch every time the menu is about to open (see
    /// `menuWillOpen`) rather than mutated in place — simplest way to keep
    /// the connected-devices list current without tracking item indices by
    /// hand for something that only needs to be right at the moment it's
    /// actually shown.
    private func rebuildMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(disabledMenuItem("Overwatch Node — listening on port \(server.port)"))
        menu.addItem(.separator())

        let connectedDevices = server.connectedDevices
        if connectedDevices.isEmpty {
            menu.addItem(disabledMenuItem("No devices connected"))
        } else {
            for device in connectedDevices {
                let item = NSMenuItem(title: device.name, action: #selector(disconnectDevice(_:)), keyEquivalent: "")
                item.target = self
                item.image = Self.connectedDotImage
                item.representedObject = device.id
                item.toolTip = "Click to disconnect"
                menu.addItem(item)
            }
        }
        menu.addItem(.separator())

        let openItem = NSMenuItem(title: "Open Overwatch Node…", action: #selector(openSettingsWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func disabledMenuItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    /// A small solid green dot — SF Symbol `circle.fill` recolored via a
    /// palette configuration (plain `isTemplate = false` alone doesn't add
    /// color, symbols are template/monochrome by default).
    private static let connectedDotImage: NSImage? = {
        NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Connected")?
            .withSymbolConfiguration(.init(paletteColors: [.systemGreen]))
    }()

    @objc private func disconnectDevice(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? ObjectIdentifier else { return }
        server.disconnect(id: id)
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu(menu)
    }

    @objc private func openSettingsWindow() {
        // Promoted to a normal app (Dock icon, Cmd+Tab) only while the
        // window is open — reverted in windowWillClose — so this stays a
        // background menu-bar utility the rest of the time.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let settingsWindow {
            // Re-center on every open, not just the first — otherwise a
            // window dragged elsewhere earlier in the session just gets
            // raised wherever it already is instead of "always opens
            // centered" like the user actually wants.
            settingsWindow.center()
            settingsWindow.makeKeyAndOrderFront(nil)
            return
        }

        let root = SettingsRootView(
            port: server.port,
            fetchDeviceNames: { [weak self] in self?.server.connectedDeviceNames ?? [] },
            fetchPendingPairingCode: { [weak self] in self?.server.currentPairingCode }
        )
        let hostingController = NSHostingController(rootView: root)
        // Reverted back to the original `NSWindow(contentViewController:)`
        // construction (was briefly rewritten via the designated
        // NSWindow(contentRect:styleMask:backing:defer:) initializer while
        // chasing what turned out to be a misdiagnosis — the real blank-
        // sidebar cause was an unrelated main-thread AppleScript hang, since
        // fixed, not window construction — and that rewrite is what broke
        // "close window" into "quit the whole app": something about
        // constructing the window that way, rather than via this
        // convenience initializer, changed its close-vs-terminate behavior.
        // `.resizable` is still needed (NavigationSplitView won't lay out
        // its sidebar/detail columns in a non-resizable window), so that
        // part of the fix stays; only the construction *mechanism* reverts.
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Overwatch Node"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.minSize = NSSize(width: 720, height: 480)
        // SwiftUI's .frame(idealWidth:idealHeight:) on SettingsRootView
        // was supposed to drive this window's initial size but doesn't
        // reliably reach NSHostingController's sizing through
        // NavigationSplitView — the window kept opening at its bare
        // minSize regardless. Setting the content size directly here is
        // deterministic: it's what actually shows, full stop, independent
        // of whatever SwiftUI's layout system decided internally.
        window.setContentSize(NSSize(width: 860, height: 720))
        window.delegate = self
        window.center()
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === settingsWindow else { return }
        settingsWindow = nil
        NSApp.setActivationPolicy(.accessory)
    }

    private func sendSnapshot(to session: WebSocketSession) {
        // AppKit-only work (icon rendering via NSWorkspace) — must stay on
        // main, per this file's own "every AppKit call must be main.async"
        // rule. This function is already reached via DispatchQueue.main.async
        // (see onClientConnected), so it's already on main here. But the
        // socket write itself is a separate concern from the AppKit
        // constraint: `session.writeText` is a *blocking* syscall with no
        // timeout (see WebSocketServer.networkQueue's doc) — this snapshot
        // in particular includes the installed-apps payload, the largest
        // message in the whole protocol, sent right at the moment a phone
        // first connects. Writing that on main used to mean a single slow/
        // stale write here could hang the entire app on a phone's very
        // first connection. Data gathering stays on main; encoding+writing
        // hops off onto a background queue, same as Volume/Bluetooth below.
        let runningAppsSnapshot = monitor.runningApps()
        let installedAppsSnapshot = monitor.installedApps()
        let brightnessLevel = DisplayBrightness.currentLevel()
        // Cached, not re-fetched — a fresh Now Playing read spawns a perl
        // process and can take up to ~2s, too slow to block a new
        // connection's snapshot on. Worst case this is up to 4s stale; the
        // next poll tick corrects it.
        let cachedNowPlayingJSON = lastNowPlaying.flatMap { Wire.encode(nowPlayingMessage($0)) }
        let cachedActiveModuleJSON = lastActiveModuleJSON

        // Volume (osascript) and Bluetooth (system_profiler) both shell out
        // to an external process and block synchronously until it exits.
        // Neither touches AppKit, so unlike the data above they don't need
        // main — and running them on main was a real bug: on a fresh TCC
        // grant, SystemVolume's first-ever call can trigger a one-time
        // "Overwatch Node wants to control System Events" permission dialog,
        // and if the app's own main thread is the one blocked waiting for
        // osascript to return, that dialog can never resolve either —
        // every connection deadlocked the whole app (menu bar, Settings
        // window, everything) until force quit. See AppleScriptRunner.swift.
        DispatchQueue.global(qos: .userInitiated).async {
            if let json = Wire.encode(AppListMessage(apps: runningAppsSnapshot)) {
                session.writeText(json)
            }
            if let json = Wire.encode(InstalledAppsMessage(apps: installedAppsSnapshot)) {
                session.writeText(json)
            }
            if let json = Wire.encode(BrightnessMessage(level: brightnessLevel)) {
                session.writeText(json)
            }
            if let json = cachedNowPlayingJSON {
                session.writeText(json)
            }
            if let json = cachedActiveModuleJSON {
                session.writeText(json)
            }
            if let json = Wire.encode(VolumeMessage(level: SystemVolume.currentLevel())) {
                session.writeText(json)
            }
            if let json = Wire.encode(BluetoothDevicesMessage(devices: BluetoothStatus.connectedDevices())) {
                session.writeText(json)
            }
        }
    }

    private func broadcastSnapshot() {
        if let json = Wire.encode(AppListMessage(apps: monitor.runningApps())) {
            server.broadcast(json)
        }
        if let json = Wire.encode(InstalledAppsMessage(apps: monitor.installedApps())) {
            server.broadcast(json)
        }
    }

    private func broadcastBrightness(level: Int) {
        guard let json = Wire.encode(BrightnessMessage(level: level)) else { return }
        server.broadcast(json)
    }

    private func broadcastVolume(level: Int) {
        guard let json = Wire.encode(VolumeMessage(level: level)) else { return }
        server.broadcast(json)
    }

    /// BluetoothStatus.connectedDevices() shells out to `system_profiler`
    /// and blocks until it exits — not AppKit, doesn't need main, and
    /// running it there (as this used to) meant both the 10s refresh timer
    /// and a manual "request_bluetooth" could stall the whole app if that
    /// subprocess was ever slow to return. server.broadcast just writes to
    /// sockets, safe from any thread.
    private func broadcastBluetooth() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let json = Wire.encode(BluetoothDevicesMessage(devices: BluetoothStatus.connectedDevices())) else {
                return
            }
            self?.server.broadcast(json)
        }
    }

    /// Runs the (slow, ~50-200ms) perl round-trip off the main thread, then
    /// broadcasts only if the result actually changed since last time — a
    /// steady "nothing changed" poll every 4s shouldn't spam every
    /// connected phone with an identical message.
    private func pollNowPlaying() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let info = NowPlayingClient.fetch()
            DispatchQueue.main.async {
                self?.updateNowPlaying(info)
            }
        }
    }

    private func updateNowPlaying(_ info: NowPlayingInfo?) {
        // A fetch failure (perl hiccup, timeout) is treated the same as
        // "nothing is playing" rather than leaving stale data displayed —
        // matches the upstream reference's own behavior, and self-corrects
        // on the next successful poll.
        var normalized = info ?? NowPlayingInfo(title: nil, artist: nil, album: nil, bundleIdentifier: nil, artworkBase64: nil, playing: false)
        // Resize now, on the main thread (this method is always reached via
        // DispatchQueue.main.async from pollNowPlaying) — replaces the raw
        // artwork bytes with the final resized PNG before dedup/caching/
        // broadcast ever see it. See NowPlayingArtwork's doc for why this
        // can't happen inside fetch() itself.
        normalized.artworkBase64 = NowPlayingArtwork.resizedPngBase64(fromRawBase64: normalized.artworkBase64)
        guard normalized != lastNowPlaying else { return }
        lastNowPlaying = normalized
        guard let json = Wire.encode(nowPlayingMessage(normalized)) else { return }
        server.broadcast(json)
    }

    private func nowPlayingMessage(_ info: NowPlayingInfo) -> NowPlayingMessage {
        NowPlayingMessage(
            title: info.title,
            artist: info.artist,
            album: info.album,
            bundleIdentifier: info.bundleIdentifier,
            artworkPngBase64: info.artworkBase64,
            playing: info.playing
        )
    }

    /// After a play/pause/next/previous command, most players update their
    /// published metadata within a few hundred ms — these two follow-up
    /// polls (fast players, then slower browser-based ones) let the phone
    /// see the new track sooner than waiting for the next full 4s tick.
    private func scheduleNowPlayingRefresh() {
        for delay in [0.2, 0.7] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.pollNowPlaying()
            }
        }
    }

    /// Looks up whether the (new) frontmost app has a module and broadcasts
    /// accordingly; a no-op if the frontmost app hasn't actually changed
    /// (onAppsChanged also fires for launches/terminations of apps that
    /// aren't becoming frontmost). Only apps with a `dynamicList` control
    /// get a refresh timer — a static button-only module never needs one.
    private func broadcastActiveModuleIfNeeded() {
        guard
            let app = NSWorkspace.shared.frontmostApplication,
            let bundleId = app.bundleIdentifier,
            bundleId != currentModuleBundleId
        else { return }

        currentModuleBundleId = bundleId
        moduleRefreshTimer?.invalidate()
        moduleRefreshTimer = nil

        guard let schema = ModuleStore.module(forBundleId: bundleId) else {
            sendNoModule(bundleId: bundleId, displayName: app.localizedName ?? bundleId)
            return
        }

        sendActiveModule(schema)

        let providers = Set(schema.sections.flatMap { $0.controls.compactMap(\.provider) })
        guard !providers.isEmpty else { return }

        let timer = Timer(timeInterval: 10, repeats: true) { [weak self] _ in
            guard let self, self.currentModuleBundleId == bundleId else { return }
            self.sendActiveModule(schema)
        }
        RunLoop.main.add(timer, forMode: .common)
        moduleRefreshTimer = timer
    }

    /// Resolving `dynamicData` (currently just browser tabs via AppleScript)
    /// is a chain of blocking subprocess calls — this used to run
    /// synchronously on main both here and on every 10s `moduleRefreshTimer`
    /// tick, the same bug class already fixed for button taps
    /// (`ActionExecutor.requiresMainThread`) but missed here. None of
    /// `DynamicProviders.resolve`'s work touches AppKit, so it's safe off
    /// main (same reasoning `TextPaster`/`ActionExecutor`'s off-main
    /// capability dispatch already relies on) — only the state write and
    /// broadcast hop back to main, where `currentModuleBundleId`/
    /// `lastActiveModuleJSON` are exclusively read/written.
    private func sendActiveModule(_ schema: ModuleSchema) {
        let providers = Set(schema.sections.flatMap { $0.controls.compactMap(\.provider) })
        guard !providers.isEmpty else {
            broadcastActiveModule(schema, dynamicData: [:])
            return
        }

        let bundleId = schema.bundleId
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var dynamicData: [String: [DynamicListItem]] = [:]
            for provider in providers {
                dynamicData[provider] = DynamicProviders.resolve(provider, bundleId: bundleId)
            }
            DispatchQueue.main.async {
                // Bail if the frontmost app changed while this was resolving
                // — a stale module's tab list shouldn't overwrite whatever's
                // actually active by the time this returns.
                guard let self, self.currentModuleBundleId == bundleId else { return }
                self.broadcastActiveModule(schema, dynamicData: dynamicData)
            }
        }
    }

    private func broadcastActiveModule(_ schema: ModuleSchema, dynamicData: [String: [DynamicListItem]]) {
        guard let json = Wire.encode(ActiveModuleMessage(
            bundleId: schema.bundleId,
            displayName: schema.displayName,
            hasModule: true,
            sections: schema.sections,
            dynamicData: dynamicData,
            projects: schema.projects ?? [],
            currentProjectId: schema.currentProjectId
        )) else { return }

        lastActiveModuleJSON = json
        server.broadcast(json)
    }

    private func sendNoModule(bundleId: String, displayName: String) {
        guard let json = Wire.encode(ActiveModuleMessage(
            bundleId: bundleId,
            displayName: displayName,
            hasModule: false,
            sections: [],
            dynamicData: [:],
            projects: [],
            currentProjectId: nil
        )) else { return }

        lastActiveModuleJSON = json
        server.broadcast(json)
    }

    /// Persists which Project is "current" for an app (so it's synced across
    /// any connected phone, not just remembered locally on one device — see
    /// mac_remote_project_status memory for why), then rebroadcasts only if
    /// that app is still the active module. File I/O runs off main (doesn't
    /// touch AppKit, same reasoning as everything else in this file that
    /// shells out or hits disk); the rebroadcast itself reuses
    /// `sendActiveModule`, which handles its own further off-main work.
    private func handleSelectProject(bundleId: String, projectId: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            ModuleStore.setCurrentProject(bundleId: bundleId, projectId: projectId)
            guard let schema = ModuleStore.module(forBundleId: bundleId) else { return }
            DispatchQueue.main.async {
                guard let self, self.currentModuleBundleId == bundleId else { return }
                self.sendActiveModule(schema)
            }
        }
    }

    /// Replies directly to the requesting session (never a broadcast — only
    /// that phone asked) with a built-in module's current data. Unlike
    /// per-frontmost-app modules, there's no "is this still the active app"
    /// staleness check needed here — a built-in module is always valid to
    /// answer, regardless of whatever's frontmost.
    private func handleRequestBuiltinModule(bundleId: String, to session: WebSocketSession) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let schema = ModuleStore.module(forBundleId: bundleId) else { return }
            let providers = Set(schema.sections.flatMap { $0.controls.compactMap(\.provider) })
            var dynamicData: [String: [DynamicListItem]] = [:]
            for provider in providers {
                dynamicData[provider] = DynamicProviders.resolve(provider, bundleId: bundleId)
            }
            guard let json = Wire.encode(BuiltinModuleMessage(
                bundleId: schema.bundleId,
                displayName: schema.displayName,
                sections: schema.sections,
                dynamicData: dynamicData,
                projects: schema.projects ?? [],
                currentProjectId: schema.currentProjectId
            )) else { return }
            session.writeText(json)
        }
    }
}
