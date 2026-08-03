//
//  TDCameraLabels.swift
//  CineSet
//
//  Created by edgar kosyan on 03/08/2026.
//

import Foundation

struct TDCameraLabels {
    struct ErrorLabels {
        var cameraAccessTitle: String
        var cameraAccessBody: String
        var openSettings: String
    }

    struct HudLabels {
        var nd: String
        var resolution: String
        var fps: String
        var shutter: String
        var iso: String
        var shutterValueFormat: String
    }

    struct SettingsLabels {
        var navigationTitle: String
        var readingCapabilities: String
        var resolutionSection: String
        var resolutionPicker: String
        var frameRateSection: String
        var fpsPicker: String
        var fpsOptionFormat: String
        var exposureSection: String
        var modePicker: String
        var shutterPicker: String
        var isoPicker: String
        var shutterOptionFormat: String
        var exposureAutoFootnote: String
        var whiteBalanceSection: String
        var temperatureFormat: String
        var tintFormat: String
        var whiteBalanceAutoFootnote: String
        var imageProcessingSection: String
        var hdrAutoAdjustment: String
        var lowLightBoost: String
        var focusSection: String
    }

    var controlModeAuto: String
    var controlModeManual: String
    var error: ErrorLabels
    var hud: HudLabels
    var settings: SettingsLabels

    func controlModeTitle(_ mode: CSCameraControlMode) -> String {
        switch mode {
        case .auto: controlModeAuto
        case .manual: controlModeManual
        }
    }
}

extension TDCameraLabels: TDLocalizedLabeling {
    static var localized: TDCameraLabels {
        .init(
            controlModeAuto: "Auto",
            controlModeManual: "Manual",
            error: .init(
                cameraAccessTitle: "Camera Access Required",
                cameraAccessBody: "Allow camera access in Settings to use CineSet.",
                openSettings: "Open Settings"
            ),
            hud: .init(
                nd: "ND",
                resolution: "Res",
                fps: "FPS",
                shutter: "Shutter",
                iso: "ISO",
                shutterValueFormat: "1/%d"
            ),
            settings: .init(
                navigationTitle: "Camera Settings",
                readingCapabilities: "Reading camera capabilities…",
                resolutionSection: "Resolution",
                resolutionPicker: "Resolution",
                frameRateSection: "Frame Rate",
                fpsPicker: "FPS",
                fpsOptionFormat: "%d fps",
                exposureSection: "Exposure",
                modePicker: "Mode",
                shutterPicker: "Shutter",
                isoPicker: "ISO",
                shutterOptionFormat: "1/%d",
                exposureAutoFootnote: "Shutter and ISO are controlled automatically.",
                whiteBalanceSection: "White Balance",
                temperatureFormat: "Temperature: %dK",
                tintFormat: "Tint: %d",
                whiteBalanceAutoFootnote: "Color temperature adapts to the scene.",
                imageProcessingSection: "Image Processing",
                hdrAutoAdjustment: "HDR Auto Adjustment",
                lowLightBoost: "Low Light Boost",
                focusSection: "Focus"
            )
        )
    }
}
