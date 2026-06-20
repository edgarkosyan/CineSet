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

struct NDExposureResult: Equatable {
    let appliedShutter: Int
    let appliedISO: Float
    let overlayOpacity: Double
}

enum NDExposureSimulator {
    static func simulate(
        baseShutter: Int,
        baseISO: Float,
        ndStops: Float,
        shutterOptions: [Int],
        isoOptions: [Float]
    ) -> NDExposureResult {
        guard ndStops > 0, baseShutter > 0, baseISO > 0 else {
            return NDExposureResult(
                appliedShutter: baseShutter,
                appliedISO: baseISO,
                overlayOpacity: 0
            )
        }

        let factor = pow(2.0, ndStops)
        let idealShutter = Int(round(Float(baseShutter) * factor))
        let idealISO = baseISO / Float(factor)

        let appliedShutter = nearestShutter(
            ideal: idealShutter,
            in: shutterOptions,
            base: baseShutter,
            fallback: idealShutter
        )
        let appliedISO = nearestISO(
            ideal: idealISO,
            in: isoOptions,
            base: baseISO,
            fallback: idealISO
        )

        let shutterStops = log2(max(Float(appliedShutter) / Float(baseShutter), 1))
        let isoStops = log2(max(baseISO / appliedISO, 1))
        let achievedStops = shutterStops + isoStops
        let remainingStops = max(ndStops - achievedStops, 0)
        let overlayOpacity = remainingStops > 0 ? 1 - pow(0.5, Double(remainingStops)) : 0

        return NDExposureResult(
            appliedShutter: appliedShutter,
            appliedISO: appliedISO,
            overlayOpacity: overlayOpacity
        )
    }

    private static func nearestShutter(ideal: Int, in options: [Int], base: Int, fallback: Int) -> Int {
        guard !options.isEmpty else { return fallback }
        let darkerOptions = options.filter { $0 >= base }
        let pool = darkerOptions.isEmpty ? options : darkerOptions
        return pool.min(by: { abs($0 - ideal) < abs($1 - ideal) }) ?? fallback
    }

    private static func nearestISO(ideal: Float, in options: [Float], base: Float, fallback: Float) -> Float {
        guard !options.isEmpty else { return fallback }
        let darkerOptions = options.filter { $0 <= base }
        let pool = darkerOptions.isEmpty ? options : darkerOptions
        return pool.min(by: { abs($0 - ideal) < abs($1 - ideal) }) ?? fallback
    }
}
