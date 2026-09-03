import Cocoa
import Foundation

/// System-wide Now Playing metadata + playback control, ported from
/// https://github.com/codexjdub/NowPlaying. Two entirely separate
/// mechanisms, each working around a different macOS restriction:
///
/// - **Reading** metadata: `MRMediaRemoteGetNowPlayingInfo` is a private
///   MediaRemote.framework API that recent macOS versions refuse to call
///   from an ordinary third-party process — but Apple-signed `/usr/bin/perl`
///   still has the access, so `NowPlayingClient` spawns perl, which loads
///   `MediaRemoteAdapter.dylib` (Resources/MediaRemoteAdapter.m, compiled
///   by package_app.sh) via Perl's own `DynaLoader` and calls it from
///   *inside* that trusted process. See `Resources/adapter.pl`. This is
///   exactly the same class of entitlement workaround documented as a
///   "genuinely new angle" in this project's prior (abandoned, then
///   revived) Now Playing investigation.
/// - **Controlling** playback: `MRMediaRemoteSendCommand` is restricted
///   even via the perl trick, so `MediaKeySender` instead posts synthetic
///   hardware media-key events (`NSEvent.systemDefined`) — the same
///   `CGEvent.post(tap: .cghidEventTap)` technique `ShortcutSender` already
///   uses, gated by the same Accessibility permission.
struct NowPlayingInfo: Equatable {
    var title: String?
    var artist: String?
    var album: String?
    var bundleIdentifier: String?
    /// Raw base64 exactly as the adapter reported it (whatever format and
    /// resolution the source app published — some publish full-resolution
    /// originals) right after `fetch()` returns. Callers MUST run it
    /// through `NowPlayingArtwork.resizedPngBase64` — on the main thread,
    /// see that function's doc — before this value is broadcast, cached,
    /// or compared for the change-dedup check; see
    /// AppDelegate.updateNowPlaying, the only place that happens.
    var artworkBase64: String?
    var playing: Bool
}

enum NowPlayingClient {
    private static let perlPath = "/usr/bin/perl"

    /// Runs on a background queue — the perl round-trip takes ~50-200ms.
    /// Returns nil (rather than an "empty" info) on any failure so callers
    /// can distinguish "couldn't ask" from "asked, nothing is playing".
    static func fetch() -> NowPlayingInfo? {
        guard
            let resourcePath = Bundle.main.resourcePath
        else { return nil }
        let scriptPath = (resourcePath as NSString).appendingPathComponent("adapter.pl")
        let dylibPath = (resourcePath as NSString).appendingPathComponent("MediaRemoteAdapter.dylib")

        let fm = FileManager.default
        guard fm.isReadableFile(atPath: scriptPath), fm.isReadableFile(atPath: dylibPath) else {
            AppLog.lifecycle.error("Now Playing adapter resources missing from app bundle")
            return nil
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: perlPath)
        task.arguments = [scriptPath, dylibPath, "adapter_get"]

        let stdoutPipe = Pipe()
        task.standardOutput = stdoutPipe
        task.standardError = FileHandle.nullDevice

        // A 2s deadline so a hung perl process can't pile up background
        // workers across polling ticks (this runs every 4s, see
        // AppDelegate's nowPlayingTimer).
        let sem = DispatchSemaphore(value: 0)
        task.terminationHandler = { _ in sem.signal() }

        do {
            try task.run()
        } catch {
            AppLog.lifecycle.error("failed to launch perl for Now Playing: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        if sem.wait(timeout: .now() + 2.0) == .timedOut {
            task.terminate()
            _ = sem.wait(timeout: .now() + 0.5)
            return nil
        }
        guard task.terminationStatus == 0 else { return nil }

        let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        guard
            let obj = try? JSONSerialization.jsonObject(with: data),
            let dict = obj as? [String: Any]
        else { return nil }

        return NowPlayingInfo(
            title: dict["title"] as? String,
            artist: dict["artist"] as? String,
            album: dict["album"] as? String,
            bundleIdentifier: dict["bundleIdentifier"] as? String,
            artworkBase64: dict["artwork"] as? String,
            playing: (dict["playing"] as? Bool) ?? false
        )
    }
}

enum NowPlayingArtwork {
    /// Decodes whatever format the source app published (usually JPEG or
    /// PNG — `NSImage(data:)` handles either) and re-renders into a
    /// downscaled bitmap **at the source's own aspect ratio** — the output
    /// canvas itself is sized to match (e.g. a portrait source produces a
    /// portrait PNG), not forced square, so the phone can render it with a
    /// plain `resizeMode="contain"` and get the real proportions with zero
    /// Mac-side letterboxing or padding baked in. Downscaling at all is the
    /// same reasoning `AppMonitor.pngBase64(for:)` applies to app icons: an
    /// embedded cover can be arbitrarily large (some apps publish
    /// full-resolution originals), and this project already has a
    /// documented incident of an unresized image payload bloating a
    /// WebSocket message to 16+ MB. Never upscales a source smaller than
    /// `maxDimension`.
    ///
    /// **Must be called on the main thread** — `NSImage`/`NSBitmapImageRep`
    /// rendering is AppKit, same rule `AppMonitor`'s icon rendering already
    /// follows ("every AppKit call from a background thread doesn't crash,
    /// it hangs or misbehaves intermittently"). `NowPlayingClient.fetch()`
    /// deliberately does NOT call this itself, since `fetch()` runs on a
    /// background queue (the perl round-trip is slow) — only
    /// `AppDelegate.updateNowPlaying`, already on the main thread, calls
    /// this, right before dedup/caching/broadcast ever see the result.
    static func resizedPngBase64(fromRawBase64 raw: String?, maxDimension: Int = 240) -> String? {
        guard let raw, let data = Data(base64Encoded: raw), let image = NSImage(data: data) else { return nil }

        let sourceSize = image.size
        guard sourceSize.width > 0, sourceSize.height > 0 else { return nil }
        let scale = min(1, CGFloat(maxDimension) / max(sourceSize.width, sourceSize.height))
        let pixelsWide = max(1, Int((sourceSize.width * scale).rounded()))
        let pixelsHigh = max(1, Int((sourceSize.height * scale).rounded()))

        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: pixelsWide,
                pixelsHigh: pixelsHigh,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(
            in: NSRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
        NSGraphicsContext.restoreGraphicsState()

        guard let png = rep.representation(using: .png, properties: [:]) else { return nil }
        return png.base64EncodedString()
    }
}

/// HID media-key codes (IOKit/hidsystem/ev_keymap.h, `NX_KEYTYPE_*`).
private enum MediaKey: Int {
    case play = 16
    case next = 17
    case previous = 18
}

enum MediaKeySender {
    static func playPause() { send(.play) }
    static func next() { send(.next) }
    static func previous() { send(.previous) }

    /// Posts a synthetic media-key down+up so the system delivers it to
    /// whichever app currently owns the Now Playing session, the same
    /// mechanism a hardware keyboard's media keys use.
    private static func send(_ key: MediaKey) {
        guard AXIsProcessTrusted() else {
            AppLog.lifecycle.error("Accessibility permission not granted — cannot send media key")
            return
        }

        func post(state: Int) {
            let data1 = (key.rawValue << 16) | (state << 8)
            let flags = NSEvent.ModifierFlags(rawValue: UInt(state) << 8)
            guard
                let nsEvent = NSEvent.otherEvent(
                    with: .systemDefined,
                    location: .zero,
                    modifierFlags: flags,
                    timestamp: 0,
                    windowNumber: 0,
                    context: nil,
                    subtype: 8,
                    data1: data1,
                    data2: -1
                ),
                let cgEvent = nsEvent.cgEvent
            else { return }
            cgEvent.post(tap: .cghidEventTap)
        }

        post(state: 0xA) // key down
        post(state: 0xB) // key up
    }
}
