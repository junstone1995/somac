//
//  MeasureView.swift
//  somac
//
//  폰을 잔 옆에 세우고 드래그로 높이·지름을 측정하는 화면
//  화면 PPI 기반으로 드래그 거리 = 실제 물리적 거리(mm)
//

import SwiftUI

// MARK: - PPI Utility

/// 화면 물리적 PPI에 기반한 pt ↔ mm 변환
private enum ScreenScale {
    /// 1 mm 당 포인트 수
    static var pointsPerMM: CGFloat {
        let scale = UIScreen.main.scale
        let nativeScale = UIScreen.main.nativeScale
        let ppi: CGFloat = nativeScale >= 3.0 ? 460 : 326
        let ppiInPoints = ppi / scale
        return ppiInPoints / 25.4
    }

    static func ptToMM(_ pt: CGFloat) -> CGFloat { pt / pointsPerMM }
    static func mmToPt(_ mm: CGFloat) -> CGFloat { mm * pointsPerMM }
}

// MARK: - MeasureView

struct MeasureView: View {
    var onComplete: (GlassMeasurement) -> Void

    // 높이 핸들 Y 위치 (pt, 화면 좌표 — 위가 0)
    @State private var topHandleY: CGFloat = 150
    @State private var bottomHandleY: CGFloat = 450

    // 지름 (mm 단위)
    @State private var topDiameterMM: CGFloat = 80
    @State private var bottomDiameterMM: CGFloat = 60

    // 높이 직접 입력용 (mm 단위)
    @State private var heightMM: CGFloat = 50

    // 높이 동기화 플래그 — 슬라이더 변경 시 핸들 위치 업데이트
    @State private var syncFromSlider = false

    @Environment(\.dismiss) private var dismiss

    private var currentHeightMM: CGFloat {
        ScreenScale.ptToMM(bottomHandleY - topHandleY)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 상단 바 (뒤로가기 + 타이틀)
            headerBar

            // 측정 영역
            GeometryReader { proxy in
                let W = proxy.size.width
                let H = proxy.size.height
                let heightCM = currentHeightMM / 10.0

                ZStack {
                    Color(white: 0.06)

                    // 눈금자 (왼쪽)
                    rulerMarks(height: H)
                        .offset(x: -W / 2 + 30)

                    // 잔 시각화 (중앙)
                    glassShape(W: W, topY: topHandleY, bottomY: bottomHandleY,
                               topDiaMM: topDiameterMM, bottomDiaMM: bottomDiameterMM)

                    // 상단 핸들
                    dragHandle(y: topHandleY, color: .orange,
                               label: String(localized: "measure.top_rim"))
                        .contentShape(Rectangle().size(width: proxy.size.width, height: 60)
                            .offset(x: 0, y: topHandleY - 30))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newY = value.location.y
                                    if newY < bottomHandleY - 40 && newY > 10 {
                                        topHandleY = newY
                                        heightMM = currentHeightMM
                                    }
                                }
                        )

                    // 하단 핸들
                    dragHandle(y: bottomHandleY, color: .cyan,
                               label: String(localized: "measure.bottom_rim"))
                        .contentShape(Rectangle().size(width: proxy.size.width, height: 60)
                            .offset(x: 0, y: bottomHandleY - 30))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newY = value.location.y
                                    if newY > topHandleY + 40 && newY < H - 10 {
                                        bottomHandleY = newY
                                        heightMM = currentHeightMM
                                    }
                                }
                        )

                    // 높이 표시 (핸들 사이)
                    heightIndicator(topY: topHandleY, bottomY: bottomHandleY,
                                    heightCM: heightCM, screenW: W)
                }
            }

            // 하단 컨트롤 패널
            controlPanel
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .background(Color(white: 0.06))
        .navigationBarHidden(true)
        .onAppear {
            heightMM = currentHeightMM
        }
    }

    // MARK: - 상단 바

    private var headerBar: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.body.bold())
                    Text("measure.back")
                }
                .foregroundColor(.white)
            }
            Spacer()
            Text("measure.nav_title")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            // 균형 맞추기 위한 투명 영역
            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(white: 0.06))
    }

    // MARK: - 눈금자

    private func rulerMarks(height: CGFloat) -> some View {
        Canvas { context, size in
            let mmPt = ScreenScale.pointsPerMM
            let totalMM = Int(height / mmPt)

            for mm in 0...totalMM {
                let y = CGFloat(mm) * mmPt
                let isCM = mm % 10 == 0
                let is5mm = mm % 5 == 0
                let tickW: CGFloat = isCM ? 20 : (is5mm ? 14 : 8)

                context.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: tickW, y: y))
                    },
                    with: .color(.white.opacity(isCM ? 0.6 : 0.25)),
                    lineWidth: isCM ? 1.5 : 0.5
                )

                if isCM {
                    let text = Text("\(mm / 10)").font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                    context.draw(context.resolve(text),
                                 at: CGPoint(x: tickW + 10, y: y),
                                 anchor: .leading)
                }
            }
        }
        .frame(width: 50)
        .allowsHitTesting(false)
    }

    // MARK: - 잔 시각화

    private func glassShape(W: CGFloat, topY: CGFloat, bottomY: CGFloat,
                            topDiaMM: CGFloat, bottomDiaMM: CGFloat) -> some View {
        let maxDisplayW = W * 0.5
        let maxDia = max(topDiaMM, bottomDiaMM)
        let scale = maxDia > 0 ? min(maxDisplayW / ScreenScale.mmToPt(maxDia), 1.0) : 1.0

        let topW = ScreenScale.mmToPt(topDiaMM) * scale
        let botW = ScreenScale.mmToPt(bottomDiaMM) * scale
        let centerX = W / 2

        return Path { p in
            p.move(to: CGPoint(x: centerX - topW / 2, y: topY))
            p.addLine(to: CGPoint(x: centerX + topW / 2, y: topY))
            p.addLine(to: CGPoint(x: centerX + botW / 2, y: bottomY))
            p.addLine(to: CGPoint(x: centerX - botW / 2, y: bottomY))
            p.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [Color.orange.opacity(0.15), Color.yellow.opacity(0.08)],
                startPoint: .top, endPoint: .bottom)
        )
        .overlay(
            Path { p in
                p.move(to: CGPoint(x: centerX - topW / 2, y: topY))
                p.addLine(to: CGPoint(x: centerX + topW / 2, y: topY))
                p.addLine(to: CGPoint(x: centerX + botW / 2, y: bottomY))
                p.addLine(to: CGPoint(x: centerX - botW / 2, y: bottomY))
                p.closeSubpath()
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .allowsHitTesting(false)
    }

    // MARK: - 드래그 핸들

    private func dragHandle(y: CGFloat, color: Color, label: String) -> some View {
        GeometryReader { proxy in
            let W = proxy.size.width
            ZStack {
                // 점선
                Path { p in
                    p.move(to: CGPoint(x: 50, y: y))
                    p.addLine(to: CGPoint(x: W, y: y))
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))

                // 핸들 원
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                    )
                    .position(x: W - 30, y: y)

                // 라벨
                Text(label)
                    .font(.caption2.bold())
                    .foregroundColor(color)
                    .position(x: 80, y: y - 12)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 높이 표시

    private func heightIndicator(topY: CGFloat, bottomY: CGFloat,
                                 heightCM: CGFloat, screenW: CGFloat) -> some View {
        let midY = (topY + bottomY) / 2
        let x = screenW - 70

        return ZStack {
            Path { p in
                p.move(to: CGPoint(x: x, y: topY + 14))
                p.addLine(to: CGPoint(x: x, y: bottomY - 14))
            }
            .stroke(Color.white.opacity(0.4), lineWidth: 1)

            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.4))
                .position(x: x, y: topY + 10)

            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.4))
                .position(x: x, y: bottomY - 10)

            Text(String(format: "%.1f cm", heightCM))
                .font(.caption.bold().monospacedDigit())
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
                .position(x: x, y: midY)
        }
        .allowsHitTesting(false)
    }

    // MARK: - 하단 컨트롤 패널

    private var controlPanel: some View {
        VStack(spacing: 14) {
            // 높이 슬라이더
            sliderRow(
                label: String(localized: "measure.height_label"),
                color: .white,
                value: Binding(
                    get: { heightMM },
                    set: { newVal in
                        heightMM = newVal
                        // 슬라이더 변경 시 핸들 위치도 동기화
                        let newHeightPt = ScreenScale.mmToPt(newVal)
                        let midY = (topHandleY + bottomHandleY) / 2
                        topHandleY = midY - newHeightPt / 2
                        bottomHandleY = midY + newHeightPt / 2
                    }
                ),
                range: 30...200,
                unit: "mm",
                displayValue: String(format: "%.0f mm", heightMM)
            )

            // 지름 슬라이더
            sliderRow(
                label: String(localized: "measure.top_diameter"),
                color: .orange,
                value: $topDiameterMM,
                range: 30...120,
                unit: "mm",
                displayValue: String(format: "%.0f mm", topDiameterMM)
            )
            sliderRow(
                label: String(localized: "measure.bottom_diameter"),
                color: .cyan,
                value: $bottomDiameterMM,
                range: 20...120,
                unit: "mm",
                displayValue: String(format: "%.0f mm", bottomDiameterMM)
            )

            Divider().background(Color.white.opacity(0.2))

            // 측정값 요약
            HStack {
                summaryChip(title: String(localized: "measure.height_label"),
                            value: String(format: "%.1f cm", heightMM / 10.0))
                Spacer()
                summaryChip(title: String(localized: "measure.top_dia_label"),
                            value: String(format: "%.0f mm", topDiameterMM))
                Spacer()
                summaryChip(title: String(localized: "measure.bottom_dia_label"),
                            value: String(format: "%.0f mm", bottomDiameterMM))
            }

            // 완료 버튼
            Button {
                let heightM = Double(heightMM) / 1000.0
                let r1 = Double(bottomDiameterMM) / 2.0 / 1000.0
                let r2 = Double(topDiameterMM) / 2.0 / 1000.0
                guard heightM > 0.001 else { return }
                onComplete(GlassMeasurement(r1: r1, r2: r2, height: heightM))
            } label: {
                Label("measure.show_guide", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func sliderRow(label: String, color: Color,
                           value: Binding<CGFloat>, range: ClosedRange<CGFloat>,
                           unit: String, displayValue: String) -> some View {
        HStack(spacing: 12) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 70, alignment: .leading)
            Slider(value: value, in: range, step: 1)
                .tint(color)
            Text(displayValue)
                .font(.caption.bold().monospacedDigit())
                .foregroundColor(.white)
                .frame(width: 55, alignment: .trailing)
        }
    }

    private func summaryChip(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.caption.bold().monospacedDigit())
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationStack { MeasureView { _ in } }
}
