//
//  CSRouteDestination.swift
//  CineSet
//
//  Created by edgar kosyan on 20/06/2026.
//

import SwiftUI

struct CSRouteDestination: View {
    let route: CSRoute
    let container: AppContainer

    var body: some View {
        switch route {
        case .camera:
            CSCameraScreen(viewModel: container.requireCameraViewModel())
        case .settings:
            CSSettingsScreen(viewModel: container.makeSettingsViewModel())
        }
    }
}
