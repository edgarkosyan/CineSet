//
//  CSCameraSettingsSheet.swift
//  CineSet
//
//  Created by edgar kosyan on 10/06/2026.
//

import SwiftUI

struct CSCameraSettingsSheet: View {
    @ObservedObject var viewModel: CSCameraViewModel

    var body: some View {
        NavigationStack {
            Form {
                if viewModel.areCapabilitiesLoaded {
                    videoSection
                    exposureSection
                    whiteBalanceSection
                    processingSection
                    focusSection
                } else {
                    Section {
                        ProgressView("Reading camera capabilities…")
                    }
                }
            }
            .navigationTitle("Camera Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var videoSection: some View {
        Group {
            Section("Resolution") {
                Picker("Resolution", selection: $viewModel.selectedResolution) {
                    ForEach(viewModel.resolutionOptions) { resolution in
                        Text(resolution.title)
                            .tag(resolution)
                    }
                }
            }

            Section("Frame Rate") {
                Picker("FPS", selection: $viewModel.selectedFPS) {
                    ForEach(viewModel.fpsOptions, id: \.self) { fps in
                        Text("\(fps) fps")
                            .tag(fps)
                    }
                }
            }
        }
    }

    private var exposureSection: some View {
        Section {
            Picker("Target Shutter", selection: $viewModel.selectedShutter) {
                ForEach(viewModel.shutterOptions, id: \.self) { shutter in
                    Text("1/\(shutter)")
                        .tag(shutter)
                }
            }

            Picker("Target ISO", selection: $viewModel.selectedISO) {
                ForEach(viewModel.isoOptions, id: \.self) { iso in
                    Text("\(Int(iso))")
                        .tag(iso)
                }
            }
        } header: {
            Text("Target Exposure")
        } footer: {
            if viewModel.areCapabilitiesLoaded {
                Text(
                    "Metered: 1/\(viewModel.sceneMeteredShutter) · ISO \(Int(viewModel.sceneMeteredISO)). " +
                    "Required ND: \(formattedStops(viewModel.requiredNDStops)) stops. " +
                    viewModel.ndMatchStatusText + "."
                )
            }
        }
    }

    private func formattedStops(_ stops: Float) -> String {
        abs(stops.rounded() - stops) < 0.05
            ? String(format: "%.0f", stops)
            : String(format: "%.1f", stops)
    }

    private var whiteBalanceSection: some View {
        Section("White Balance") {
            Picker("Mode", selection: $viewModel.whiteBalanceMode) {
                ForEach(CSCameraControlMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.isWhiteBalanceManual {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Temperature: \(Int(viewModel.whiteBalanceTemperature))K")
                        .font(.subheadline)
                    Slider(
                        value: $viewModel.whiteBalanceTemperature,
                        in: CSCameraManualControls.temperatureRange,
                        step: 100
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tint: \(Int(viewModel.whiteBalanceTint))")
                        .font(.subheadline)
                    Slider(
                        value: $viewModel.whiteBalanceTint,
                        in: CSCameraManualControls.tintRange,
                        step: 1
                    )
                }
            } else {
                Text("Color temperature adapts to the scene.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var processingSection: some View {
        Section("Image Processing") {
            Toggle("HDR Auto Adjustment", isOn: $viewModel.isHDRAutoAdjustmentEnabled)

            if viewModel.supportsLowLightBoost {
                Toggle("Low Light Boost", isOn: $viewModel.isLowLightBoostEnabled)
            }
        }
    }

    private var focusSection: some View {
        Section("Focus") {
            Picker("Mode", selection: $viewModel.focusMode) {
                ForEach(CSCameraControlMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

#Preview {
    CSCameraSettingsSheet(viewModel: AppContainer.previewCameraViewModel())
}
