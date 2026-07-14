import SwiftUI

enum RailwayTheme {
    // MARK: - Canvas (monochrome)

    static let background = Color(hex: 0x0A0A0A)
    static let backgroundDeep = Color(hex: 0x000000)
    static let surface = Color(hex: 0x1C1C1E)
    static let surfaceElevated = Color(hex: 0x2C2C2E)
    static let surfaceBlue = Color(hex: 0x1C1C1E)
    static let surfaceBlueStrong = Color(hex: 0x2C2C2E)
    static let nebulaDeep = Color(hex: 0x111111)

    // MARK: - Ink

    static let ink = Color(hex: 0xFFFFFF)
    static let inkSecondary = Color(hex: 0x8E8E93)
    static let inkTertiary = Color(hex: 0x636366)

    // MARK: - Accent (near-white for Apple sleek)

    static let primary = Color(hex: 0xF5F5F7)
    static let primaryHover = Color(hex: 0xFFFFFF)
    static let glow = Color(hex: 0x3A3A3C)
    static let onPrimary = Color.black

    // MARK: - Borders / status

    static let border = Color(hex: 0x38383A)
    static let borderFaint = Color(hex: 0x1C1C1E)
    static let statusConnected = Color(hex: 0x30D158)
    static let statusConnecting = Color(hex: 0xFFD60A)
    static let statusDisconnected = Color(hex: 0xFF9F0A)
    static let statusUnavailable = Color(hex: 0xFF453A)

    // MARK: - Radii

    static let radiusControl: CGFloat = 10
    static let radiusCard: CGFloat = 16
    static let radiusPanel: CGFloat = 20
    static let radiusPill: CGFloat = 999

    // MARK: - Typography

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
