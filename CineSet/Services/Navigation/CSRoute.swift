//
//  CSRoute.swift
//  CineSet
//
//  Created by edgar kosyan on 20/06/2026.
//

import Foundation

enum CSRoute: Hashable, Identifiable {
    case camera
    case settings

    var id: Self { self }
}

enum CSNavigationStyle {
    case push
    case sheet
    case fullScreenCover
}
