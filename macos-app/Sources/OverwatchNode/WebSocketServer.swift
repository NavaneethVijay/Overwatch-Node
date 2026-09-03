import Foundation
import Swifter

/// A tiny WebSocket server for the local Wi-Fi protocol described in
/// design/DESIGN_SYSTEM.md and the project plan. One route, `/ws`; every
/// connected phone gets the same broadcasts.
final class WebSocketServer {
    let port: UInt16
    private let server = HttpServer()

    // Swifter runs every connection's read loop on its own background
    // thread and invokes our `connected`/`disconnected`/`text` callbacks
    // from there, while `broadcast` gets called from the main thread (an
    // NSWorkspace notification). This queue is the only thing allowed to
    // touch `sessions`, so those threads can never race on it.
    private let sessionsQueue = DispatchQueue(label: "com.overwatchnode.sessions")
    private var sessions: [WebSocketSession] = []
    /// Populated by `client_hello`, keyed by session identity — a session
    /// with no entry yet (connected but hasn't said hello) shows as
    /// "Unknown Device" rather than being dropped from the list.
    private var deviceNames: [ObjectIdentifier: String] = [:]
    private var heartbeat: Timer?

    /// Actual socket writes (`WebSocketSession.writeText`/`writeFrame`) are
    /// blocking syscalls with no timeout — Swifter sets `SO_NOSIGPIPE` but
    /// never `SO_SNDTIMEO` (see the vendored Socket.swift), and there's no
    /// internal write queue either. A session whose underlying connection
    /// has gone stale (phone's Wi-Fi radio asleep, a router silently
    /// dropping it — precisely the scenario `startHeartbeat`'s doc comment
    /// describes) can make a write to it hang for a very long time. Both
    /// `broadcast` and the heartbeat ping used to run directly on whatever
    /// thread called them — in practice always the main thread (an
    /// NSWorkspace app-switch notification, or the heartbeat's own
    /// RunLoop.main timer) — so one stale session could freeze the entire
    /// app (menu bar, Settings window, everything) indefinitely, often
    /// right after a phone's very first connection. Routing every outgoing
    /// write through this queue keeps them off main: a stale session now
    /// just means that one write never completes, not that the whole app
    /// stops responding.
    private let networkQueue = DispatchQueue(label: "com.overwatchnode.network")

    // Device pairing — see DevicePairing.swift for the persisted trust
    // store this checks against. A session lives in exactly one of these
    // two states between `client_hello` and either pairing completing or
    // disconnecting; `handleIncoming` refuses every message type except
    // `client_hello`/`submit_pairing_code` until a session is in
    // `pairedSessions`.
    private var pairedSessions: Set<ObjectIdentifier> = []
    private var pendingPairing: [ObjectIdentifier: PendingPairing] = [:]
    private struct PendingPairing {
        let code: String
        let deviceId: String
        let deviceName: String
        let expiresAt: Date
        var attempts: Int = 0
    }
    private static let pairingCodeValidity: TimeInterval = 300
    private static let maxPairingAttempts = 5

    /// Fired once a session is actually paired — either immediately
    /// (client_hello from an already-trusted deviceId) or after a correct
    /// `submit_pairing_code` — so it can be sent the current app list right
    /// away instead of waiting for the next focus change. NOT fired at raw
    /// WebSocket connect time anymore; an unpaired session gets nothing
    /// until it pairs.
    var onClientConnected: ((WebSocketSession) -> Void)?
    /// Fired when a new (untrusted) device's `client_hello` arrives, so the
    /// app can surface the pairing code to the user (see PairingNotifier).
    var onPairingRequested: ((_ deviceName: String, _ code: String) -> Void)?
    var onActivateApp: ((String) -> Void)?
    var onOpenApp: ((String) -> Void)?
    var onCloseApp: ((String) -> Void)?
    var onSetBrightness: ((Int) -> Void)?
    var onSetVolume: ((Int) -> Void)?
    var onTriggerScreenshot: (() -> Void)?
    var onRequestBluetooth: (() -> Void)?
    var onInvokeControlAction: ((ModuleAction) -> Void)?
    var onSelectProject: ((_ bundleId: String, _ projectId: String) -> Void)?
    /// A built-in module's data was requested — replies go directly to
    /// `session` (see AppDelegate.handleRequestBuiltinModule), not a
    /// broadcast, since only the asking phone needs the answer.
    var onRequestBuiltinModule: ((_ bundleId: String, _ session: WebSocketSession) -> Void)?
    var onTriggerLockScreen: (() -> Void)?
    var onTriggerShutdown: (() -> Void)?
    var onTriggerMediaPlayPause: (() -> Void)?
    var onTriggerMediaNext: (() -> Void)?
    var onTriggerMediaPrevious: (() -> Void)?

    init(port: UInt16 = 8787) {
        self.port = port
        server["/ws"] = websocket(
            text: { [weak self] session, text in
                AppLog.network.debug("recv: \(text, privacy: .public)")
                self?.handleIncoming(text, from: session)
            },
            connected: { [weak self] session in
                AppLog.network.info("client connected (session \(ObjectIdentifier(session).hashValue, privacy: .public))")
                self?.addSession(session)
                // onClientConnected fires once pairing completes, not here —
                // client_hello arrives moments later and decides whether
                // that's immediate (already-trusted device) or after the
                // phone submits a pairing code.
            },
            disconnected: { [weak self] session in
                AppLog.network.info("client disconnected (session \(ObjectIdentifier(session).hashValue, privacy: .public))")
                self?.removeSession(session)
            }
        )
    }

    func start() throws {
        try server.start(port, forceIPv4: true)
        AppLog.network.info("HTTP/WebSocket server bound on port \(self.port, privacy: .public)")
        startHeartbeat()
    }

    func stop() {
        AppLog.network.info("server stopping")
        heartbeat?.invalidate()
        heartbeat = nil
        server.stop()
    }

    func broadcast(_ json: String) {
        let sessions = currentSessions()
        networkQueue.async {
            for session in sessions {
                session.writeText(json)
            }
        }
    }

    /// Read by the Status view to show which device(s) are connected right
    /// now. Paired sessions only — a socket that's open but still waiting
    /// on a pairing code isn't "connected" in any meaningful sense (it
    /// can't do anything yet), so it shouldn't show as if it were, that's
    /// misleading about what pairing is actually gating.
    var connectedDeviceNames: [String] {
        connectedDevices.map(\.name)
    }

    /// A connected (paired) session, with an opaque id the menu bar can
    /// hand back to `disconnect(id:)` to target this specific one — plain
    /// names alone (connectedDeviceNames) aren't enough to act on one.
    struct ConnectedDevice {
        let id: ObjectIdentifier
        let name: String
    }

    var connectedDevices: [ConnectedDevice] {
        sessionsQueue.sync {
            sessions
                .filter { pairedSessions.contains(ObjectIdentifier($0)) }
                .map { ConnectedDevice(id: ObjectIdentifier($0), name: deviceNames[ObjectIdentifier($0)] ?? "Unknown Device") }
        }
    }

    /// Forcibly drops a connected device — e.g. the menu bar's per-device
    /// disconnect click. This is a *temporary* kick, not a trust revoke
    /// (see DevicePairing.revoke for that, exposed on the Status screen):
    /// the phone's own reconnect-with-backoff logic will bring it right
    /// back and re-pair silently, since its deviceId is still trusted.
    /// Sends a real close frame first (same as WebSocketSession's own
    /// deinit), not just a raw socket close.
    func disconnect(id: ObjectIdentifier) {
        guard let session = sessionsQueue.sync(execute: { sessions.first { ObjectIdentifier($0) == id } }) else {
            return
        }
        networkQueue.async {
            session.writeCloseFrame()
            session.socket.close()
        }
    }

    /// The most recently-initiated still-valid pairing code awaiting entry,
    /// if any — read by the Status screen (polled on a short timer) so the
    /// code is visible there too, not only via the one-shot system
    /// notification (see PairingNotifier), which is easy to miss or dismiss.
    var currentPairingCode: (deviceName: String, code: String)? {
        sessionsQueue.sync {
            pendingPairing.values
                .filter { Date() < $0.expiresAt }
                .max { $0.expiresAt < $1.expiresAt }
                .map { (deviceName: $0.deviceName, code: $0.code) }
        }
    }

    private func addSession(_ session: WebSocketSession) {
        sessionsQueue.sync { sessions.append(session) }
    }

    private func removeSession(_ session: WebSocketSession) {
        sessionsQueue.sync {
            sessions.removeAll { $0 === session }
            deviceNames.removeValue(forKey: ObjectIdentifier(session))
            pairedSessions.remove(ObjectIdentifier(session))
            pendingPairing.removeValue(forKey: ObjectIdentifier(session))
        }
    }

    private func setDeviceName(_ name: String, for session: WebSocketSession) {
        sessionsQueue.sync { deviceNames[ObjectIdentifier(session)] = name }
    }

    private func currentSessions() -> [WebSocketSession] {
        sessionsQueue.sync { sessions }
    }

    /// A phone's Wi-Fi radio going into power-save (screen off, backgrounded)
    /// or a router silently dropping an idle connection can leave a socket
    /// that looks open on both ends but is actually dead. A small ping every
    /// few seconds keeps real connections alive and turns dead ones into a
    /// prompt disconnect instead of a silent, unresponsive "tap does
    /// nothing" state.
    private func startHeartbeat() {
        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
            self?.pingAll()
        }
        RunLoop.main.add(timer, forMode: .common)
        heartbeat = timer
    }

    private func pingAll() {
        let sessions = currentSessions()
        networkQueue.async {
            for session in sessions {
                session.writeFrame(ArraySlice("".utf8), .ping)
            }
        }
    }

    private func handleIncoming(_ text: String, from session: WebSocketSession) {
        guard let message = Wire.decodeIncoming(text) else {
            AppLog.network.error("failed to decode incoming message: \(text, privacy: .public)")
            return
        }

        switch message.type {
        case "client_hello":
            handleClientHello(message, session: session)
            return
        case "submit_pairing_code":
            handleSubmitPairingCode(message, session: session)
            return
        default:
            break
        }

        guard isPaired(session) else {
            AppLog.network.error("ignoring \(message.type, privacy: .public) from an unpaired session")
            return
        }

        switch message.type {
        case "activate_app":
            if let bundleId = message.bundleId {
                onActivateApp?(bundleId)
            }
        case "open_app":
            if let bundleId = message.bundleId {
                onOpenApp?(bundleId)
            }
        case "close_app":
            if let bundleId = message.bundleId {
                onCloseApp?(bundleId)
            }
        case "set_brightness":
            if let level = message.level {
                onSetBrightness?(level)
            }
        case "set_volume":
            if let level = message.level {
                onSetVolume?(level)
            }
        case "trigger_screenshot":
            onTriggerScreenshot?()
        case "request_bluetooth":
            onRequestBluetooth?()
        case "invoke_control_action":
            if let action = message.action {
                onInvokeControlAction?(action)
            }
        case "select_project":
            if let bundleId = message.bundleId, let projectId = message.projectId {
                onSelectProject?(bundleId, projectId)
            }
        case "request_builtin_module":
            if let bundleId = message.bundleId {
                onRequestBuiltinModule?(bundleId, session)
            }
        case "trigger_lock_screen":
            onTriggerLockScreen?()
        case "trigger_shutdown":
            onTriggerShutdown?()
        case "trigger_media_play_pause":
            onTriggerMediaPlayPause?()
        case "trigger_media_next":
            onTriggerMediaNext?()
        case "trigger_media_previous":
            onTriggerMediaPrevious?()
        default:
            break
        }
    }

    private func handleClientHello(_ message: IncomingMessage, session: WebSocketSession) {
        if let deviceName = message.deviceName {
            setDeviceName(deviceName, for: session)
        }
        let deviceId = message.deviceId ?? ""
        let deviceName = message.deviceName ?? "Unknown Device"

        if DevicePairing.isTrusted(deviceId: deviceId) {
            completePairing(session: session)
        } else {
            beginPairing(deviceId: deviceId, deviceName: deviceName, session: session)
        }
    }

    /// `deviceId` can legitimately be empty — an older/malformed client
    /// with no stable identity to check trust against. Pairing still
    /// works for it (the code challenge itself doesn't need one), it just
    /// can never be persisted as trusted (DevicePairing.trust no-ops on an
    /// empty id), so it re-pairs on every fresh connection.
    private func beginPairing(deviceId: String, deviceName: String, session: WebSocketSession) {
        let code = DevicePairing.generateCode()
        sessionsQueue.sync {
            pendingPairing[ObjectIdentifier(session)] = PendingPairing(
                code: code,
                deviceId: deviceId,
                deviceName: deviceName,
                expiresAt: Date().addingTimeInterval(Self.pairingCodeValidity)
            )
        }
        if let json = Wire.encode(PairingRequiredMessage()) {
            session.writeText(json)
        }
        onPairingRequested?(deviceName, code)
    }

    private func handleSubmitPairingCode(_ message: IncomingMessage, session: WebSocketSession) {
        guard let submittedCode = message.code else { return }
        let key = ObjectIdentifier(session)

        guard var pending = sessionsQueue.sync(execute: { pendingPairing[key] }) else {
            sendPairingStatus(paired: false, error: "No pairing in progress — reconnect to try again.", to: session)
            return
        }

        guard Date() < pending.expiresAt else {
            _ = sessionsQueue.sync { pendingPairing.removeValue(forKey: key) }
            sendPairingStatus(paired: false, error: "Code expired — reconnect to get a new one.", to: session)
            return
        }

        guard submittedCode == pending.code else {
            pending.attempts += 1
            if pending.attempts >= Self.maxPairingAttempts {
                _ = sessionsQueue.sync { pendingPairing.removeValue(forKey: key) }
                sendPairingStatus(paired: false, error: "Too many incorrect attempts — reconnect to try again.", to: session)
            } else {
                sessionsQueue.sync { pendingPairing[key] = pending }
                sendPairingStatus(paired: false, error: "Incorrect code.", to: session)
            }
            return
        }

        DevicePairing.trust(deviceId: pending.deviceId, deviceName: pending.deviceName)
        _ = sessionsQueue.sync { pendingPairing.removeValue(forKey: key) }
        completePairing(session: session)
    }

    /// The single place a session ever transitions into `pairedSessions` —
    /// from `handleClientHello` (already-trusted deviceId) or
    /// `handleSubmitPairingCode` (just paired). Fires `onClientConnected`,
    /// which is what actually triggers the initial app-list/state snapshot
    /// (see AppDelegate.sendSnapshot) — an unpaired session never gets one.
    private func completePairing(session: WebSocketSession) {
        sessionsQueue.sync { _ = pairedSessions.insert(ObjectIdentifier(session)) }
        if let json = Wire.encode(PairingStatusMessage(paired: true, error: nil)) {
            session.writeText(json)
        }
        onClientConnected?(session)
    }

    private func sendPairingStatus(paired: Bool, error: String?, to session: WebSocketSession) {
        guard let json = Wire.encode(PairingStatusMessage(paired: paired, error: error)) else { return }
        session.writeText(json)
    }

    private func isPaired(_ session: WebSocketSession) -> Bool {
        sessionsQueue.sync { pairedSessions.contains(ObjectIdentifier(session)) }
    }
}
