import SwiftUI
import UIKit

/// Dark blue canvas with Bayer-dithered nebula blooms (stipple, not smooth gradients).
struct RailwayBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Rectangle()
            .fill(RailwayTheme.backgroundDeep)
            .overlay {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 / 2.0 : 1.0 / 20.0, paused: reduceMotion)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        Image(uiImage: DitheredNebulaRenderer.image(size: CGSize(width: w, height: h), time: t))
                            .resizable()
                            .interpolation(.none)
                            .frame(width: w, height: h)
                            .clipped()
                    }
                }
            }
            .clipped()
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

/// CPU ordered-dither of three drifting blue blooms (no Metal toolchain required).
private enum DitheredNebulaRenderer {
    /// Logical pixel size in points — larger = chunkier dither, cheaper.
    private static let cell: CGFloat = 3

    private static let bayer: [Double] = [
        0 / 16, 8 / 16, 2 / 16, 10 / 16,
        12 / 16, 4 / 16, 14 / 16, 6 / 16,
        3 / 16, 11 / 16, 1 / 16, 9 / 16,
        15 / 16, 7 / 16, 13 / 16, 5 / 16,
    ]

    static func image(size: CGSize, time: TimeInterval) -> UIImage {
        let width = max(Int(ceil(size.width / cell)), 1)
        let height = max(Int(ceil(size.height / cell)), 1)
        let w = Double(size.width)
        let h = Double(size.height)
        let maxDim = max(w, h)

        let p1 = time * (.pi * 2 / 8.0)
        let p2 = time * (.pi * 2 / 6.5) + 1.1
        let p3 = time * (.pi * 2 / 9.0) + 2.4

        let c1x = w * (0.12 + 0.11 * sin(p1))
        let c1y = h * (0.08 + 0.07 * cos(p1 * 0.85))
        let c2x = w * (0.92 + 0.10 * cos(p2))
        let c2y = h * (0.32 + 0.08 * sin(p2 * 1.1))
        let c3x = w * (0.40 + 0.12 * sin(p3 * 0.9))
        let c3y = h * (0.95 + 0.06 * cos(p3))

        let pulse1 = 0.72 + 0.18 * sin(p1)
        let pulse2 = 0.64 + 0.20 * cos(p2)
        let pulse3 = 0.48 + 0.14 * sin(p3)

        let r1 = maxDim * 0.48
        let r2 = w * 0.42
        let r3 = maxDim * 0.46

        let levels = 7.0
        let nLevels = levels - 1

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let baseR = 0.031 // ~#080C14
        let baseG = 0.047
        let baseB = 0.078

        for row in 0..<height {
            for col in 0..<width {
                let x = (Double(col) + 0.5) * Double(cell)
                let y = (Double(row) + 0.5) * Double(cell)

                let b1 = bloom(x: x, y: y, cx: c1x, cy: c1y, radius: r1) * pulse1
                let b2 = bloom(x: x, y: y, cx: c2x, cy: c2y, radius: r2) * pulse2
                let b3 = bloom(x: x, y: y, cx: c3x, cy: c3y, radius: r3) * pulse3

                var r = baseR + b1 * 0.18 + b2 * 0.28 + b3 * 0.08
                var g = baseG + b1 * 0.42 + b2 * 0.52 + b3 * 0.32
                var b = baseB + b1 * 0.78 + b2 * 0.88 + b3 * 0.62

                let vignette = 1.0 - 0.35 * (y / max(h, 1))
                r *= vignette
                g *= vignette
                b *= vignette

                let threshold = bayer[(row & 3) * 4 + (col & 3)] - 0.5
                r = floor(r * nLevels + threshold + 0.5) / nLevels
                g = floor(g * nLevels + threshold + 0.5) / nLevels
                b = floor(b * nLevels + threshold + 0.5) / nLevels

                let i = (row * width + col) * 4
                pixels[i] = UInt8(clamping: Int(r * 255))
                pixels[i + 1] = UInt8(clamping: Int(g * 255))
                pixels[i + 2] = UInt8(clamping: Int(b * 255))
                pixels[i + 3] = 255
            }
        }

        let data = Data(pixels)
        let provider = CGDataProvider(data: data as CFData)!
        let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!

        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }

    private static func bloom(x: Double, y: Double, cx: Double, cy: Double, radius: Double) -> Double {
        let dx = x - cx
        let dy = y - cy
        let d = (dx * dx + dy * dy).squareRoot()
        let t = min(max(1.0 - d / radius, 0), 1)
        return t * t
    }
}

#Preview {
    ZStack {
        RailwayBackground()
        RailwayCard {
            Text("Glass over nebula")
                .foregroundStyle(RailwayTheme.ink)
        }
        .padding(40)
    }
}
