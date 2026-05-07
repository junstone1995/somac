//
//  BrewView.swift
//  somac
//
//  제조 종류 선택 → 레시피 선택 → AR 측정 → 가이드 표시
//

import SwiftUI

// MARK: - Navigation

enum BrewRoute: Hashable {
    case recipeList(DrinkCategory)
    case measure(DrinkRecipe)
    case guide(DrinkRecipe, GlassMeasurement)
}



extension GlassMeasurement: Hashable {
    static func == (lhs: GlassMeasurement, rhs: GlassMeasurement) -> Bool {
        lhs.r1 == rhs.r1 && lhs.r2 == rhs.r2 && lhs.height == rhs.height
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(r1); hasher.combine(r2); hasher.combine(height)
    }
}

// MARK: - BrewView (카테고리 선택)

struct BrewView: View {
    @State private var path: [BrewRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(DrinkCategory.allCases) { category in
                            CategoryCard(category: category) {
                                path.append(.recipeList(category))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(AppTheme.darkBg)
            .navigationTitle(Text("brew.title"))
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: BrewRoute.self) { route in
                switch route {
                case .recipeList(let category):
                    RecipeListView(category: category) { recipe in
                        path.append(.measure(recipe))
                    }
                case .measure(let recipe):
                    MeasureView { glass in
                        path.append(.guide(recipe, glass))
                    }
                case .guide(let recipe, let glass):
                    GuideView(recipe: recipe, glass: glass)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("brew.header")
                .font(.title2.bold())
            Text("brew.header_sub")
                .font(.subheadline)
                .foregroundStyle(AppTheme.subtleText)
        }
        .padding(.top, 8)
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: DrinkCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(category.icon)
                    .font(.system(size: 44))
                Text(category.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .background(AppTheme.cardBg, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.gold.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recipe List

struct RecipeListView: View {
    let category: DrinkCategory
    let onSelect: (DrinkRecipe) -> Void

    private var recipes: [DrinkRecipe] {
        RecipePresets.all(for: category)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(recipes) { recipe in
                    RecipeCard(recipe: recipe) {
                        onSelect(recipe)
                    }
                }

                if recipes.isEmpty {
                    Text("brew.no_presets")
                        .foregroundStyle(AppTheme.subtleText)
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .background(AppTheme.darkBg)
        .navigationTitle(category.displayName)
    }
}

// MARK: - Recipe Card

struct RecipeCard: View {
    let recipe: DrinkRecipe
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 비율 바
                HStack(spacing: 0) {
                    ForEach(Array(recipe.layers.enumerated()), id: \.offset) { _, layer in
                        Rectangle()
                            .fill(Color(hex: layer.colorHex))
                            .frame(width: CGFloat(layer.ratio / recipe.totalParts) * 60)
                    }
                }
                .frame(width: 60, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(recipe.layers.map { "\($0.ingredient) \(Int($0.ratio))" }.joined(separator: " : "))
                        .font(.caption)
                        .foregroundStyle(AppTheme.subtleText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.gold)
            }
            .padding()
            .background(AppTheme.cardBg, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    BrewView()
        .preferredColorScheme(.dark)
}
