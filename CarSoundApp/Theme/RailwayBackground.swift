import SwiftUI

/// Flat black canvas with a soft gray vignette — quiet Apple dark surface.
struct RailwayBackground: View {
    var body: some View {
        ZStack {
            RailwayTheme.backgroundDeep

            RadialGradient(
                colors: [
                    Color.white.opacity(0.06),
                    Color.clear,
                ],
                center: .center,
                startRadius: 20,
                endRadius: 420
            )
            .blendMode(.plusLighter)

            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.55),
                ],
                center: .center,
                startRadius: 160,
                endRadius: 560
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        RailwayBackground()
        Text("Monochrome")
            .foregroundStyle(RailwayTheme.ink)
    }
}
