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

    private(set) var activeCameraViewModel: CSCameraViewModel?
    private lazy var homeViewModel = CSHomeViewModel(router: self)

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
        activeCameraViewModel?.stopCamera()
        activeCameraViewModel = nil
    }

    private func beginCameraSession() {
        guard activeCameraViewModel == nil else { return }

        activeCameraViewModel = CSCameraViewModel(
            cameraService: makeCameraService(),
            videoAccess: makeVideoAccessService(),
            router: self
        )
    }

    private func makeCameraService() -> CSCameraVideoSessionServicing {
        CSCameraVideoSessionService()
    }

    private func makeVideoAccessService() -> CSCameraVideoAccessServicing {
        CSCameraVideoAccessService()
    }
}

#if DEBUG
extension AppContainer {
    static func previewCameraViewModel() -> CSCameraViewModel {
        let container = AppContainer()
        return CSCameraViewModel(
            cameraService: CSCameraVideoSessionService(),
            videoAccess: PreviewCameraVideoAccess(),
            router: container
        )
    }
}
#endif
