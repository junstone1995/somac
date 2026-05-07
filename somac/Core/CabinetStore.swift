//
//  CabinetStore.swift
//  somac
//

import SwiftUI

// MARK: - 내 술장 저장소

@Observable
final class CabinetStore {
    var items: [CabinetItem] = []
    var comparisons: [ComparisonRecord] = []
    var favoriteRecipes: [DrinkRecipe] = []

    private let itemsKey = "cabinet_items"
    private let comparisonsKey = "cabinet_comparisons"

    init() {
        loadItems()
        loadComparisons()
    }

    // MARK: - Items

    func addItem(_ item: CabinetItem) {
        items.insert(item, at: 0)
        saveItems()
    }

    func removeItem(_ item: CabinetItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }

    func toggleFavorite(_ item: CabinetItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isFavorite.toggle()
            saveItems()
        }
    }

    // MARK: - Comparisons

    func addComparison(_ record: ComparisonRecord) {
        comparisons.insert(record, at: 0)
        saveComparisons()
    }

    func removeComparison(_ record: ComparisonRecord) {
        comparisons.removeAll { $0.id == record.id }
        saveComparisons()
    }

    // MARK: - Persistence

    private func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: itemsKey)
        }
    }

    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: itemsKey),
              let decoded = try? JSONDecoder().decode([CabinetItem].self, from: data) else { return }
        items = decoded
    }

    private func saveComparisons() {
        if let data = try? JSONEncoder().encode(comparisons) {
            UserDefaults.standard.set(data, forKey: comparisonsKey)
        }
    }

    private func loadComparisons() {
        guard let data = UserDefaults.standard.data(forKey: comparisonsKey),
              let decoded = try? JSONDecoder().decode([ComparisonRecord].self, from: data) else { return }
        comparisons = decoded
    }
}
