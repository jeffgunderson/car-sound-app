import SwiftUI

/// Clear Liquid Glass for secondary surfaces (Settings cards).
struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = RailwayTheme.radiusCard
    var interactive: Bool = false
    var tint: Color? = nil
    var tintStrength: Double = 0
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(iOS 26, *) {
            content()
                .glassEffect(glassStyle, in: .rect(cornerRadius: cornerRadius))
        } else {
            content()
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(RailwayTheme.surface.opacity(0.85))
                }
        }
    }

    @available(iOS 26, *)
    private var glassStyle: Glass {
        var style = Glass.clear
        if let tint, tintStrength > 0 {
            style = style.tint(tint.opacity(tintStrength))
        }
        return interactive ? style.interactive() : style
    }
}

struct RailwayCard<Content: View>: View {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = RailwayTheme.radiusCard
    var interactive: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        GlassPanel(cornerRadius: cornerRadius, interactive: interactive) {
            content()
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .railwayInsetBevel(cornerRadius: cornerRadius, intensity: 0.55)
    }
}

struct RailwaySectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(RailwayTheme.sectionHeader)
            .tracking(1.2)
            .foregroundStyle(RailwayTheme.inkSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
    }
}

struct RailwayGlassStack<Content: View>: View {
    var spacing: CGFloat = 0
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
    }
}
