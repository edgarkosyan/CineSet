//
//  CSRootView.swift
//  CineSet
//
//  Created by edgar kosyan on 20/06/2026.
//

import SwiftUI

struct CSRootView: View {
    @State private var container = AppContainer()

    var body: some View {
        @Bindable var router = container.router

        NavigationStack(path: $router.path) {
            CSHomeScreen(viewModel: container.makeHomeViewModel())
                .navigationDestination(for: CSRoute.self) { route in
                    CSRouteDestination(route: route, container: container)
                }
        }
        .sheet(item: $router.sheet) { route in
            CSRouteDestination(route: route, container: container)
        }
        .fullScreenCover(item: $router.fullScreenCover, onDismiss: {
            container.endCameraSession()
        }) { route in
            CSRouteDestination(route: route, container: container)
        }
    }
}

#Preview {
    CSRootView()
}
