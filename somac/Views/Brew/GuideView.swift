//
//  GuideView.swift
//  somac
//
//  레시피에 맞춰 잔에 따를 높이를 시각적으로 표시
//  폰을 잔 옆에 세우면 화면 = 물리적 자(ruler)
//

import SwiftUI

struct GuideView: View {
    let recipe: DrinkRecipe
    let glass: GlassMeasurement
    @Environment(\.dismiss) private var dismiss

    @State private var fillProgress: CGFloat = 0
    @State private var linesVisible = false

    var body: some View {
        GeometryReader { proxy in
            let W = proxy.size.width
            let H = proxy.size.height

            ZStack(alignment: .bottom) {
                // 배경
                Color(white: 0.05).ignoresSafeArea()

                // 레이어별 채움 영역
                layerStack(W: W, H: H)

                // 점선 + 라벨
                lineOverlay(W: W, H: H)
                    .opacity(linesVisible ? 1 : 0)

                // HUD
                hudOverlay(W: W, H: H, topPad: proxy.safeAreaInsets.top, botPad: proxy.safeAreaInsets.bottom)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            withAnimation(.easeOut(duration: 1.3)) { fillProgress = 1 }
            withAnimation(.easeIn(duration: 0.4).delay(0.9)) { linesVisible = true }
        }
    }

    // MARK: - Layer fill rectangles

    private func layerStack(W: CGFloat, H: CGFloat) -> some View {
        let cumulativeRatios = computeCumulativeRatios()

        return ZStack(alignment: .bottom) {
            ForEach(Array(cumulativeRatios.enumerated()), id: \.offset) { idx, info in
                let heightPt = info.fillFraction * H * fillProgress
                let offsetY = info.baseOffset * H * fillProgress

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: info.colorHex).opacity(0.65),
                                     Color(hex: info.colorHex).opacity(0.35)],
                            startPoint: .bottom, endPoint: .top
                        )
                    )
                    .frame(width: W, height: max(0, heightPt))
                    .offset(y: -offsetY)
            }
        }
    }

    // MARK: - Dashed lines + labels

    private func lineOverlay(W: CGFloat, H: CGFloat) -> some View {
        let cumulativeRatios = computeCumulativeRatios()

        return ZStack {
            ForEach(Array(cumulativeRatios.enumerated()), id: \.offset) { idx, info in
                let topY = H - (info.baseOffset + info.fillFraction) * H

                Path { p in
                    p.move(to: CGPoint(x: 0, y: topY))
                    p.addLine(to: CGPoint(x: W, y: topY))
                }
                .stroke(Color(hex: info.colorHex), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))

                lineLabel(
                    num: "①②③④⑤".map(String.init)[safe: idx] ?? "\(idx + 1)",
                    name: info.name,
                    ratioText: "\(Int(info.ratio))/" + "\(Int(recipe.totalParts))",
                    color: Color(hex: info.colorHex)
                )
                .position(x: W - 72, y: topY - 20)
            }
        }
        .frame(width: W, height: H)
    }

    // MARK: - HUD

    private func hudOverlay(W: CGFloat, H: CGFloat, topPad: CGFloat, botPad: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(.leading)
                Spacer()
            }
            .padding(.top, topPad + 8)

            Spacer()

            // 하단 정보
            VStack(spacing: 8) {
                Text(recipe.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(recipe.layers.map { "\($0.ingredient) \(Int($0.ratio))" }.joined(separator: " : "))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 16) {
                    Text(String(format: "%.0f ml", glass.frustumVolume()))
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                    Text(String(format: String(localized: "guide.glass_height_fmt"), glass.height * 100))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.bottom, botPad + 80)
        }
        .frame(width: W, height: H)
    }

    // MARK: - Helpers

    private struct LayerInfo {
        let name: String
        let ratio: Double
        let colorHex: String
        let fillFraction: CGFloat   // fraction of screen height
        let baseOffset: CGFloat     // offset from bottom (sum of layers below)
    }

    private func computeCumulativeRatios() -> [LayerInfo] {
        var result: [LayerInfo] = []
        var cumulativeOffset: CGFloat = 0

        for layer in recipe.layers {
            let fraction = CGFloat(layer.ratio / recipe.totalParts)
            result.append(LayerInfo(
                name: layer.ingredient,
                ratio: layer.ratio,
                colorHex: layer.colorHex,
                fillFraction: fraction,
                baseOffset: cumulativeOffset
            ))
            cumulativeOffset += fraction
        }
        return result
    }

    private func lineLabel(num: String, name: String, ratioText: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Text(num)
                .font(.footnote)
                .foregroundColor(color.opacity(0.8))
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundColor(color)
                Text(ratioText)
                    .font(.caption2)
                    .foregroundColor(color.opacity(0.75))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Safe subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    GuideView(
        recipe: RecipePresets.somacGolden,
        glass: GlassMeasurement(r1: 0.030, r2: 0.038, height: 0.130)
    )
}
