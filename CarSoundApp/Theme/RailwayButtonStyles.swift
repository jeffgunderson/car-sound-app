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
            tint: RailwayTheme.ink,
            tintStrength: configuration.isPressed ? 0.18 : 0.1,
            interactive: true,
            pressed: configuration.isPressed,
            bevelBorder: RailwayTheme.border
        )
    }
}

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
                        .fill(RailwayTheme.surface)
                }
            }
        }
        .railwayInsetCapsuleBevel(intensity: 0.5)
    }
}

/// Large circular play/stop — monochrome, springy press.
struct RailwayCircularPlayButtonStyle: ButtonStyle {
    var isPlaying: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 32, weight: .semibold))
            .foregroundStyle(isPlaying ? RailwayTheme.ink : RailwayTheme.onPrimary)
            .frame(width: 88, height: 88)
            .background {
                Circle()
                    .fill(isPlaying ? RailwayTheme.surfaceElevated : RailwayTheme.ink)
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        Color.white.opacity(isPlaying ? 0.18 : 0.08),
                        lineWidth: 1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.2), value: isPlaying)
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
            tint: isPlaying ? nil : RailwayTheme.ink,
            tintStrength: isPlaying ? 0 : (configuration.isPressed ? 0.16 : 0.1),
            interactive: true,
            pressed: configuration.isPressed,
            bevelBorder: RailwayTheme.border
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
                    .fill(RailwayTheme.surface)
            }
        }
    }
    .railwayInsetBevel(
        cornerRadius: cornerRadius,
        baseBorder: bevelBorder,
        intensity: pressed ? 0.45 : 0.55
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
