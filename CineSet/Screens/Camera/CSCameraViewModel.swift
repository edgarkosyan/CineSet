//
//  CSCameraViewModel.swift
//  CineSet
//
//  Created by edgar kosyan on 10/06/2026.
//

import Combine
import Foundation

@MainActor
final class CSCameraViewModel: ObservableObject {
    @Published private(set) var viewData: CSCameraViewData = .initial

    let labels = TDCameraLabels.localized
    let cameraService: CSCameraVideoSessionServicing

    private let router: CSNavigationRouting
    private let videoAccess: CSCameraVideoAccessServicing
    private let settingsEngine = CSCameraSettingsEngine()
    private var focusIndicatorTask: Task<Void, Never>?

    init(
        cameraService: CSCameraVideoSessionServicing,
        videoAccess: CSCameraVideoAccessServicing,
        router: CSNavigationRouting
    ) {
        self.cameraService = cameraService
        self.videoAccess = videoAccess
        self.router = router
    }

    var isExposureManual: Bool {
        viewData.user.manualControls.exposureMode == .manual
    }

    var isWhiteBalanceManual: Bool {
        viewData.user.manualControls.whiteBalanceMode == .manual
    }

    func prepareCamera() async {
        let authorization = await videoAccess.resolveVideoAccess()
        viewData.chrome.authorization = authorization
        if authorization == .authorized {
            startCamera()
        }
    }

    func startCamera() {
        let settings = settingsEngine.appliedSettings(from: viewData)
        cameraService.configure(applying: settings) { [weak self] capabilities, applied in
            self?.handleCapabilities(capabilities, applied: applied)
        }
    }

    func stopCamera() {
        focusIndicatorTask?.cancel()
        viewData.chrome.focusIndicatorPoint = nil
        cameraService.stop()
    }

    func focus(at viewPoint: CGPoint, devicePoint: CGPoint) {
        guard viewData.chrome.authorization == .authorized else { return }

        viewData.chrome.focusIndicatorPoint = viewPoint
        cameraService.focus(at: devicePoint, settings: settingsEngine.appliedSettings(from: viewData))

        focusIndicatorTask?.cancel()
        focusIndicatorTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            viewData.chrome.focusIndicatorPoint = nil
        }
    }

    func didTapClose() {
        router.dismissPresentedRoute()
    }

    func didTapCameraSettings() {
        viewData.chrome.isSettingsPresented = true
    }

    func setSettingsPresented(_ isPresented: Bool) {
        viewData.chrome.isSettingsPresented = isPresented
    }

    func send(_ change: CSCameraSettingsChange) {
        let effects = settingsEngine.applying(change, to: &viewData)
        run(effects)
    }

    private func handleCapabilities(
        _ capabilities: CSCameraCapabilities,
        applied: CSCameraAppliedSettings
    ) {
        settingsEngine.applyingCapabilities(capabilities, applied: applied, to: &viewData)
        run([.updateManualControls])
    }

    private func run(_ effects: [CSCameraSideEffect]) {
        let settings = settingsEngine.appliedSettings(from: viewData)

        for effect in effects {
            switch effect {
            case .updateResolution:
                cameraService.updateResolution(viewData.user.resolution, settings: settings) { [weak self] capabilities, applied in
                    self?.handleCapabilities(capabilities, applied: applied)
                }
            case .updateFPS:
                cameraService.updateFPS(viewData.user.fps, resolution: viewData.user.resolution)
            case .updateManualControls:
                cameraService.updateManualControls(settings)
            }
        }
    }
}
