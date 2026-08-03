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
            updateExposurePlan()
        }
    }

    @Published var selectedShutter: Int = 50 {
        didSet { updateExposurePlan() }
    }

    @Published var selectedISO: Float = 100 {
        didSet { updateExposurePlan() }
    }

    @Published var selectedNDFilter: NDFilter = .clear {
        didSet { updateExposurePlan() }
    }

    @Published private(set) var sceneMeteredShutter: Int = 50
    @Published private(set) var sceneMeteredISO: Float = 100
    @Published private(set) var requiredNDStops: Float = 0
    @Published private(set) var ndMatchState: NDMatchState = .notRequired
    @Published private(set) var exposurePlan: NDExposurePlan?

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
    @Published var isSettingsPresented = false

    let cameraService: CSCameraVideoSessionServicing

    private let router: CSNavigationRouting
    private var isSyncingSettings = false
    private var focusIndicatorTask: Task<Void, Never>?
    private var meteringTask: Task<Void, Never>?

    init(
        cameraService: CSCameraVideoSessionServicing,
        router: CSNavigationRouting
    ) {
        self.cameraService = cameraService
        self.router = router
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
        stopMeteringUpdates()
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

    func didTapClose() {
        router.dismissPresentedRoute()
    }

    func didTapCameraSettings() {
        isSettingsPresented = true
    }

    var setupSnapshot: CineSetSetup {
        CineSetSetup(
            ndFilterTitle: selectedNDFilter.title,
            fps: selectedFPS,
            shutter: selectedShutter,
            iso: selectedISO
        )
    }

    func applySetup(_ setup: CineSetSetup) {
        isSyncingSettings = true
        if let filter = setup.ndFilter {
            selectedNDFilter = filter
        }
        selectedFPS = setup.fps
        selectedShutter = setup.shutter
        selectedISO = setup.iso
        isSyncingSettings = false
        updateExposurePlan()
    }

    var ndFilterDisplayValue: String {
        let selected = selectedNDFilter.hudTitle
        guard areCapabilitiesLoaded else { return selected }

        switch ndMatchState {
        case .notRequired:
            return selected
        case .insufficient(let missingStops):
            return "\(selected) (-\(formattedNDStops(missingStops)))"
        case .matched:
            return "\(selected) ✓"
        case .stronger(let extraStops):
            return "\(selected) (+\(formattedNDStops(extraStops)))"
        }
    }

    var ndMatchStatusText: String {
        guard areCapabilitiesLoaded else { return "Reading scene…" }

        switch ndMatchState {
        case .notRequired:
            return "No ND required"
        case .insufficient(let missingStops):
            return "Short \(formattedNDStops(missingStops)) stops · need \(formattedNDStops(requiredNDStops))"
        case .matched:
            return "Matched · need \(formattedNDStops(requiredNDStops))"
        case .stronger(let extraStops):
            return "+\(formattedNDStops(extraStops)) stops headroom"
        }
    }

    /// Subtle cosmetic preview shift from residual ND stops (required − selected).
    var ndPreviewBrightness: Double {
        guard let exposurePlan else { return 0 }
        return NDExposurePlanner.previewBrightnessAdjustment(
            requiredNDStops: exposurePlan.requiredNDStops,
            selectedNDStops: exposurePlan.selectedNDStops
        )
    }

    private func formattedNDStops(_ stops: Float) -> String {
        abs(stops.rounded() - stops) < 0.05
            ? String(format: "%.0f", stops)
            : String(format: "%.1f", stops)
    }

    private func updateExposurePlan() {
        guard areCapabilitiesLoaded else { return }

        let plan = NDExposurePlanner.plan(
            meteredShutter: sceneMeteredShutter,
            meteredISO: sceneMeteredISO,
            targetShutter: selectedShutter,
            targetISO: selectedISO,
            selectedNDStops: selectedNDFilter.stops
        )

        exposurePlan = plan
        requiredNDStops = plan.requiredNDStops
        ndMatchState = plan.matchState
    }

    private func refreshMeteredExposure() {
        cameraService.readMeteredExposure { [weak self] shutter, iso in
            guard let self else { return }
            guard shutter > 0, iso.isFinite, iso > 0 else { return }

            let shutterChanged = shutter != sceneMeteredShutter
            let isoChanged = abs(iso - sceneMeteredISO) > 0.5
            guard shutterChanged || isoChanged else { return }

            sceneMeteredShutter = shutter
            sceneMeteredISO = iso
            updateExposurePlan()
        }
    }

    private func startMeteringUpdates() {
        stopMeteringUpdates()
        meteringTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.refreshMeteredExposure()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private func stopMeteringUpdates() {
        meteringTask?.cancel()
        meteringTask = nil
    }

    private func applyManualControls() {
        guard !isSyncingSettings else { return }
        cameraService.updateManualControls(currentSettings)
    }

    /// Preview always uses auto exposure. Target shutter/ISO and ND are planning values only.
    private var currentSettings: CSCameraAppliedSettings {
        CSCameraAppliedSettings(
            resolution: selectedResolution,
            fps: selectedFPS,
            shutter: sceneMeteredShutter,
            iso: sceneMeteredISO,
            manualControls: CSCameraManualControls(
                exposureMode: .auto,
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
        sceneMeteredShutter = applied.shutter
        sceneMeteredISO = applied.iso

        whiteBalanceMode = applied.manualControls.whiteBalanceMode
        whiteBalanceTemperature = applied.manualControls.whiteBalanceTemperature
        whiteBalanceTint = applied.manualControls.whiteBalanceTint
        isHDRAutoAdjustmentEnabled = applied.manualControls.isHDRAutoAdjustmentEnabled
        isLowLightBoostEnabled = applied.manualControls.isLowLightBoostEnabled
        focusMode = applied.manualControls.focusMode

        isSyncingSettings = false

        applyManualControls()
        updateExposurePlan()
        startMeteringUpdates()
        refreshMeteredExposure()
    }
}
