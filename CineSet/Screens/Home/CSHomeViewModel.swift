//
//  CSHomeViewModel.swift
//  CineSet
//
//  Created by edgar kosyan on 20/06/2026.
//

import Combine
import Foundation

@MainActor
final class CSHomeViewModel: ObservableObject {
    @Published private(set) var lastSetup: CineSetSetup?

    private let router: CSNavigationRouting
    private let settings: CSAppSettingsStoring

    init(router: CSNavigationRouting, settings: CSAppSettingsStoring) {
        self.router = router
        self.settings = settings
        reloadLastSetup()
    }

    func didTapStartCamera() {
        router.showCamera()
    }

    func didTapSettings() {
        router.showSettings()
    }

    func reloadLastSetup() {
        lastSetup = settings.lastSetup
    }
}
