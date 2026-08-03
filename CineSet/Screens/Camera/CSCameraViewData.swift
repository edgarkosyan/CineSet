//
//  CSCameraViewData.swift
//  CineSet
//
//  Created by edgar kosyan on 03/08/2026.
//

import CoreGraphics
import Foundation

enum CSCameraAuthorizationState: Equatable {
    case notDetermined
    case authorized
    case denied
}

struct CSCameraUserSettings: Equatable {
    var resolution: CSCameraResolution = .p1080
    var fps: Int = 25
    var ndFilter: NDFilter = .clear
    var shutter: Int = 50
    var iso: Float = 100
    var manualControls: CSCameraManualControls = CSCameraManualControls()
}

struct CSCameraCapabilitiesViewData: Equatable {
    var resolutionOptions: [CSCameraResolution] = []
    var fpsOptions: [Int] = []
    var shutterOptions: [Int] = []
    var isoOptions: [Float] = []
    var supportsLowLightBoost: Bool = false
    var isLoaded: Bool = false

    init() {}

    init(capabilities: CSCameraCapabilities, isLoaded: Bool) {
        resolutionOptions = capabilities.resolutionOptions
        fpsOptions = capabilities.fpsOptions
        shutterOptions = capabilities.shutterOptions
        isoOptions = capabilities.isoOptions
        supportsLowLightBoost = capabilities.supportsLowLightBoost
        self.isLoaded = isLoaded
    }
}

struct CSCameraDerivedExposure: Equatable {
    var appliedShutter: Int = 50
    var appliedISO: Float = 100
    var ndOverlayOpacity: Double = 0
}

struct CSCameraUIChrome: Equatable {
    var authorization: CSCameraAuthorizationState = .notDetermined
    var isSettingsPresented: Bool = false
    var focusIndicatorPoint: CGPoint?
}

struct CSCameraViewData: Equatable {
    var user: CSCameraUserSettings = CSCameraUserSettings()
    var capabilities: CSCameraCapabilitiesViewData = CSCameraCapabilitiesViewData()
    var derived: CSCameraDerivedExposure = CSCameraDerivedExposure()
    var chrome: CSCameraUIChrome = CSCameraUIChrome()

    static let initial = CSCameraViewData()
}
