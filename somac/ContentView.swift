//
//  ContentView.swift
//  somac
//

import SwiftUI

// MARK: - Navigation Destination

enum AppRoute: Hashable {
    case measure
    case guide(GlassMeasurement)
}

extension GlassMeasurement: Hashable {
    static func == (lhs: GlassMeasurement, rhs: GlassMeasurement) -> Bool {
        lhs.r1 == rhs.r1 && lhs.r2 == rhs.r2 && lhs.height == rhs.height
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(r1); hasher.combine(r2); hasher.combine(height)
    }
}

// MARK: - Home Screen

struct ContentView: View {
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            homeScreen
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .measure:
                        MeasureView { glass in path.append(.guide(glass)) }
                    case .guide(let glass):
                        GuideView(glass: glass)
                    }
                }
        }
    }

    private var homeScreen: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 8) {
                Text("🍺").font(.system(size: 72))
                Text("app.name").font(.largeTitle.bold())
                Text("home.subtitle")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                ratioRow(icon: "drop.fill",  color: .blue,   key: "home.soju_row", amount: "25 ml")
                ratioRow(icon: "mug.fill",   color: .yellow, key: "home.beer_row", amount: "50 ml")
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 32)

            Spacer()

            Button {
                path.append(.measure)
            } label: {
                Label("home.measure_button", systemImage: "camera.viewfinder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.horizontal, 32)

            Text("home.lidar_note")
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer().frame(height: 20)
        }
        .navigationBarHidden(true)
    }

    private func ratioRow(icon: String, color: Color,
                          key: LocalizedStringKey, amount: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(color)
            Text(key)
            Spacer()
            Text(amount).bold()
        }
    }
}

#Preview { ContentView() }
