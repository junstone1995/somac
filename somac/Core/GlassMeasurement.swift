//
//  GlassMeasurement.swift
//  somac
//

import Foundation

/// Frustum (truncated cone) model of a glass.
/// All dimensions in meters; volumes computed in ml (1 ml = 1 cm³ = 1e-6 m³).
struct GlassMeasurement {
    /// Bottom radius in meters.
    let r1: Double
    /// Top radius in meters.
    let r2: Double
    /// Glass height in meters.
    let height: Double

    // MARK: - Volume

    /// Total frustum volume in millilitres.
    func frustumVolume() -> Double {
        volumeUpTo(h: height)
    }

    /// Volume of liquid (ml) when filled to `h` metres from the bottom.
    /// The radius at height h is linearly interpolated: r(h) = r1 + (r2 - r1) * h / height
    /// Sub-frustum from 0..h has r_bottom = r1, r_top = r(h).
    func volumeUpTo(h: Double) -> Double {
        guard h > 0 else { return 0 }
        let clampedH = min(h, height)
        let rTop = r1 + (r2 - r1) * clampedH / height
        // Frustum volume formula (m³) converted to ml (×1e6)
        let volumeM3 = (Double.pi * clampedH / 3.0) * (r1 * r1 + r1 * rTop + rTop * rTop)
        return volumeM3 * 1_000_000
    }

    // MARK: - Fill Height

    /// Returns the fill height (metres) that yields `targetVolume` ml,
    /// found via binary search. Clamps to [0, height].
    func fillHeight(for targetVolume: Double) -> Double {
        guard targetVolume > 0 else { return 0 }
        let total = frustumVolume()
        guard targetVolume < total else { return height }

        var lo = 0.0
        var hi = height
        let tolerance = 1e-9  // metres (~1 nanometre)

        for _ in 0..<60 {
            let mid = (lo + hi) / 2.0
            if volumeUpTo(h: mid) < targetVolume {
                lo = mid
            } else {
                hi = mid
            }
            if hi - lo < tolerance { break }
        }
        return (lo + hi) / 2.0
    }

    // MARK: - Fill Ratio

    /// Fraction of glass height to fill for `targetVolume` ml (0.0…1.0).
    func fillRatio(for targetVolume: Double) -> Double {
        fillHeight(for: targetVolume) / height
    }
}
