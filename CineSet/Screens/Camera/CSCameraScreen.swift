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
            .ignoresSafeArea()

            if viewModel.viewData.derived.ndOverlayOpacity > 0 {
                Color.black
                    .opacity(viewModel.viewData.derived.ndOverlayOpacity)
                    .blendMode(.multiply)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }

            if let focusPoint = viewModel.viewData.chrome.focusIndicatorPoint {
                CSCameraFocusReticle()
                    .position(focusPoint)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.2), value: focusPoint)
            }
            HStack {
                NDFilterSelectorView(
                    filters: NDFilter.presets,
                    selectedFilter: viewModel.settingBinding(\.user.ndFilter, send: CSCameraSettingsChange.ndFilter)
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

            if viewModel.viewData.chrome.authorization == .denied {
                cameraAccessDeniedOverlay
            }
        }
        .task {
            await viewModel.prepareCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .sheet(isPresented: viewModel.settingsSheetPresented) {
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

                Text(viewModel.labels.error.cameraAccessTitle)
                    .font(.title3.bold())

                Text(viewModel.labels.error.cameraAccessBody)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(viewModel.labels.error.openSettings) {
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
            .disabled(viewModel.viewData.chrome.authorization != .authorized)
        }
    }

    private var bottomInfoPanel: some View {
        HStack {
            settingItem(title: viewModel.labels.hud.nd, value: viewModel.viewData.user.ndFilter.hudTitle)
            settingItem(title: viewModel.labels.hud.resolution, value: viewModel.viewData.user.resolution.title)
            settingItem(title: viewModel.labels.hud.fps, value: "\(viewModel.viewData.user.fps)")
            settingItem(
                title: viewModel.labels.hud.shutter,
                value: viewModel.labels.withArguments(
                    keyPath: \.hud.shutterValueFormat,
                    viewModel.viewData.user.shutter
                )
            )
            settingItem(title: viewModel.labels.hud.iso, value: "\(Int(viewModel.viewData.user.iso))")
        }
        .padding()
        .background(.black.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .opacity(viewModel.viewData.chrome.authorization == .authorized ? 1 : 0)
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
