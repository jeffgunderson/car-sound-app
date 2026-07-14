import SwiftUI

/// Soft inset depth + top-edge blue bevel, shaded along the bottom.
/// Edge-only strokes — no `.blur` / blend modes over label area.
struct RailwayInsetBevel<S: InsettableShape>: View {
    var shape: S
    var highlight: Color = RailwayTheme.primaryHover
    var shade: Color = .black
    var baseBorder: Color = RailwayTheme.border
    var intensity: Double = 1

    var body: some View {
        ZStack {
            // Soft inset rim (stroke masked to interior = no fill over text).
            shape
                .stroke(shade.opacity(0.18 * intensity), lineWidth: 3)
                .mask(shape)

            shape
                .strokeBorder(baseBorder.opacity(0.28 * intensity), lineWidth: 1)

            // Blue lit top edge, dark bottom edge.
            shape
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: highlight.opacity(0.65 * intensity), location: 0),
                            .init(color: highlight.opacity(0.22 * intensity), location: 0.16),
                            .init(color: Color.clear, location: 0.4),
                            .init(color: shade.opacity(0.25 * intensity), location: 1),
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
        highlight: Color = RailwayTheme.primaryHover,
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
        highlight: Color = RailwayTheme.primaryHover,
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
