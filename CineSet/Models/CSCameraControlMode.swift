//
//  CSCameraControlMode.swift
//  CineSet
//
//  Created by edgar kosyan on 10/06/2026.
//

import Foundation

enum CSCameraControlMode: String, CaseIterable, Identifiable, Sendable {
    case auto
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: "Auto"
        case .manual: "Manual"
        }
    }
}

struct CSCameraManualControls: Sendable, Equatable {
    var exposureMode: CSCameraControlMode = .auto
    var whiteBalanceMode: CSCameraControlMode = .auto
    var whiteBalanceTemperature: Float = 5_500
    var whiteBalanceTint: Float = 0
    var isHDRAutoAdjustmentEnabled: Bool = false
    var isLowLightBoostEnabled: Bool = false
    var focusMode: CSCameraControlMode = .auto

    static let temperatureRange: ClosedRange<Float> = 2_500...8_000
    static let tintRange: ClosedRange<Float> = -50...50
}
