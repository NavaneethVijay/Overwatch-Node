import ApplicationServices
import Cocoa

/// Direct window positioning via the Accessibility API — the same
/// technique tools like Rectangle use under the hood — since vanilla
/// macOS has no built-in keyboard shortcuts for half/quarter tiling.
/// Reuses the Accessibility permission the app already requires for
/// `ShortcutSender`. Always operates on whatever app is actually
/// frontmost right now (`NSWorkspace.shared.frontmostApplication`), not
/// the `contextBundleId` `ActionExecutor` threads through — the built-in
/// Window Management tab (mobile-app/src/modules/windowManagement.ts)
/// isn't tied to any one app's module, unlike every other capability here.
enum WindowTiler {
    static func tile(preset: String?) {
        guard AXIsProcessTrusted() else {
            AppLog.lifecycle.error("Accessibility permission not granted — cannot tile window")
            return
        }
        guard let preset else { return }
        guard let app = NSWorkspace.shared.frontmostApplication else { return }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        guard let axWindow = focusedWindow(of: axApp) else {
            AppLog.lifecycle.error("no focused window for frontmost app \(app.bundleIdentifier ?? "?", privacy: .public)")
            return
        }

        guard let visible = visibleFrame(containing: axWindow) else { return }

        if preset == "center" {
            guard let currentSize = size(of: axWindow) else { return }
            let cocoaOrigin = CGPoint(
                x: visible.origin.x + (visible.width - currentSize.width) / 2,
                y: visible.origin.y + (visible.height - currentSize.height) / 2
            )
            setPosition(axWindow, cocoaOrigin: cocoaOrigin, height: currentSize.height)
            return
        }

        guard let rect = tileRect(for: preset, in: visible) else {
            AppLog.lifecycle.error("unknown tile preset: \(preset, privacy: .public)")
            return
        }
        setSize(axWindow, rect.size)
        setPosition(axWindow, cocoaOrigin: rect.origin, height: rect.height)
        // Some apps re-clamp size once the window lands on its new
        // position (especially across a screen boundary) — re-applying
        // once more matches the defensive double-set other tiling tools
        // use rather than trusting a single ordering to always stick.
        setSize(axWindow, rect.size)
    }

    /// A `preset` rect in Cocoa screen-space (bottom-left origin, y up) —
    /// the same space `NSScreen.visibleFrame` is expressed in.
    private static func tileRect(for preset: String, in visible: CGRect) -> CGRect? {
        let x0 = visible.origin.x, y0 = visible.origin.y, w = visible.width, h = visible.height
        switch preset {
        case "leftHalf": return CGRect(x: x0, y: y0, width: w / 2, height: h)
        case "rightHalf": return CGRect(x: x0 + w / 2, y: y0, width: w / 2, height: h)
        case "topHalf": return CGRect(x: x0, y: y0 + h / 2, width: w, height: h / 2)
        case "bottomHalf": return CGRect(x: x0, y: y0, width: w, height: h / 2)
        case "topLeft": return CGRect(x: x0, y: y0 + h / 2, width: w / 2, height: h / 2)
        case "topRight": return CGRect(x: x0 + w / 2, y: y0 + h / 2, width: w / 2, height: h / 2)
        case "bottomLeft": return CGRect(x: x0, y: y0, width: w / 2, height: h / 2)
        case "bottomRight": return CGRect(x: x0 + w / 2, y: y0, width: w / 2, height: h / 2)
        case "maximize": return visible
        default: return nil
        }
    }

    /// Falls back to the main window if there's no focused window — some
    /// apps don't reliably report `kAXFocusedWindowAttribute`.
    private static func focusedWindow(of axApp: AXUIElement) -> AXUIElement? {
        var ref: CFTypeRef?
        if AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &ref) == .success, let ref {
            return (ref as! AXUIElement)
        }
        if AXUIElementCopyAttributeValue(axApp, kAXMainWindowAttribute as CFString, &ref) == .success, let ref {
            return (ref as! AXUIElement)
        }
        return nil
    }

    /// Which screen's `visibleFrame` a window is currently on, by
    /// converting its AX-space position back to Cocoa space and testing
    /// containment. Falls back to the main screen if position can't be
    /// read at all.
    private static func visibleFrame(containing axWindow: AXUIElement) -> CGRect? {
        guard let origin = position(of: axWindow), let primaryHeight = NSScreen.screens.first?.frame.height else {
            return NSScreen.main?.visibleFrame
        }
        let cocoaPoint = CGPoint(x: origin.x, y: primaryHeight - origin.y)
        let screen = NSScreen.screens.first(where: { $0.frame.contains(cocoaPoint) }) ?? NSScreen.main
        return screen?.visibleFrame
    }

    private static func position(of axWindow: AXUIElement) -> CGPoint? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &ref) == .success, let ref
        else { return nil }
        var point = CGPoint.zero
        AXValueGetValue((ref as! AXValue), .cgPoint, &point)
        return point
    }

    private static func size(of axWindow: AXUIElement) -> CGSize? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &ref) == .success, let ref
        else { return nil }
        var size = CGSize.zero
        AXValueGetValue((ref as! AXValue), .cgSize, &size)
        return size
    }

    private static func setSize(_ axWindow: AXUIElement, _ cocoaSize: CGSize) {
        var size = cocoaSize
        guard let value = AXValueCreate(.cgSize, &size) else { return }
        AXUIElementSetAttributeValue(axWindow, kAXSizeAttribute as CFString, value)
    }

    /// AX's coordinate space is top-left-origin, y-down; Cocoa screen
    /// space (what `visibleFrame` and every rect above are computed in) is
    /// bottom-left-origin, y-up — both anchored to the *primary* screen's
    /// top/bottom edge respectively, so flipping only ever needs the
    /// primary screen's height, never the target screen's own frame.
    /// `kAXPositionAttribute` is the window's top-left corner, so the flip
    /// needs the rect's height to find that corner from a bottom-left
    /// Cocoa origin: axY = primaryHeight - cocoaOriginY - height.
    private static func setPosition(_ axWindow: AXUIElement, cocoaOrigin: CGPoint, height: CGFloat) {
        guard let primaryHeight = NSScreen.screens.first?.frame.height else { return }
        var axPoint = CGPoint(x: cocoaOrigin.x, y: primaryHeight - cocoaOrigin.y - height)
        guard let value = AXValueCreate(.cgPoint, &axPoint) else { return }
        AXUIElementSetAttributeValue(axWindow, kAXPositionAttribute as CFString, value)
    }
}
