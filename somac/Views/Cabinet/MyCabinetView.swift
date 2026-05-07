//
//  MyCabinetView.swift
//  somac
//
//  내 술장 - 즐겨찾기 & 비교 내역
//

import SwiftUI

struct MyCabinetView: View {
    var store: CabinetStore

    @State private var selectedSection: CabinetSection = .favorites
    @State private var showAddSheet = false

    enum CabinetSection: String, CaseIterable {
        case favorites
        case history

        var title: String {
            switch self {
            case .favorites: return String(localized: "cabinet.favorites")
            case .history:   return String(localized: "cabinet.history")
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 세그먼트 피커
                Picker("Section", selection: $selectedSection) {
                    ForEach(CabinetSection.allCases, id: \.self) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // 콘텐츠
                switch selectedSection {
                case .favorites:
                    favoritesSection
                case .history:
                    historySection
                }
            }
            .background(AppTheme.darkBg)
            .navigationTitle(Text("cabinet.title"))
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                    .tint(AppTheme.gold)
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddItemSheet(store: store)
            }
        }
    }

    // MARK: - Favorites

    private var favoritesSection: some View {
        Group {
            if store.items.isEmpty {
                emptyState(
                    icon: "heart.slash",
                    message: String(localized: "cabinet.empty_favorites")
                )
            } else {
                List {
                    ForEach(store.items) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                if !item.category.isEmpty {
                                    Text(item.category)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.subtleText)
                                }
                                if !item.note.isEmpty {
                                    Text(item.note)
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.subtleText)
                                }
                            }
                            Spacer()
                            Button {
                                store.toggleFavorite(item)
                            } label: {
                                Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                                    .foregroundStyle(item.isFavorite ? .red : AppTheme.subtleText)
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(AppTheme.cardBg)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            store.removeItem(store.items[index])
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - History

    private var historySection: some View {
        Group {
            if store.comparisons.isEmpty {
                emptyState(
                    icon: "clock.arrow.circlepath",
                    message: String(localized: "cabinet.empty_history")
                )
            } else {
                List {
                    ForEach(store.comparisons) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(record.alcoholName.isEmpty ? String(localized: "cabinet.unnamed") : record.alcoholName)
                                    .font(.headline)
                                Spacer()
                                Text(record.date, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.subtleText)
                            }
                            HStack {
                                let cur = CurrencyStore.find(record.currencyId)
                                Text("\(cur?.symbol ?? "")\(Int(record.foreignPrice).formatted())")
                                    .font(.subheadline)
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.gold)
                                Text("₩\(Int(record.krwConverted).formatted())")
                                    .font(.subheadline)
                                Spacer()
                                Text("₩\(Int(record.savings).formatted())")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(record.savings > 0 ? .green : .red)
                            }
                        }
                        .listRowBackground(AppTheme.cardBg)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            store.removeComparison(store.comparisons[index])
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.subtleText)
            Text(message)
                .foregroundStyle(AppTheme.subtleText)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Item Sheet

struct AddItemSheet: View {
    var store: CabinetStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "cabinet.add_name")) {
                    TextField(String(localized: "cabinet.name_placeholder"), text: $name)
                }
                Section(String(localized: "cabinet.add_category")) {
                    TextField(String(localized: "cabinet.category_placeholder"), text: $category)
                }
                Section(String(localized: "cabinet.add_note")) {
                    TextField(String(localized: "cabinet.note_placeholder"), text: $note)
                }
            }
            .navigationTitle(Text("cabinet.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        store.addItem(CabinetItem(name: name, category: category, note: note, isFavorite: true))
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MyCabinetView(store: CabinetStore())
        .preferredColorScheme(.dark)
}
