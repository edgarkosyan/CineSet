//
//  CSCameraScreen.swift
//  CineSet
//
//  Created by edgar kosyan on 10/06/2026.
//

import SwiftUI

struct CSCameraScreen: View {
    @StateObject private var viewModel: CSCameraViewModel
    @Environment(\.openURL) private var openURL

    init(viewModel: CSCameraViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            CameraPreviewView(
                session: viewModel.cameraService.session,
                onFocusTap: { viewPoint, devicePoint in
                    viewModel.focus(at: viewPoint, devicePoint: devicePoint)
                }
            )
            .brightness(viewModel.ndPreviewBrightness)
            .animation(.easeOut(duration: 0.2), value: viewModel.ndPreviewBrightness)
            .ignoresSafeArea()

            if let focusPoint = viewModel.focusIndicatorPoint {
                CSCameraFocusReticle()
                    .position(focusPoint)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.2), value: focusPoint)
            }
            HStack {
                NDFilterSelectorView(
                    filters: NDFilter.presets,
                    selectedFilter: $viewModel.selectedNDFilter
                )
                .padding(.leading, 16)

                Spacer()
            }

            VStack {
                topBar

                Spacer()
                    .allowsHitTesting(false)

                bottomInfoPanel
                    .allowsHitTesting(false)
            }
            .padding()

            if viewModel.authorizationState == .denied {
                cameraAccessDeniedOverlay
            }
        }
        .task {
            await viewModel.prepareCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .sheet(isPresented: $viewModel.isSettingsPresented) {
            CSCameraSettingsSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var cameraAccessDeniedOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.largeTitle)

                Text("Camera Access Required")
                    .font(.title3.bold())

                Text("Allow camera access in Settings to use CineSet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(32)
            .foregroundStyle(.white)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                viewModel.didTapClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.45))
                    .clipShape(Circle())
            }

            Spacer()

            Button {
                viewModel.didTapCameraSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.45))
                    .clipShape(Circle())
            }
            .disabled(viewModel.authorizationState != .authorized)
        }
    }

    private var bottomInfoPanel: some View {
        VStack(spacing: 8) {
            HStack {
                settingItem(title: "ND", value: viewModel.ndFilterDisplayValue)
                settingItem(title: "Res", value: viewModel.selectedResolution.title)
                settingItem(title: "FPS", value: "\(viewModel.selectedFPS)")
                settingItem(title: "Shutter", value: "1/\(viewModel.selectedShutter)")
                settingItem(title: "ISO", value: "\(Int(viewModel.selectedISO))")
            }

            Text(viewModel.ndMatchStatusText)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.black.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .opacity(viewModel.authorizationState == .authorized ? 1 : 0)
    }

    private func settingItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CSCameraScreen(viewModel: AppContainer.previewCameraViewModel())
}
