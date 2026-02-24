//
//  GuideView.swift
//  somac
//
//  전체 화면 = 맥주잔 높이
//  아래부터:
//    ① 소주 25ml 선
//    ② 소주+맥주 75ml 선 (50ml 더 부으면 됨)
//  폰을 세우고 옆에 잔을 세워서 선에 맞게 따른다.
//

import SwiftUI

// MARK: - GuideView

struct GuideView: View {
    let glass: GlassMeasurement
    @Environment(\.dismiss) private var dismiss

    private let recipe = SomacRecipe()

    @State private var fillProgress: CGFloat = 0   // 0→1 애니메이션
    @State private var linesVisible  = false

    // 모든 LiDAR iPhone(Pro) 은 460 PPI
    private static let screenPPI: Double = 460

    // 기기 화면의 물리적 높이 (mm)
    private var physScreenH_mm: Double {
        Double(UIScreen.main.nativeBounds.height) / Self.screenPPI * 25.4
    }

    /// 화면 좌표계에서 `vol` ml 가 채워지는 높이(pt, 아래에서부터)
    private func fillPts(vol: Double, screenH: CGFloat) -> CGFloat {
        let glassH_mm = glass.height * 1000
        let fillH_mm  = glass.fillHeight(for: vol) * 1000
        // 잔이 화면보다 짧으면 실제 물리 크기로 1:1 매핑
        // 잔이 화면보다 길면 화면에 맞게 축소
        let refH_mm   = max(physScreenH_mm, glassH_mm)
        return CGFloat(fillH_mm / refH_mm) * screenH
    }

    var body: some View {
        GeometryReader { proxy in
            let W      = proxy.size.width
            let H      = proxy.size.height
            let topPad = proxy.safeAreaInsets.top
            let botPad = proxy.safeAreaInsets.bottom

            // 고정 선 위치 (pt, 화면 좌표 – 위가 0)
            let sojuLinePts  = fillPts(vol: 25, screenH: H)   // 아래서부터
            let totalLinePts = fillPts(vol: 75, screenH: H)   // 아래서부터
            let sojuLineY    = H - sojuLinePts
            let beerLineY    = H - totalLinePts

            // 애니메이션 적용된 채움 높이
            let sojuFillH = sojuLinePts  * fillProgress
            let beerFillH = (totalLinePts - sojuLinePts) * fillProgress

            ZStack(alignment: .bottom) {

                // ── 배경 ──────────────────────────────────────────────
                Color(white: 0.05).ignoresSafeArea()

                // ── 소주 구간 (파란색, 맨 아래) ──────────────────────
                Rectangle()
                    .fill(sojuGradient)
                    .frame(width: W, height: max(0, sojuFillH))

                // ── 맥주 구간 (앰버, 소주 위) ────────────────────────
                Rectangle()
                    .fill(beerGradient)
                    .frame(width: W, height: max(0, beerFillH))
                    .offset(y: -sojuFillH)

                // ── 점선 및 레이블 ──────────────────────────────────
                ZStack {
                    // 소주 선 (하단)
                    dashedLine(y: sojuLineY, color: sojuLineClr, W: W)

                    // 맥주 선 (상단)
                    dashedLine(y: beerLineY, color: beerLineClr, W: W)

                    // 소주 레이블
                    lineLabel(num: "①",
                              volume: "25 ml",
                              name: String(localized: "glass.soju"),
                              color: sojuLineClr)
                        .position(x: W - 64, y: sojuLineY - 20)

                    // 맥주 레이블
                    lineLabel(num: "②",
                              volume: "50 ml",
                              name: String(localized: "glass.beer"),
                              color: beerLineClr)
                        .position(x: W - 64, y: beerLineY - 20)
                }
                .frame(width: W, height: H)
                .opacity(linesVisible ? 1 : 0)

                // ── HUD ──────────────────────────────────────────────
                VStack(spacing: 0) {
                    // 뒤로가기 버튼
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

                    // 하단 정보 바
                    infoBar(beerFillCm: recipe.beerFillHeight(glass: glass) * 100)
                        .padding(.horizontal)
                        .padding(.bottom, botPad + 12)
                }
                .frame(width: W, height: H)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 1.3))        { fillProgress = 1 }
            withAnimation(.easeIn(duration: 0.4).delay(0.9)) { linesVisible = true }
        }
    }

    // MARK: - 색상

    private let sojuLineClr = Color.cyan
    private let beerLineClr = Color(red: 1.0, green: 0.88, blue: 0.3)

    private var sojuGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.1, green: 0.42, blue: 0.9).opacity(0.65),
                     Color(red: 0.3, green: 0.65, blue: 1.0).opacity(0.4)],
            startPoint: .bottom, endPoint: .top)
    }

    private var beerGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.65),
                     Color(red: 1.0, green: 0.86, blue: 0.3).opacity(0.4)],
            startPoint: .bottom, endPoint: .top)
    }

    // MARK: - 서브뷰 빌더

    private func dashedLine(y: CGFloat, color: Color, W: CGFloat) -> some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: W, y: y))
        }
        .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
    }

    private func lineLabel(num: String, volume: String,
                           name: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Text(num)
                .font(.footnote)
                .foregroundColor(color.opacity(0.8))
            VStack(alignment: .leading, spacing: 1) {
                Text(volume)
                    .font(.subheadline.bold())
                    .foregroundColor(color)
                Text(name)
                    .font(.caption2)
                    .foregroundColor(color.opacity(0.75))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
    }

    private func infoBar(beerFillCm: Double) -> some View {
        HStack(spacing: 0) {
            // 소주
            infoChip(icon: "drop.fill", color: sojuLineClr,
                     name: String(localized: "glass.soju"),
                     detail: String(localized: "guide.soju_detail"))

            dividerLine

            // 맥주
            infoChip(icon: "mug.fill", color: beerLineClr,
                     name: String(localized: "glass.beer"),
                     detail: String(format: String(localized: "guide.beer_fill_fmt"),
                                    beerFillCm))

            Spacer()

            // 잔 정보
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f ml", glass.frustumVolume()))
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.75))
                Text(String(format: String(localized: "guide.glass_height_fmt"),
                            glass.height * 100))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func infoChip(icon: String, color: Color,
                          name: String, detail: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color).font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.caption.bold()).foregroundColor(.white)
                Text(detail).font(.caption2).foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 1, height: 32)
            .padding(.horizontal, 12)
    }
}

// MARK: - Preview

#Preview {
    GuideView(glass: GlassMeasurement(r1: 0.030, r2: 0.038, height: 0.130))
}
