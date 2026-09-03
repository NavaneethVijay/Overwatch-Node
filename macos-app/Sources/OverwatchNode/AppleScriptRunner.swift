import Foundation

/// Shared `osascript` invocation, used by anything that talks to the system
/// or another app via AppleScript (volume, browser tabs, system power).
enum AppleScriptRunner {
    @discardableResult
    static func run(_ script: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        do {
            try process.run()
            // Read to EOF before waiting — waiting first can deadlock once
            // output exceeds the pipe buffer.
            let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            // Without this, a denied "Automation" permission (osascript
            // exits non-zero with an "not authorized to send Apple events"
            // message on stderr, e.g. error -1743) previously failed 100%
            // silently — stderr was inherited from the parent GUI app (goes
            // nowhere useful) and every caller just treated the resulting
            // empty string as "nothing to show", with no trail to diagnose
            // from.
            guard process.terminationStatus == 0 else {
                let stderr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                AppLog.lifecycle.error("AppleScript exited \(process.terminationStatus, privacy: .public): \(stderr ?? "<no stderr>", privacy: .public)")
                return nil
            }
            return String(data: outData, encoding: .utf8)
        } catch {
            AppLog.lifecycle.error("AppleScript failed: \(String(describing: error), privacy: .public)")
            return nil
        }
    }
}
