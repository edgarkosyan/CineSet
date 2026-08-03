//
//  CSCameraVideoAccessService.swift
//  CineSet
//
//  Created by edgar kosyan on 03/08/2026.
//

import AVFoundation
import Foundation

protocol CSCameraVideoAccessServicing: Sendable {
    func resolveVideoAccess() async -> CSCameraAuthorizationState
}

struct CSCameraVideoAccessService: CSCameraVideoAccessServicing {
    func resolveVideoAccess() async -> CSCameraAuthorizationState {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video) ? .authorized : .denied
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }
}

#if DEBUG
struct PreviewCameraVideoAccess: CSCameraVideoAccessServicing {
    var authorization: CSCameraAuthorizationState = .authorized

    func resolveVideoAccess() async -> CSCameraAuthorizationState {
        authorization
    }
}
#endif
