//
//  CSCameraPreview.swift
//  CineSet
//
//  Created by edgar kosyan on 10/06/2026.
//

import AVFoundation
import SwiftUI

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    var onFocusTap: ((CGPoint, CGPoint) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onFocusTap: onFocusTap)
    }

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        view.addGestureRecognizer(tap)
        context.coordinator.previewView = view

        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        context.coordinator.onFocusTap = onFocusTap
    }

    final class Coordinator: NSObject {
        var onFocusTap: ((CGPoint, CGPoint) -> Void)?
        weak var previewView: PreviewUIView?

        init(onFocusTap: ((CGPoint, CGPoint) -> Void)?) {
            self.onFocusTap = onFocusTap
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = previewView else { return }

            let viewPoint = gesture.location(in: view)
            let devicePoint = view.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: viewPoint)
            onFocusTap?(viewPoint, devicePoint)
        }
    }
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
