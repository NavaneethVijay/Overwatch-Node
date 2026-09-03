import Foundation

/// A phone that has completed pairing once and is trusted to auto-connect
/// without re-entering a code — see WebSocketServer's pairing flow.
struct TrustedDevice: Codable, Identifiable {
    var id: String { deviceId }
    let deviceId: String
    var deviceName: String
    let pairedAt: Date
}

/// Persisted trust store + pairing-code generation. Trust-on-first-use:
/// the first connection from a given `deviceId` requires a code shown on
/// the Mac (see PairingNotifier); every connection after that is silent.
/// Deliberately outside the signed .app bundle, same reasoning as
/// ModuleStore — this is real user data (who's allowed to control this
/// Mac), not something a rebuild should ever touch.
enum DevicePairing {
    private static let storeURL: URL = {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("OverwatchNode/TrustedDevices.json")
    }()

    static func loadTrusted() -> [TrustedDevice] {
        guard
            let data = try? Data(contentsOf: storeURL),
            let devices = try? JSONDecoder().decode([TrustedDevice].self, from: data)
        else { return [] }
        return devices
    }

    static func isTrusted(deviceId: String) -> Bool {
        !deviceId.isEmpty && loadTrusted().contains { $0.deviceId == deviceId }
    }

    /// Re-pairing an already-trusted id (e.g. the phone reinstalled and
    /// regenerated its id, or a name changed) just refreshes the entry
    /// rather than creating a duplicate.
    static func trust(deviceId: String, deviceName: String) {
        guard !deviceId.isEmpty else { return }
        var devices = loadTrusted().filter { $0.deviceId != deviceId }
        devices.append(TrustedDevice(deviceId: deviceId, deviceName: deviceName, pairedAt: Date()))
        save(devices)
    }

    static func revoke(deviceId: String) {
        save(loadTrusted().filter { $0.deviceId != deviceId })
    }

    private static func save(_ devices: [TrustedDevice]) {
        guard let data = try? JSONEncoder().encode(devices) else { return }
        let dir = storeURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: storeURL)
    }

    /// 6 random digits, always zero-padded to 6 characters (e.g. "042817")
    /// — plenty for a local-network-only, short-lived, attempt-limited
    /// code (see WebSocketServer's maxPairingAttempts), not trying to be
    /// cryptographic-strength.
    static func generateCode() -> String {
        String(format: "%06d", Int.random(in: 0..<1_000_000))
    }
}
