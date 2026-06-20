//
//  CSCameraViewModel.swift
//  CineSet
//
//  Created by edgar kosyan on 10/06/2026.
//

import AVFoundation
import Combine
import Foundation

enum CSCameraAuthorizationState {
    case notDetermined
    case authorized
    case denied
}

@MainActor
final class CSCameraViewModel: ObservableObject {
    @Published var selectedResolution: CSCameraResolution = .p1080 {
        didSet {
            guard !isSyncingSettings else { return }
            cameraService.updateResolution(selectedResolution, settings: currentSettings) { [weak self] capabilities, applied in
                self?.applyCapabilities(capabilities, applied: applied)
            }
        }
    }

    @Published var selectedFPS: Int = 25 {
        didSet {
            guard !isSyncingSettings else { return }
            cameraService.updateFPS(selectedFPS, resolution: selectedResolution)
        }
    }

    @Published var selectedShutter: Int = 50 {
        didSet { applyNDSimulation() }
    }

    @Published var selectedISO: Float = 100 {
        didSet { applyNDSimulation() }
    }

    @Published var selectedNDFilter: NDFilter = .clear {
        didSet { applyNDSimulation() }
    }

    @Published private(set) var ndOverlayOpacity: Double = 0

    @Published var exposureMode: CSCameraControlMode = .manual {
        didSet { applyManualControls() }
    }

    @Published var whiteBalanceMode: CSCameraControlMode = .auto {
        didSet { applyManualControls() }
    }

    @Published var whiteBalanceTemperature: Float = 5_500 {
        didSet { applyManualControls() }
    }

    @Published var whiteBalanceTint: Float = 0 {
        didSet { applyManualControls() }
    }

    @Published var isHDRAutoAdjustmentEnabled: Bool = false {
        didSet { applyManualControls() }
    }

    @Published var isLowLightBoostEnabled: Bool = false {
        didSet { applyManualControls() }
    }

    @Published var focusMode: CSCameraControlMode = .auto {
        didSet { applyManualControls() }
    }

    @Published private(set) var authorizationState: CSCameraAuthorizationState = .notDetermined
    @Published private(set) var resolutionOptions: [CSCameraResolution] = []
    @Published private(set) var fpsOptions: [Int] = []
    @Published private(set) var shutterOptions: [Int] = []
    @Published private(set) var isoOptions: [Float] = []
    @Published private(set) var supportsLowLightBoost = false
    @Published private(set) var areCapabilitiesLoaded = false
    @Published var focusIndicatorPoint: CGPoint?

    let cameraService: CSCameraVideoSessionServicing

    private var appliedShutter: Int = 50
    private var appliedISO: Float = 100
    private var isSyncingSettings = false
    private var focusIndicatorTask: Task<Void, Never>?

    init(cameraService: CSCameraVideoSessionServicing = CSCameraVideoSessionService()) {
        self.cameraService = cameraService
    }

    var isExposureManual: Bool {
        exposureMode == .manual
    }

    var isWhiteBalanceManual: Bool {
        whiteBalanceMode == .manual
    }

    func prepareCamera() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            authorizationState = .authorized
            startCamera()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationState = granted ? .authorized : .denied
            if granted {
                startCamera()
            }
        case .denied, .restricted:
            authorizationState = .denied
        @unknown default:
            authorizationState = .denied
        }
    }

    func startCamera() {
        cameraService.configure(applying: currentSettings) { [weak self] capabilities, applied in
            self?.applyCapabilities(capabilities, applied: applied)
        }
    }

    func stopCamera() {
        focusIndicatorTask?.cancel()
        focusIndicatorPoint = nil
        cameraService.stop()
    }

    func focus(at viewPoint: CGPoint, devicePoint: CGPoint) {
        guard authorizationState == .authorized else { return }

        focusIndicatorPoint = viewPoint
        cameraService.focus(at: devicePoint, settings: currentSettings)

        focusIndicatorTask?.cancel()
        focusIndicatorTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            focusIndicatorPoint = nil
        }
    }

    private func applyNDSimulation() {
        guard !isSyncingSettings else { return }

        let result = NDExposureSimulator.simulate(
            baseShutter: selectedShutter,
            baseISO: selectedISO,
            ndStops: selectedNDFilter.stops,
            shutterOptions: shutterOptions,
            isoOptions: isoOptions
        )

        appliedShutter = result.appliedShutter
        appliedISO = result.appliedISO
        ndOverlayOpacity = result.overlayOpacity

        applyManualControls()
    }

    private func applyManualControls() {
        guard !isSyncingSettings else { return }
        cameraService.updateManualControls(currentSettings)
    }

    private var currentSettings: CSCameraAppliedSettings {
        CSCameraAppliedSettings(
            resolution: selectedResolution,
            fps: selectedFPS,
            shutter: appliedShutter,
            iso: appliedISO,
            manualControls: CSCameraManualControls(
                exposureMode: exposureMode,
                whiteBalanceMode: whiteBalanceMode,
                whiteBalanceTemperature: whiteBalanceTemperature,
                whiteBalanceTint: whiteBalanceTint,
                isHDRAutoAdjustmentEnabled: isHDRAutoAdjustmentEnabled,
                isLowLightBoostEnabled: isLowLightBoostEnabled,
                focusMode: focusMode
            )
        )
    }

    private func applyCapabilities(_ capabilities: CSCameraCapabilities, applied: CSCameraAppliedSettings) {
        isSyncingSettings = true

        resolutionOptions = capabilities.resolutionOptions
        fpsOptions = capabilities.fpsOptions
        shutterOptions = capabilities.shutterOptions
        isoOptions = capabilities.isoOptions
        supportsLowLightBoost = capabilities.supportsLowLightBoost
        areCapabilitiesLoaded = true

        selectedResolution = applied.resolution
        selectedFPS = applied.fps

        if selectedNDFilter.stops == 0 {
            selectedShutter = applied.shutter
            selectedISO = applied.iso
        }

        exposureMode = applied.manualControls.exposureMode
        whiteBalanceMode = applied.manualControls.whiteBalanceMode
        whiteBalanceTemperature = applied.manualControls.whiteBalanceTemperature
        whiteBalanceTint = applied.manualControls.whiteBalanceTint
        isHDRAutoAdjustmentEnabled = applied.manualControls.isHDRAutoAdjustmentEnabled
        isLowLightBoostEnabled = applied.manualControls.isLowLightBoostEnabled
        focusMode = applied.manualControls.focusMode

        isSyncingSettings = false
        applyNDSimulation()
    }
}
