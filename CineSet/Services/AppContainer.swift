//
//  AppContainer.swift
//  CineSet
//
//  Created by edgar kosyan on 20/06/2026.
//

import Foundation

@MainActor
final class AppContainer: CSNavigationRouting {
    let router = CSRouter()

    private let settings: CSAppSettingsStoring
    private(set) var activeCameraViewModel: CSCameraViewModel?
    private lazy var homeViewModel = CSHomeViewModel(router: self, settings: settings)

    init(settings: CSAppSettingsStoring = CSAppSettingsService()) {
        self.settings = settings
    }

    func makeHomeViewModel() -> CSHomeViewModel {
        homeViewModel
    }

    func makeSettingsViewModel() -> CSSettingsViewModel {
        CSSettingsViewModel(router: self)
    }

    func requireCameraViewModel() -> CSCameraViewModel {
        guard let activeCameraViewModel else {
            preconditionFailure("Camera session is not active")
        }
        return activeCameraViewModel
    }

    func showCamera() {
        beginCameraSession()
        router.navigate(to: .camera, style: .fullScreenCover)
    }

    func showSettings() {
        router.navigate(to: .settings, style: .sheet)
    }

    func dismissPresentedRoute() {
        if router.fullScreenCover == .camera {
            endCameraSession()
        }
        router.dismiss()
    }

    func endCameraSession() {
        if let activeCameraViewModel {
            settings.lastSetup = activeCameraViewModel.setupSnapshot
        }

        activeCameraViewModel?.stopCamera()
        activeCameraViewModel = nil
        homeViewModel.reloadLastSetup()
    }

    private func beginCameraSession() {
        guard activeCameraViewModel == nil else { return }

        let viewModel = CSCameraViewModel(
            cameraService: makeCameraService(),
            router: self
        )

        if let savedSetup = settings.lastSetup {
            viewModel.applySetup(savedSetup)
        }

        activeCameraViewModel = viewModel
    }

    private func makeCameraService() -> CSCameraVideoSessionServicing {
        CSCameraVideoSessionService()
    }
}

#if DEBUG
extension AppContainer {
    static func previewCameraViewModel() -> CSCameraViewModel {
        let container = AppContainer()
        container.showCamera()
        return container.requireCameraViewModel()
    }
}
#endif
