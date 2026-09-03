import Foundation

/// Publishes this Mac's WebSocket server over Bonjour as `_overwatchnode._tcp`
/// so the Android app can find it without the user typing an IP address.
final class BonjourAdvertiser: NSObject, NetServiceDelegate {
    private var service: NetService?

    func publish(port: UInt16, name: String) {
        AppLog.bonjour.info("publishing _overwatchnode._tcp as \(name, privacy: .public) on port \(port, privacy: .public)")
        let service = NetService(domain: "local.", type: "_overwatchnode._tcp.", name: name, port: Int32(port))
        service.delegate = self
        service.publish()
        self.service = service
    }

    func stop() {
        AppLog.bonjour.info("stopping advertisement")
        service?.stop()
        service = nil
    }

    func netServiceDidPublish(_ sender: NetService) {
        AppLog.bonjour.info("advertising \(sender.name, privacy: .public) on port \(sender.port, privacy: .public)")
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        AppLog.bonjour.error("failed to publish — \(errorDict, privacy: .public)")
    }
}
