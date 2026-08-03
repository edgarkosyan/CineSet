//
//  CSCameraSettingsSheet.swift
//  CineSet
//
//  Created by edgar kosyan on 10/06/2026.
//

import SwiftUI

struct CSCameraSettingsSheet: View {
    @ObservedObject var viewModel: CSCameraViewModel

    private var capabilities: CSCameraCapabilitiesViewData {
        viewModel.viewData.capabilities
    }

    private var labels: TDCameraLabels {
        viewModel.labels
    }

    var body: some View {
        NavigationStack {
            Form {
                if capabilities.isLoaded {
                    videoSection
                    exposureSection
                    whiteBalanceSection
                    processingSection
                    focusSection
                } else {
                    Section {
                        ProgressView(labels.settings.readingCapabilities)
                    }
                }
            }
            .navigationTitle(labels.settings.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var videoSection: some View {
        Group {
            Section(labels.settings.resolutionSection) {
                Picker(
                    labels.settings.resolutionPicker,
                    selection: viewModel.settingBinding(\.user.resolution, send: CSCameraSettingsChange.resolution)
                ) {
                    ForEach(capabilities.resolutionOptions) { resolution in
                        Text(resolution.title)
                            .tag(resolution)
                    }
                }
            }

            Section(labels.settings.frameRateSection) {
                Picker(labels.settings.fpsPicker, selection: viewModel.settingBinding(\.user.fps, send: CSCameraSettingsChange.fps)) {
                    ForEach(capabilities.fpsOptions, id: \.self) { fps in
                        Text(labels.withArguments(keyPath: \.settings.fpsOptionFormat, fps))
                            .tag(fps)
                    }
                }
            }
        }
    }

    private var exposureSection: some View {
        Section(labels.settings.exposureSection) {
            Picker(
                labels.settings.modePicker,
                selection: viewModel.settingBinding(
                    \.user.manualControls.exposureMode,
                    send: CSCameraSettingsChange.exposureMode
                )
            ) {
                ForEach(CSCameraControlMode.allCases) { mode in
                    Text(labels.controlModeTitle(mode)).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.isExposureManual {
                Picker(
                    labels.settings.shutterPicker,
                    selection: viewModel.settingBinding(\.user.shutter, send: CSCameraSettingsChange.shutter)
                ) {
                    ForEach(capabilities.shutterOptions, id: \.self) { shutter in
                        Text(labels.withArguments(keyPath: \.settings.shutterOptionFormat, shutter))
                            .tag(shutter)
                    }
                }

                Picker(labels.settings.isoPicker, selection: viewModel.settingBinding(\.user.iso, send: CSCameraSettingsChange.iso)) {
                    ForEach(capabilities.isoOptions, id: \.self) { iso in
                        Text("\(Int(iso))")
                            .tag(iso)
                    }
                }
            } else {
                Text(labels.settings.exposureAutoFootnote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var whiteBalanceSection: some View {
        Section(labels.settings.whiteBalanceSection) {
            Picker(
                labels.settings.modePicker,
                selection: viewModel.settingBinding(
                    \.user.manualControls.whiteBalanceMode,
                    send: CSCameraSettingsChange.whiteBalanceMode
                )
            ) {
                ForEach(CSCameraControlMode.allCases) { mode in
                    Text(labels.controlModeTitle(mode)).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.isWhiteBalanceManual {
                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        labels.withArguments(
                            keyPath: \.settings.temperatureFormat,
                            Int(viewModel.viewData.user.manualControls.whiteBalanceTemperature)
                        )
                    )
                    .font(.subheadline)
                    Slider(
                        value: viewModel.settingBinding(
                            \.user.manualControls.whiteBalanceTemperature,
                            send: CSCameraSettingsChange.whiteBalanceTemperature
                        ),
                        in: CSCameraManualControls.temperatureRange,
                        step: 100
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        labels.withArguments(
                            keyPath: \.settings.tintFormat,
                            Int(viewModel.viewData.user.manualControls.whiteBalanceTint)
                        )
                    )
                    .font(.subheadline)
                    Slider(
                        value: viewModel.settingBinding(
                            \.user.manualControls.whiteBalanceTint,
                            send: CSCameraSettingsChange.whiteBalanceTint
                        ),
                        in: CSCameraManualControls.tintRange,
                        step: 1
                    )
                }
            } else {
                Text(labels.settings.whiteBalanceAutoFootnote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var processingSection: some View {
        Section(labels.settings.imageProcessingSection) {
            Toggle(
                labels.settings.hdrAutoAdjustment,
                isOn: viewModel.settingBinding(
                    \.user.manualControls.isHDRAutoAdjustmentEnabled,
                    send: CSCameraSettingsChange.isHDRAutoAdjustmentEnabled
                )
            )

            if capabilities.supportsLowLightBoost {
                Toggle(
                    labels.settings.lowLightBoost,
                    isOn: viewModel.settingBinding(
                        \.user.manualControls.isLowLightBoostEnabled,
                        send: CSCameraSettingsChange.isLowLightBoostEnabled
                    )
                )
            }
        }
    }

    private var focusSection: some View {
        Section(labels.settings.focusSection) {
            Picker(
                labels.settings.modePicker,
                selection: viewModel.settingBinding(
                    \.user.manualControls.focusMode,
                    send: CSCameraSettingsChange.focusMode
                )
            ) {
                ForEach(CSCameraControlMode.allCases) { mode in
                    Text(labels.controlModeTitle(mode)).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

#Preview {
    CSCameraSettingsSheet(viewModel: AppContainer.previewCameraViewModel())
}
