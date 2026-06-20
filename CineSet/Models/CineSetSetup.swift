//
//  CineSetSetup.swift
//  CineSet
//
//  Created by edgar kosyan on 20/06/2026.
//

import Foundation

struct CineSetSetup: Codable, Equatable {
    var ndFilterTitle: String
    var fps: Int
    var shutter: Int
    var iso: Float

    var ndDisplayTitle: String {
        ndFilter?.hudTitle ?? ndFilterTitle
    }

    var shutterDisplayTitle: String {
        "1/\(shutter)"
    }

    var isoDisplayTitle: String {
        "\(Int(iso))"
    }

    var ndFilter: NDFilter? {
        NDFilter.presets.first { $0.title == ndFilterTitle }
    }
}
