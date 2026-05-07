//
//  CompareView.swift
//  somac
//
//  인기 술 리스트 → 선택 → 가격 비교 상세
//

import SwiftUI

// MARK: - CompareView (리스트)

struct CompareView: View {
    var store: CabinetStore

    @State private var searchText = ""
    @State private var selectedItem: AlcoholItem?

    private var filteredItems: [AlcoholItem] {
        if searchText.isEmpty {
            return AlcoholCatalog.items
        }
        return AlcoholCatalog.items.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedItems: [(String, [AlcoholItem])] {
        let dict = Dictionary(grouping: filteredItems, by: \.category)
        return dict.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 검색바
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.subtleText)
                        TextField(String(localized: "compare.search_placeholder"), text: $searchText)
                    }
                    .padding(12)
                    .background(AppTheme.cardBg, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // 카테고리별 리스트
                    ForEach(groupedItems, id: \.0) { category, items in
                        VStack(alignment: .leading, spacing: 10) {
                            // 카테고리 헤더
                            HStack(spacing: 6) {
                                Text(items.first?.categoryIcon ?? "")
                                Text(categoryDisplayName(category))
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.gold)
                            }
                            .padding(.horizontal)

                            // 술 카드 리스트
                            ForEach(items) { item in
                                AlcoholRow(item: item) {
                                    selectedItem = item
                                }
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
            .background(AppTheme.darkBg)
            .navigationTitle(Text("compare.title"))
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedItem) { item in
                CompareDetailSheet(item: item, store: store)
            }
        }
    }

    private func categoryDisplayName(_ key: String) -> String {
        switch key {
        case "whiskey": return String(localized: "compare.cat_whiskey")
        case "wine":    return String(localized: "compare.cat_wine")
        case "sake":    return String(localized: "compare.cat_sake")
        case "cognac":  return String(localized: "compare.cat_cognac")
        case "liqueur": return String(localized: "compare.cat_liqueur")
        case "vodka":   return String(localized: "compare.cat_vodka")
        default:        return key
        }
    }
}

// MARK: - Alcohol Row

struct AlcoholRow: View {
    let item: AlcoholItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(item.imageEmoji)
                    .font(.system(size: 36))
                    .frame(width: 52, height: 52)
                    .background(AppTheme.darkBg, in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(String(localized: "compare.domestic_avg_label"))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.subtleText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("₩\(item.domesticAvgKRW.formatted())")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(String(localized: "compare.tap_to_compare"))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.gold)
                }
            }
            .padding(12)
            .background(AppTheme.cardBg, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compare Detail Sheet

struct CompareDetailSheet: View {
    let item: AlcoholItem
    var store: CabinetStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCurrencyId = "JPY"
    @State private var foreignPriceText = ""
    @State private var showResult = false

    private var selectedCurrency: CurrencyInfo {
        CurrencyStore.find(selectedCurrencyId) ?? CurrencyStore.currencies[0]
    }

    private var foreignPrice: Double {
        Double(foreignPriceText) ?? 0
    }

    private var krwConverted: Double {
        foreignPrice * selectedCurrency.rateToKRW
    }

    private var savings: Double {
        Double(item.domesticAvgKRW) - krwConverted
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 술 정보 헤더
                    VStack(spacing: 8) {
                        Text(item.imageEmoji)
                            .font(.system(size: 56))
                        Text(item.name)
                            .font(.title3.bold())
                        HStack(spacing: 4) {
                            Text(String(localized: "compare.domestic_avg"))
                            Text("₩\(item.domesticAvgKRW.formatted())")
                                .bold()
                        }
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.subtleText)
                    }
                    .padding(.top, 8)

                    // 국가 선택
                    VStack(alignment: .leading, spacing: 6) {
                        Text("compare.country")
                            .font(.caption)
                            .foregroundStyle(AppTheme.subtleText)
                            .padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(CurrencyStore.currencies) { cur in
                                    Button {
                                        selectedCurrencyId = cur.id
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(cur.flag)
                                            Text(cur.id).font(.caption.bold())
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedCurrencyId == cur.id
                                                ? AppTheme.gold.opacity(0.3)
                                                : AppTheme.cardBg
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(
                                                selectedCurrencyId == cur.id ? AppTheme.gold : Color.clear,
                                                lineWidth: 1
                                            )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // 해외 가격 입력
                    VStack(alignment: .leading, spacing: 6) {
                        Text("compare.foreign_price")
                            .font(.caption)
                            .foregroundStyle(AppTheme.subtleText)
                        HStack {
                            Text(selectedCurrency.symbol)
                                .foregroundStyle(AppTheme.gold)
                                .font(.title3)
                            TextField("0", text: $foreignPriceText)
                                .keyboardType(.decimalPad)
                                .font(.title2)
                        }
                        .padding()
                        .background(AppTheme.cardBg, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // 비교 버튼
                    Button {
                        showResult = true
                    } label: {
                        Text("compare.calculate")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.gold)
                    .disabled(foreignPriceText.isEmpty)
                    .padding(.horizontal)

                    // 결과
                    if showResult {
                        resultCard
                    }
                }
                .padding(.bottom, 32)
            }
            .background(AppTheme.darkBg)
            .navigationTitle(Text("compare.detail_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.subtleText)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Result Card

    private var resultCard: some View {
        VStack(spacing: 16) {
            // 환율 변환
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("compare.foreign")
                        .font(.caption)
                        .foregroundStyle(AppTheme.subtleText)
                    Text("\(selectedCurrency.symbol)\(foreignPriceText)")
                        .font(.title2.bold())
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundStyle(AppTheme.gold)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("compare.converted")
                        .font(.caption)
                        .foregroundStyle(AppTheme.subtleText)
                    Text("₩\(Int(krwConverted).formatted())")
                        .font(.title2.bold())
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // 국내 평균가
            HStack {
                Text("compare.domestic_avg")
                    .foregroundStyle(AppTheme.subtleText)
                Spacer()
                Text("₩\(item.domesticAvgKRW.formatted())")
                    .font(.title3.bold())
            }

            Divider().background(Color.white.opacity(0.1))

            // 절약 금액
            HStack {
                Text("compare.savings")
                    .font(.headline)
                Spacer()
                Text("₩\(Int(savings).formatted())")
                    .font(.title.bold())
                    .foregroundStyle(savings > 0 ? .green : .red)
            }

            Text(savings > 0
                 ? String(localized: "compare.cheaper_abroad")
                 : String(localized: "compare.cheaper_domestic"))
                .font(.caption)
                .foregroundStyle(AppTheme.subtleText)

            // 저장 버튼
            Button {
                let record = ComparisonRecord(
                    alcoholName: item.name,
                    foreignPrice: foreignPrice,
                    currencyId: selectedCurrencyId,
                    krwConverted: krwConverted,
                    domesticPrice: Double(item.domesticAvgKRW),
                    savings: savings
                )
                store.addComparison(record)
                dismiss()
            } label: {
                Label("compare.save", systemImage: "square.and.arrow.down")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.gold)
        }
        .padding()
        .background(AppTheme.cardBg, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Make AlcoholItem work with .sheet(item:)

extension AlcoholItem: @retroactive Equatable {
    static func == (lhs: AlcoholItem, rhs: AlcoholItem) -> Bool { lhs.id == rhs.id }
}
extension AlcoholItem: @retroactive Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

#Preview {
    CompareView(store: CabinetStore())
        .preferredColorScheme(.dark)
}
