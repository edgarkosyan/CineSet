//
//  CSCameraSettingsEngine.swift
//  CineSet
//
//  Created by edgar kosyan on 03/08/2026.
//

import Foundation

enum CSCameraSettingsChange: Equatable {
    case resolution(CSCameraResolution)
    case fps(Int)
    case ndFilter(NDFilter)
    case shutter(Int)
    case iso(Float)
    case exposureMode(CSCameraControlMode)
    case whiteBalanceMode(CSCameraControlMode)
    case whiteBalanceTemperature(Float)
    case whiteBalanceTint(Float)
    case isHDRAutoAdjustmentEnabled(Bool)
    case isLowLightBoostEnabled(Bool)
    case focusMode(CSCameraControlMode)
}

enum CSCameraSideEffect: Equatable {
    case updateResolution
    case updateFPS
    case updateManualControls
}

struct CSCameraSettingsEngine {
    func applying(
        _ change: CSCameraSettingsChange,
        to viewData: inout CSCameraViewData
    ) -> [CSCameraSideEffect] {
        switch change {
        case .resolution(let value):
            viewData.user.resolution = value
            return [.updateResolution]

        case .fps(let value):
            viewData.user.fps = value
            return [.updateFPS]

        case .ndFilter(let value):
            viewData.user.ndFilter = value
            refreshDerivedExposure(in: &viewData)
            return [.updateManualControls]

        case .shutter(let value):
            viewData.user.shutter = value
            refreshDerivedExposure(in: &viewData)
            return [.updateManualControls]

        case .iso(let value):
            viewData.user.iso = value
            refreshDerivedExposure(in: &viewData)
            return [.updateManualControls]

        case .exposureMode(let value):
            viewData.user.manualControls.exposureMode = value
            return [.updateManualControls]

        case .whiteBalanceMode(let value):
            viewData.user.manualControls.whiteBalanceMode = value
            return [.updateManualControls]

        case .whiteBalanceTemperature(let value):
            viewData.user.manualControls.whiteBalanceTemperature = value
            return [.updateManualControls]

        case .whiteBalanceTint(let value):
            viewData.user.manualControls.whiteBalanceTint = value
            return [.updateManualControls]

        case .isHDRAutoAdjustmentEnabled(let value):
            viewData.user.manualControls.isHDRAutoAdjustmentEnabled = value
            return [.updateManualControls]

        case .isLowLightBoostEnabled(let value):
            viewData.user.manualControls.isLowLightBoostEnabled = value
            return [.updateManualControls]

        case .focusMode(let value):
            viewData.user.manualControls.focusMode = value
            return [.updateManualControls]
        }
    }

    func applyingCapabilities(
        _ capabilities: CSCameraCapabilities,
        applied: CSCameraAppliedSettings,
        to viewData: inout CSCameraViewData
    ) {
        viewData.capabilities = CSCameraCapabilitiesViewData(
            capabilities: capabilities,
            isLoaded: true
        )

        viewData.user.resolution = applied.resolution
        viewData.user.fps = applied.fps

        if viewData.user.ndFilter.stops == 0 {
            viewData.user.shutter = applied.shutter
            viewData.user.iso = applied.iso
        }

        viewData.user.manualControls = applied.manualControls
        refreshDerivedExposure(in: &viewData)
    }

    func appliedSettings(from viewData: CSCameraViewData) -> CSCameraAppliedSettings {
        CSCameraAppliedSettings(
            resolution: viewData.user.resolution,
            fps: viewData.user.fps,
            shutter: viewData.derived.appliedShutter,
            iso: viewData.derived.appliedISO,
            manualControls: viewData.user.manualControls
        )
    }

    private func refreshDerivedExposure(in viewData: inout CSCameraViewData) {
        let result = NDExposureSimulator.simulate(
            baseShutter: viewData.user.shutter,
            baseISO: viewData.user.iso,
            ndStops: viewData.user.ndFilter.stops,
            shutterOptions: viewData.capabilities.shutterOptions,
            isoOptions: viewData.capabilities.isoOptions
        )

        viewData.derived.appliedShutter = result.appliedShutter
        viewData.derived.appliedISO = result.appliedISO
        viewData.derived.ndOverlayOpacity = result.overlayOpacity
    }
}
