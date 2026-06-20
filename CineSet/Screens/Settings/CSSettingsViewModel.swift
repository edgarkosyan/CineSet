//
//  CSSettingsViewModel.swift
//  CineSet
//
//  Created by edgar kosyan on 20/06/2026.
//

import Combine
import Foundation

@MainActor
final class CSSettingsViewModel: ObservableObject {
    private let router: CSNavigationRouting

    init(router: CSNavigationRouting) {
        self.router = router
    }

    func didTapDone() {
        router.dismissPresentedRoute()
    }
}
