//
//  NDFilter.swift
//  CineSet
//
//  Created by edgar kosyan on 12/06/2026.
//

import Foundation

struct NDFilter: Identifiable, Equatable, Hashable {
    let title: String
    let stops: Float

    var id: String { title }

    static let clear = NDFilter(title: "ND 0", stops: 0)

    static let presets: [NDFilter] = [
        .clear,
        NDFilter(title: "ND 8", stops: 3),
        NDFilter(title: "ND 16", stops: 4),
        NDFilter(title: "ND 32", stops: 5),
        NDFilter(title: "ND 64", stops: 6),
        NDFilter(title: "ND 128", stops: 7),
        NDFilter(title: "ND 256", stops: 8)
    ]

    var hudTitle: String {
        stops == 0 ? "0" : title.replacingOccurrences(of: "ND ", with: "")
    }
}

enum NDMatchState: Equatable {
    case notRequired
    case insufficient(missingStops: Float)
    case matched
    case stronger(extraStops: Float)
}

/// Planning result comparing scene-metered exposure, target cinematic settings, and selected ND.
struct NDExposurePlan: Equatable {
    let meteredShutter: Int
    let meteredISO: Float
    let targetShutter: Int
    let targetISO: Float
    let requiredNDStops: Float
    let selectedNDStops: Float
    let differenceStops: Float
    let matchState: NDMatchState
}

enum NDExposurePlanner {
    /// Approximate stop tolerance for matched / insufficient / stronger classification.
    static let stopTolerance: Float = 0.5

    static func plan(
        meteredShutter: Int,
        meteredISO: Float,
        targetShutter: Int,
        targetISO: Float,
        selectedNDStops: Float
    ) -> NDExposurePlan {
        let required = requiredNDStops(
            meteredShutter: meteredShutter,
            meteredISO: meteredISO,
            targetShutter: targetShutter,
            targetISO: targetISO
        )
        let selected = max(selectedNDStops, 0)
        let difference = selected - required

        return NDExposurePlan(
            meteredShutter: meteredShutter,
            meteredISO: meteredISO,
            targetShutter: targetShutter,
            targetISO: targetISO,
            requiredNDStops: required,
            selectedNDStops: selected,
            differenceStops: difference,
            matchState: matchState(requiredNDStops: required, selectedNDStops: selected)
        )
    }

    /// Stops of ND required so target settings match metered scene brightness.
    static func requiredNDStops(
        meteredShutter: Int,
        meteredISO: Float,
        targetShutter: Int,
        targetISO: Float
    ) -> Float {
        guard
            meteredShutter > 0,
            meteredISO.isFinite,
            meteredISO > 0,
            targetShutter > 0,
            targetISO.isFinite,
            targetISO > 0
        else {
            return 0
        }

        let shutterStops = log2(Float(meteredShutter) / Float(targetShutter))
        let isoStops = log2(targetISO / meteredISO)
        return max(shutterStops + isoStops, 0)
    }

    static func matchState(requiredNDStops: Float, selectedNDStops: Float) -> NDMatchState {
        guard requiredNDStops > stopTolerance else {
            return .notRequired
        }

        let difference = selectedNDStops - requiredNDStops

        if difference < -stopTolerance {
            return .insufficient(missingStops: abs(difference))
        }

        if abs(difference) <= stopTolerance {
            return .matched
        }

        return .stronger(extraStops: difference)
    }

    /// Cosmetic preview adjustment from residual ND (required − selected), capped to keep preview usable.
    static func previewBrightnessAdjustment(
        requiredNDStops: Float,
        selectedNDStops: Float
    ) -> Double {
        let residualStops = requiredNDStops - selectedNDStops
        return min(max(Double(residualStops) * 0.07, -0.35), 0.35)
    }
}
