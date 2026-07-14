import SwiftUI

enum RailwayTheme {
    // MARK: - Canvas

    static let background = Color(hex: 0x10151E)
    static let backgroundDeep = Color(hex: 0x080C14)
    static let surface = Color(hex: 0x141B28)
    static let surfaceBlue = Color(hex: 0x152238)
    static let surfaceBlueStrong = Color(hex: 0x1A3A5C)
    static let nebulaDeep = Color(hex: 0x0A1A38)

    // MARK: - Ink

    static let ink = Color(hex: 0xF7F7F8)
    static let inkSecondary = Color(hex: 0xA1A0AB)
    static let inkTertiary = Color(hex: 0x6B7280)

    // MARK: - Accent (Twitter-like blue, darkened for the night UI)

    static let primary = Color(hex: 0x1A7AB8)
    static let primaryHover = Color(hex: 0x2290D0)
    static let glow = Color(hex: 0x2B6FD4)
    static let onPrimary = Color.white

    // MARK: - Borders / status

    static let border = Color(hex: 0x2A3344)
    static let borderFaint = Color(hex: 0x141B28)
    static let statusConnected = Color(hex: 0x42946E)
    static let statusConnecting = Color(hex: 0xD4A017)
    static let statusDisconnected = Color(hex: 0xC47A3A)
    static let statusUnavailable = Color(hex: 0xC44536)

    // MARK: - Radii (4px grid)

    static let radiusControl: CGFloat = 6
    static let radiusCard: CGFloat = 12
    static let radiusPanel: CGFloat = 16
    static let radiusPill: CGFloat = 999

    // MARK: - Typography (shadcn-style: Inter for display + UI)

    static func display(_ size: CGFloat) -> Font {
        .custom("Inter-SemiBold", size: size)
    }

    static func displayRegular(_ size: CGFloat) -> Font {
        .custom("Inter-Medium", size: size)
    }

    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .semibold, .bold, .heavy, .black:
            return .custom("Inter-SemiBold", size: size)
        case .medium:
            return .custom("Inter-Medium", size: size)
        default:
            return .custom("Inter-Regular", size: size)
        }
    }

    static var sectionHeader: Font { ui(12, weight: .medium) }
    static var body: Font { ui(15) }
    static var bodyMedium: Font { ui(15, weight: .medium) }
    static var caption: Font { ui(13) }
    static var captionMedium: Font { ui(13, weight: .medium) }
    static var micro: Font { ui(11) }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
