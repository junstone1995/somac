//
//  ContentView.swift
//  somac
//

import SwiftUI

// MARK: - App Theme

enum AppTheme {
    static let gold       = Color(red: 0.85, green: 0.68, blue: 0.32)
    static let darkBg     = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let cardBg     = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let subtleText = Color(white: 0.55)
}

// MARK: - Tab

enum AppTab: Int, CaseIterable {
    case compare = 0
    case brew    = 1
    case cabinet = 2

    var title: String {
        switch self {
        case .compare: return String(localized: "tab.compare")
        case .brew:    return String(localized: "tab.brew")
        case .cabinet: return String(localized: "tab.cabinet")
        }
    }

    var icon: String {
        switch self {
        case .compare: return "chart.bar.fill"
        case .brew:    return "wineglass.fill"
        case .cabinet: return "cabinet.fill"
        }
    }
}

// MARK: - Root View

struct ContentView: View {
    @State private var selectedTab: AppTab = .brew
    @State private var cabinetStore = CabinetStore()

    var body: some View {
        TabView(selection: $selectedTab) {
            CompareView(store: cabinetStore)
                .tabItem {
                    Label(String(localized: "tab.compare"), systemImage: "chart.bar.fill")
                }
                .tag(AppTab.compare)

            BrewView()
                .tabItem {
                    Label(String(localized: "tab.brew"), systemImage: "wineglass.fill")
                }
                .tag(AppTab.brew)

            MyCabinetView(store: cabinetStore)
                .tabItem {
                    Label(String(localized: "tab.cabinet"), systemImage: "cabinet.fill")
                }
                .tag(AppTab.cabinet)
        }
        .tint(AppTheme.gold)
        .preferredColorScheme(.dark)
    }
}

#Preview { ContentView() }
