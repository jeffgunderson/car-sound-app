import SwiftUI

/// Soft inset hairline — monochrome top highlight, bottom shade.
struct RailwayInsetBevel<S: InsettableShape>: View {
    var shape: S
    var highlight: Color = Color.white
    var shade: Color = .black
    var baseBorder: Color = RailwayTheme.border
    var intensity: Double = 1

    var body: some View {
        ZStack {
            shape
                .stroke(shade.opacity(0.2 * intensity), lineWidth: 3)
                .mask(shape)

            shape
                .strokeBorder(baseBorder.opacity(0.5 * intensity), lineWidth: 1)

            shape
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: highlight.opacity(0.28 * intensity), location: 0),
                            .init(color: highlight.opacity(0.08 * intensity), location: 0.18),
                            .init(color: Color.clear, location: 0.45),
                            .init(color: shade.opacity(0.35 * intensity), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func railwayInsetBevel(
        cornerRadius: CGFloat,
        highlight: Color = .white,
        baseBorder: Color = RailwayTheme.border,
        intensity: Double = 1
    ) -> some View {
        overlay {
            RailwayInsetBevel(
                shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                highlight: highlight,
                baseBorder: baseBorder,
                intensity: intensity
            )
        }
    }

    func railwayInsetCapsuleBevel(
        highlight: Color = .white,
        baseBorder: Color = RailwayTheme.border,
        intensity: Double = 1
    ) -> some View {
        overlay {
            RailwayInsetBevel(
                shape: Capsule(style: .continuous),
                highlight: highlight,
                baseBorder: baseBorder,
                intensity: intensity
            )
        }
    }
}
