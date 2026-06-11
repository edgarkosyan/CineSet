//
//  CSCameraResolution.swift
//  CineSet
//
//  Created by edgar kosyan on 10/06/2026.
//

import Foundation

enum CSCameraResolution: Int, CaseIterable, Identifiable, Sendable, Comparable {
    case k4 = 2160
    case k2 = 1440
    case p1080 = 1080
    case p720 = 720

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .k4: "4K"
        case .k2: "2K"
        case .p1080: "1080p"
        case .p720: "720p"
        }
    }

    var targetShortEdge: Int { rawValue }

    static func < (lhs: CSCameraResolution, rhs: CSCameraResolution) -> Bool {
        lhs.rawValue > rhs.rawValue
    }
}
