import Foundation

/// Read-only: which paired Bluetooth devices are currently connected.
///
/// Deliberately shells out to `system_profiler` rather than calling
/// IOBluetooth directly — the latter is TCC-protected, and for a locally
/// built, ad-hoc-signed app the permission handshake either hard-crashes
/// (no Info.plist usage string) or hangs indefinitely with no visible
/// prompt (confirmed while building this). `system_profiler` is Apple's
/// own signed binary and answers this query instantly with no permission
/// dialog at all, since our process never touches the protected API itself.
enum BluetoothStatus {
    static func connectedDevices() -> [BluetoothDevice] {
        guard let data = runSystemProfiler() else { return [] }
        return parseConnectedDevices(from: data)
    }

    private static func runSystemProfiler() -> Data? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPBluetoothDataType", "-json"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            // Read to EOF before waiting — waitUntilExit() first deadlocks
            // forever once output exceeds the pipe buffer (same bug already
            // fixed in ShellRunner/AppleScriptRunner). system_profiler's
            // Bluetooth JSON is verbose per-device and this call fires
            // automatically every 10s, so it's a real risk, not theoretical.
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            _ = (process.standardError as? Pipe)?.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return data
        } catch {
            return nil
        }
    }

    private static func parseConnectedDevices(from data: Data) -> [BluetoothDevice] {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let sections = root["SPBluetoothDataType"] as? [[String: Any]]
        else { return [] }

        var names: [String] = []
        for section in sections {
            guard let connected = section["device_connected"] as? [[String: Any]] else { continue }
            for entry in connected {
                if let name = entry.keys.first {
                    names.append(name.trimmingCharacters(in: .whitespaces))
                }
            }
        }
        return names.map { BluetoothDevice(name: $0, connected: true) }
    }
}
