//
//  Models.swift
//  somac
//

import Foundation

// MARK: - 제조 카테고리

enum DrinkCategory: String, CaseIterable, Identifiable, Codable {
    case somac    = "somac"
    case highball = "highball"
    case cocktail = "cocktail"
    case custom   = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .somac:    return String(localized: "category.somac")
        case .highball: return String(localized: "category.highball")
        case .cocktail: return String(localized: "category.cocktail")
        case .custom:   return String(localized: "category.custom")
        }
    }

    var icon: String {
        switch self {
        case .somac:    return "🍺"
        case .highball: return "🥃"
        case .cocktail: return "🍸"
        case .custom:   return "🧪"
        }
    }
}

// MARK: - 레시피

struct DrinkRecipe: Identifiable, Codable, Hashable {
    let id: UUID
    let category: DrinkCategory
    let name: String
    let nameKey: String
    let layers: [RecipeLayer]

    init(id: UUID = UUID(), category: DrinkCategory, name: String, nameKey: String, layers: [RecipeLayer]) {
        self.id = id
        self.category = category
        self.name = name
        self.nameKey = nameKey
        self.layers = layers
    }

    var totalParts: Double {
        layers.reduce(0) { $0 + $1.ratio }
    }
}

struct RecipeLayer: Codable, Hashable {
    let ingredient: String
    let ingredientKey: String
    let ratio: Double
    let colorHex: String
}

// MARK: - 프리셋 레시피

struct RecipePresets {
    // 소맥
    static let somacGolden = DrinkRecipe(
        category: .somac, name: "황금비율", nameKey: "recipe.somac_golden",
        layers: [
            RecipeLayer(ingredient: "소주", ingredientKey: "ingredient.soju", ratio: 1, colorHex: "3A8EF6"),
            RecipeLayer(ingredient: "맥주", ingredientKey: "ingredient.beer", ratio: 2, colorHex: "F5A623")
        ])

    static let somacStrong = DrinkRecipe(
        category: .somac, name: "진한 소맥", nameKey: "recipe.somac_strong",
        layers: [
            RecipeLayer(ingredient: "소주", ingredientKey: "ingredient.soju", ratio: 2, colorHex: "3A8EF6"),
            RecipeLayer(ingredient: "맥주", ingredientKey: "ingredient.beer", ratio: 1, colorHex: "F5A623")
        ])

    static let somacLight = DrinkRecipe(
        category: .somac, name: "약한 소맥", nameKey: "recipe.somac_light",
        layers: [
            RecipeLayer(ingredient: "소주", ingredientKey: "ingredient.soju", ratio: 1, colorHex: "3A8EF6"),
            RecipeLayer(ingredient: "맥주", ingredientKey: "ingredient.beer", ratio: 3, colorHex: "F5A623")
        ])

    // 하이볼
    static let highballClassic = DrinkRecipe(
        category: .highball, name: "이자카야 스타일", nameKey: "recipe.highball_classic",
        layers: [
            RecipeLayer(ingredient: "위스키", ingredientKey: "ingredient.whiskey", ratio: 1, colorHex: "C68B3E"),
            RecipeLayer(ingredient: "탄산수", ingredientKey: "ingredient.soda", ratio: 3, colorHex: "B8E6F0")
        ])

    static let highballStrong = DrinkRecipe(
        category: .highball, name: "진한 하이볼", nameKey: "recipe.highball_strong",
        layers: [
            RecipeLayer(ingredient: "위스키", ingredientKey: "ingredient.whiskey", ratio: 1, colorHex: "C68B3E"),
            RecipeLayer(ingredient: "탄산수", ingredientKey: "ingredient.soda", ratio: 2, colorHex: "B8E6F0")
        ])

    static let highballLight = DrinkRecipe(
        category: .highball, name: "가벼운 하이볼", nameKey: "recipe.highball_light",
        layers: [
            RecipeLayer(ingredient: "위스키", ingredientKey: "ingredient.whiskey", ratio: 1, colorHex: "C68B3E"),
            RecipeLayer(ingredient: "탄산수", ingredientKey: "ingredient.soda", ratio: 4, colorHex: "B8E6F0")
        ])

    // 칵테일
    static let ginTonic = DrinkRecipe(
        category: .cocktail, name: "진토닉", nameKey: "recipe.gin_tonic",
        layers: [
            RecipeLayer(ingredient: "진", ingredientKey: "ingredient.gin", ratio: 1, colorHex: "7ED6C1"),
            RecipeLayer(ingredient: "토닉워터", ingredientKey: "ingredient.tonic", ratio: 2, colorHex: "E8E8E8")
        ])

    static let jackCoke = DrinkRecipe(
        category: .cocktail, name: "잭콕", nameKey: "recipe.jack_coke",
        layers: [
            RecipeLayer(ingredient: "잭다니엘", ingredientKey: "ingredient.jack", ratio: 1, colorHex: "8B4513"),
            RecipeLayer(ingredient: "콜라", ingredientKey: "ingredient.cola", ratio: 2, colorHex: "3D1C02")
        ])

    static let moscowMule = DrinkRecipe(
        category: .cocktail, name: "모스코뮬", nameKey: "recipe.moscow_mule",
        layers: [
            RecipeLayer(ingredient: "보드카", ingredientKey: "ingredient.vodka", ratio: 1, colorHex: "D4D4D4"),
            RecipeLayer(ingredient: "진저비어", ingredientKey: "ingredient.ginger_beer", ratio: 3, colorHex: "C89B3C")
        ])

    static func all(for category: DrinkCategory) -> [DrinkRecipe] {
        switch category {
        case .somac:    return [somacGolden, somacStrong, somacLight]
        case .highball: return [highballClassic, highballStrong, highballLight]
        case .cocktail: return [ginTonic, jackCoke, moscowMule]
        case .custom:   return []
        }
    }
}

// MARK: - 통화

struct CurrencyInfo: Identifiable {
    let id: String       // "JPY", "USD", etc.
    let name: String
    let nameKey: String
    let symbol: String
    let flag: String
    let rateToKRW: Double // 1 unit → KRW (approximate defaults)
}

struct CurrencyStore {
    static let currencies: [CurrencyInfo] = [
        CurrencyInfo(id: "JPY", name: "일본 엔", nameKey: "currency.jpy", symbol: "¥", flag: "🇯🇵", rateToKRW: 9.2),
        CurrencyInfo(id: "USD", name: "미국 달러", nameKey: "currency.usd", symbol: "$", flag: "🇺🇸", rateToKRW: 1380),
        CurrencyInfo(id: "EUR", name: "유로", nameKey: "currency.eur", symbol: "€", flag: "🇪🇺", rateToKRW: 1500),
        CurrencyInfo(id: "GBP", name: "영국 파운드", nameKey: "currency.gbp", symbol: "£", flag: "🇬🇧", rateToKRW: 1750),
        CurrencyInfo(id: "CNY", name: "중국 위안", nameKey: "currency.cny", symbol: "¥", flag: "🇨🇳", rateToKRW: 190),
        CurrencyInfo(id: "THB", name: "태국 바트", nameKey: "currency.thb", symbol: "฿", flag: "🇹🇭", rateToKRW: 39),
    ]

    static func find(_ id: String) -> CurrencyInfo? {
        currencies.first { $0.id == id }
    }
}

// MARK: - 인기 술 데이터

struct AlcoholItem: Identifiable {
    let id: String
    let name: String
    let nameKey: String
    let category: String         // "whiskey", "wine", "sake", etc.
    let categoryIcon: String
    let domesticAvgKRW: Int      // 국내 평균가 (원)
    let imageEmoji: String       // placeholder
}

struct AlcoholCatalog {
    static let items: [AlcoholItem] = [
        // 위스키
        AlcoholItem(id: "yamazaki12", name: "산토리 야마자키 12년", nameKey: "alcohol.yamazaki12",
                    category: "whiskey", categoryIcon: "🥃", domesticAvgKRW: 198_000, imageEmoji: "🥃"),
        AlcoholItem(id: "hibiki_harmony", name: "히비키 하모니", nameKey: "alcohol.hibiki_harmony",
                    category: "whiskey", categoryIcon: "🥃", domesticAvgKRW: 120_000, imageEmoji: "🥃"),
        AlcoholItem(id: "macallan12", name: "맥캘란 12년", nameKey: "alcohol.macallan12",
                    category: "whiskey", categoryIcon: "🥃", domesticAvgKRW: 89_000, imageEmoji: "🥃"),
        AlcoholItem(id: "jw_blue", name: "조니워커 블루라벨", nameKey: "alcohol.jw_blue",
                    category: "whiskey", categoryIcon: "🥃", domesticAvgKRW: 280_000, imageEmoji: "🥃"),
        AlcoholItem(id: "jack_single", name: "잭다니엘 싱글배럴", nameKey: "alcohol.jack_single",
                    category: "whiskey", categoryIcon: "🥃", domesticAvgKRW: 65_000, imageEmoji: "🥃"),
        // 와인
        AlcoholItem(id: "opus_one", name: "오퍼스 원", nameKey: "alcohol.opus_one",
                    category: "wine", categoryIcon: "🍷", domesticAvgKRW: 450_000, imageEmoji: "🍷"),
        AlcoholItem(id: "mouton", name: "무통 로칠드", nameKey: "alcohol.mouton",
                    category: "wine", categoryIcon: "🍷", domesticAvgKRW: 380_000, imageEmoji: "🍷"),
        // 사케
        AlcoholItem(id: "dassai23", name: "닷사이 23", nameKey: "alcohol.dassai23",
                    category: "sake", categoryIcon: "🍶", domesticAvgKRW: 95_000, imageEmoji: "🍶"),
        AlcoholItem(id: "juyondai", name: "주욘다이 혼죠조", nameKey: "alcohol.juyondai",
                    category: "sake", categoryIcon: "🍶", domesticAvgKRW: 150_000, imageEmoji: "🍶"),
        // 리큐르/기타
        AlcoholItem(id: "hennessy_vs", name: "헤네시 VS", nameKey: "alcohol.hennessy_vs",
                    category: "cognac", categoryIcon: "🍸", domesticAvgKRW: 75_000, imageEmoji: "🍸"),
        AlcoholItem(id: "baileys", name: "베일리스", nameKey: "alcohol.baileys",
                    category: "liqueur", categoryIcon: "🥛", domesticAvgKRW: 32_000, imageEmoji: "🥛"),
        AlcoholItem(id: "absolut", name: "앱솔루트 보드카", nameKey: "alcohol.absolut",
                    category: "vodka", categoryIcon: "🧊", domesticAvgKRW: 25_000, imageEmoji: "🧊"),
    ]

    static var categories: [String] {
        Array(Set(items.map(\.category))).sorted()
    }

    static func items(for category: String) -> [AlcoholItem] {
        items.filter { $0.category == category }
    }
}

// MARK: - 내 술장 아이템

struct CabinetItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: String       // "whiskey", "soju", etc.
    var note: String
    var isFavorite: Bool
    var dateAdded: Date

    init(id: UUID = UUID(), name: String, category: String = "", note: String = "", isFavorite: Bool = false, dateAdded: Date = .now) {
        self.id = id
        self.name = name
        self.category = category
        self.note = note
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
    }
}

struct ComparisonRecord: Identifiable, Codable {
    let id: UUID
    var alcoholName: String
    var foreignPrice: Double
    var currencyId: String
    var krwConverted: Double
    var domesticPrice: Double
    var savings: Double
    var date: Date

    init(id: UUID = UUID(), alcoholName: String, foreignPrice: Double, currencyId: String, krwConverted: Double, domesticPrice: Double, savings: Double, date: Date = .now) {
        self.id = id
        self.alcoholName = alcoholName
        self.foreignPrice = foreignPrice
        self.currencyId = currencyId
        self.krwConverted = krwConverted
        self.domesticPrice = domesticPrice
        self.savings = savings
        self.date = date
    }
}
