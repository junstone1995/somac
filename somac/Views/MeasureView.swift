//
//  MeasureView.swift
//  somac
//

import SwiftUI
import ARKit
import RealityKit

// MARK: - Measurement Step

enum MeasureStep: Int {
    case bottomRim = 0
    case topRim    = 1
    case done      = 2

    var instruction: String {
        switch self {
        case .bottomRim: return String(localized: "measure.step1_instruction")
        case .topRim:    return String(localized: "measure.step2_instruction")
        case .done:      return String(localized: "measure.done_instruction")
        }
    }

    var edgeInstruction: String {
        switch self {
        case .bottomRim: return String(localized: "measure.step1_edge")
        case .topRim:    return String(localized: "measure.step2_edge")
        case .done:      return ""
        }
    }

    var stepLabel: String {
        switch self {
        case .bottomRim: return String(localized: "measure.step1_label")
        case .topRim:    return String(localized: "measure.step2_label")
        case .done:      return String(localized: "measure.done_label")
        }
    }
}

// MARK: - AR Coordinator

final class MeasureCoordinator: NSObject, ARSessionDelegate {
    weak var arView: ARView?
    var onHitResult: ((simd_float3) -> Void)?

    func session(_ session: ARSession, didUpdate frame: ARFrame) { }

    func handleTap(at point: CGPoint) {
        guard let arView else { return }
        let results = arView.raycast(from: point,
                                     allowing: .estimatedPlane,
                                     alignment: .any)
        if let first = results.first {
            let col = first.worldTransform.columns.3
            onHitResult?(simd_float3(col.x, col.y, col.z))
        }
    }
}

// MARK: - ARViewContainer

struct ARViewContainer: UIViewRepresentable {
    let coordinator: MeasureCoordinator

    func makeCoordinator() -> MeasureCoordinator { coordinator }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        coordinator.arView = arView

        let config = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(MeasureCoordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) { }
}

extension MeasureCoordinator {
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view as? ARView else { return }
        handleTap(at: gesture.location(in: view))
    }
}

// MARK: - MeasureView

struct MeasureView: View {
    var onComplete: (GlassMeasurement) -> Void

    @State private var step:          MeasureStep = .bottomRim
    @State private var awaitingEdge   = false
    @State private var pendingCentre: simd_float3? = nil
    @State private var pendingIsBottom = false
    @State private var bottomPoint:   simd_float3? = nil
    @State private var topPoint:      simd_float3? = nil
    @State private var bottomRadius:  Double = 0
    @State private var topRadius:     Double = 0
    @State private var showRetryAlert = false

    private let coordinator = MeasureCoordinator()

    var body: some View {
        ZStack {
            ARViewContainer(coordinator: coordinator)
                .ignoresSafeArea()
                .onAppear { coordinator.onHitResult = handleCentreHit(_:) }

            if step != .done { crosshair }

            VStack {
                Spacer()
                hudPanel
            }
            .padding()
        }
        .navigationTitle(Text("measure.nav_title"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(Text("measure.error_title"), isPresented: $showRetryAlert) {
            Button("measure.retry") { reset() }
        } message: {
            Text("measure.error_message")
        }
    }

    // MARK: Crosshair

    private var crosshair: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                .frame(width: 40, height: 40)
            Rectangle().fill(Color.white.opacity(0.8)).frame(width: 2, height: 20)
            Rectangle().fill(Color.white.opacity(0.8)).frame(width: 20, height: 2)
        }
    }

    // MARK: HUD

    private var hudPanel: some View {
        VStack(spacing: 12) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { i in
                    Circle()
                        .fill(step.rawValue > i ? Color.green : Color.white.opacity(0.4))
                        .frame(width: 10, height: 10)
                }
            }

            Text(step.stepLabel)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text(awaitingEdge ? step.edgeInstruction : step.instruction)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal)

            if step == .done {
                Button("measure.show_guide") { buildAndComplete() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            }

            Button("measure.reset") { reset() }
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Tap Logic
    // Each measurement step requires two taps:
    //   tap 1 → rim centre  (sets origin point)
    //   tap 2 → rim edge    (radius = distance from centre to edge)

    private func handleCentreHit(_ centre: simd_float3) {
        pendingCentre  = centre
        pendingIsBottom = (step == .bottomRim)
        awaitingEdge   = true
        coordinator.onHitResult = handleEdgeHit(_:)
    }

    private func handleEdgeHit(_ edge: simd_float3) {
        guard let centre = pendingCentre else { return }
        let radius = Double(distance(centre, edge))
        awaitingEdge = false

        if pendingIsBottom {
            bottomPoint  = centre
            bottomRadius = radius
            step = .topRim
            coordinator.onHitResult = handleCentreHit(_:)
        } else {
            topPoint    = centre
            topRadius   = radius
            step = .done
            coordinator.onHitResult = { _ in }
        }
    }

    private func buildAndComplete() {
        guard let bp = bottomPoint, let tp = topPoint else { return }
        let height = abs(Double(tp.y - bp.y))
        guard height > 0.001 else { showRetryAlert = true; return }

        onComplete(GlassMeasurement(r1: bottomRadius,
                                    r2: topRadius,
                                    height: height))
    }

    private func reset() {
        step          = .bottomRim
        awaitingEdge  = false
        pendingCentre = nil
        bottomPoint   = nil
        topPoint      = nil
        bottomRadius  = 0
        topRadius     = 0
        coordinator.onHitResult = handleCentreHit(_:)
    }
}

#Preview {
    NavigationStack { MeasureView { _ in } }
}
