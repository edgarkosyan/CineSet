//
//  CSNavigationRouting.swift
//  CineSet
//
//  Created by edgar kosyan on 20/06/2026.
//

import Foundation

@MainActor
protocol CSNavigationRouting: AnyObject {
    func showCamera()
    func showSettings()
    func dismissPresentedRoute()
}
