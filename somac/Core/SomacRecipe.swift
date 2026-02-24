//
//  SomacRecipe.swift
//  somac
//

import Foundation

/// Golden-ratio Somac (소맥) recipe: soju 25 ml + beer 50 ml.
struct SomacRecipe {
    /// Fixed soju volume (ml). Always half a standard 50 ml shot glass.
    let sojuML: Double = 25
    /// Fixed beer volume (ml). Twice the soju amount.
    let beerML: Double = 50

    // MARK: - Soju

    /// Soju fill ratio: always 0.5 (half glass), regardless of glass size.
    func sojuFillRatio() -> Double { 0.5 }

    // MARK: - Beer

    /// Height (metres) to fill beer glass to reach `beerML`.
    func beerFillHeight(glass: GlassMeasurement) -> Double {
        glass.fillHeight(for: beerML)
    }

    /// Ratio of glass height to fill for beer (0.0…1.0).
    func beerFillRatio(glass: GlassMeasurement) -> Double {
        glass.fillRatio(for: beerML)
    }
}
