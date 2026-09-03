import SwiftUI

/// Design tokens for the settings window's content area, ported 1:1 from
/// the approved mockup (published as an Artifact — see the "Queued next"
/// note this redesign closes out in mac_remote_project_status memory).
/// Deliberately a separate, neutral palette from the phone app's cyan/
/// magenta cyberpunk theme — a native macOS utility-app look instead.
/// The sidebar itself uses SwiftUI's real `.listStyle(.sidebar)` chrome
/// (genuine vibrancy/material) rather than hand-imitating it, since HTML
/// can only approximate that — these tokens are for the content area,
/// which the mockup captured precisely.
enum SettingsColor {
    static let bgContent = Color(hex: 0x1e1e20)
    static let text = Color(hex: 0xf2f2f3)
    static let textSecondary = Color(hex: 0x9a9aa0)
    static let textTertiary = Color(hex: 0x6d6d72)
    static let accent = Color(hex: 0x0a84ff)
    static let green = Color(hex: 0x30d158)
    static let red = Color(hex: 0xff453a)
    static let cardBg = Color.white.opacity(0.035)
    static let cardBorder = Color.white.opacity(0.07)
    static let divider = Color.white.opacity(0.08)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// A rounded, subtly-bordered card grouping rows with dividers between
/// them — the container every mockup screen uses instead of a native
/// Form/List section.
struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .background(SettingsColor.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(SettingsColor.cardBorder, lineWidth: 1)
        )
    }
}

/// A hairline divider between two rows inside a `SettingsCard`.
struct SettingsCardDivider: View {
    var body: some View {
        Rectangle().fill(SettingsColor.divider).frame(height: 1)
    }
}

/// The small uppercase "CONNECTION" / "PERMISSIONS" / "INSTALLED" label
/// above a card.
struct SettingsSectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(SettingsColor.textTertiary)
    }
}
