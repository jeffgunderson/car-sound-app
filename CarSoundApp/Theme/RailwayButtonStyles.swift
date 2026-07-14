import SwiftUI

private extension View {
    func railwayReadableLabel() -> some View {
        self.foregroundStyle(RailwayTheme.ink)
    }
}

struct RailwayPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let radius = RailwayTheme.radiusControl + 6
        labeledControl(
            configuration.label,
            font: RailwayTheme.ui(16, weight: .semibold),
            verticalPadding: 16,
            horizontalPadding: 0,
            cornerRadius: radius,
            tint: RailwayTheme.primary,
            tintStrength: configuration.isPressed ? 0.22 : 0.14,
            interactive: true,
            pressed: configuration.isPressed,
            bevelBorder: RailwayTheme.primary.opacity(configuration.isPressed ? 0.55 : 0.4)
        )
    }
}

/// Clear liquid glass control (probe recipe).
struct RailwayGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let radius = RailwayTheme.radiusControl + 4
        labeledControl(
            configuration.label,
            font: RailwayTheme.ui(14, weight: .medium),
            verticalPadding: 12,
            horizontalPadding: 10,
            cornerRadius: radius,
            tint: nil,
            tintStrength: 0,
            interactive: true,
            pressed: configuration.isPressed,
            bevelBorder: RailwayTheme.border
        )
    }
}

struct RailwayChipStyle: ViewModifier {
    func body(content: Content) -> some View {
        let padded = content
            .font(RailwayTheme.captionMedium)
            .foregroundStyle(RailwayTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

        Group {
            if #available(iOS 26, *) {
                padded.glassEffect(Glass.clear, in: .capsule)
            } else {
                padded.background {
                    Capsule(style: .continuous)
                        .fill(RailwayTheme.surface.opacity(0.14))
                        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                }
            }
        }
        .railwayInsetCapsuleBevel(intensity: 0.65)
    }
}

struct RailwayPlaybackButtonStyle: ButtonStyle {
    var isPlaying: Bool

    func makeBody(configuration: Configuration) -> some View {
        let radius = RailwayTheme.radiusControl + 6
        labeledControl(
            configuration.label,
            font: RailwayTheme.ui(17, weight: .semibold),
            verticalPadding: 16,
            horizontalPadding: 0,
            cornerRadius: radius,
            tint: isPlaying ? nil : RailwayTheme.primary,
            tintStrength: isPlaying ? 0 : (configuration.isPressed ? 0.2 : 0.14),
            interactive: true,
            pressed: configuration.isPressed,
            bevelBorder: isPlaying
                ? RailwayTheme.border
                : RailwayTheme.primary.opacity(configuration.isPressed ? 0.55 : 0.4)
        )
    }
}

@ViewBuilder
private func labeledControl<Label: View>(
    _ label: Label,
    font: Font,
    verticalPadding: CGFloat,
    horizontalPadding: CGFloat,
    cornerRadius: CGFloat,
    tint: Color?,
    tintStrength: Double,
    interactive: Bool,
    pressed: Bool,
    bevelBorder: Color
) -> some View {
    let core = label
        .font(font)
        .railwayReadableLabel()
        .frame(maxWidth: .infinity)
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)

    Group {
        if #available(iOS 26, *) {
            core.glassEffect(
                clearGlass(tint: tint, tintStrength: tintStrength, interactive: interactive),
                in: .rect(cornerRadius: cornerRadius)
            )
        } else {
            core.background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill((tint ?? RailwayTheme.surface).opacity(tint != nil ? 0.4 : 0.14))
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    )
            }
        }
    }
    .railwayInsetBevel(
        cornerRadius: cornerRadius,
        baseBorder: bevelBorder,
        intensity: pressed ? 0.55 : 0.7
    )
    .scaleEffect(pressed ? 0.98 : 1)
    .animation(.easeOut(duration: 0.12), value: pressed)
}

@available(iOS 26, *)
private func clearGlass(tint: Color?, tintStrength: Double, interactive: Bool) -> Glass {
    var style = Glass.clear
    if let tint, tintStrength > 0 {
        style = style.tint(tint.opacity(tintStrength))
    }
    return interactive ? style.interactive() : style
}

extension View {
    func railwayChip() -> some View {
        modifier(RailwayChipStyle())
    }

    @ViewBuilder
    func railwayClearNavigationBackground() -> some View {
        if #available(iOS 18, *) {
            self.containerBackground(.clear, for: .navigation)
        } else {
            self
        }
    }
}
