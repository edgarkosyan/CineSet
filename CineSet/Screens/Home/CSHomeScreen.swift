//
//  CSHomeScreen.swift
//  CineSet
//
//  Created by edgar kosyan on 20/06/2026.
//

import SwiftUI

struct CSHomeScreen: View {
    @StateObject private var viewModel: CSHomeViewModel

    init(viewModel: CSHomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerView

                    startCameraCard

                    lastSetupCard

                    presetsSection

                    toolsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("CineSet")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.primaryText)

                Text("Exposure tools for camera creators")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()

            Button {
                viewModel.didTapSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(Color.primaryText)
                    .frame(width: 44, height: 44)
                    .background(Color.card)
                    .clipShape(Circle())
            }
        }
    }

    private var startCameraCard: some View {
        Button {
            viewModel.didTapStartCamera()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Color.accent)

                Text("Start Camera")
                    .font(.title2.bold())
                    .foregroundStyle(Color.primaryText)

                Text("ND · Shutter · ISO · FPS")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .background(cardBackground(cornerRadius: 28))
        }
        .buttonStyle(.plain)
    }

    private var lastSetupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Last Setup")

            HStack {
                settingBlock(title: "ND", value: "32")
                settingBlock(title: "FPS", value: "24")
                settingBlock(title: "Shutter", value: "1/50")
                settingBlock(title: "ISO", value: "100")
            }
            .padding(16)
            .background(cardBackground(cornerRadius: 20))
        }
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Presets")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    presetCard(title: "Daylight", nd: "ND 64", settings: "24 FPS · 1/50")
                    presetCard(title: "Golden Hour", nd: "ND 16", settings: "24 FPS · 1/50")
                    presetCard(title: "Indoor", nd: "ND 8", settings: "30 FPS · 1/60")
                }
            }
        }
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Tools")

            VStack(spacing: 10) {
                toolRow(title: "Find ND Filter", icon: "circle.grid.2x2")
                toolRow(title: "Camera Profiles", icon: "camera.aperture")
                toolRow(title: "Settings", icon: "slider.horizontal.3") {
                    viewModel.didTapSettings()
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color.primaryText)
    }

    private func settingBlock(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)

            Text(value)
                .font(.headline.bold())
                .foregroundStyle(Color.primaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func presetCard(title: String, nd: String, settings: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            Text(nd)
                .font(.title3.bold())
                .foregroundStyle(Color.accent)

            Text(settings)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
        }
        .padding(16)
        .frame(width: 150, height: 120, alignment: .topLeading)
        .background(cardBackground(cornerRadius: 20))
    }

    private func toolRow(title: String, icon: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundStyle(Color.accent)
                    .frame(width: 28)

                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color.secondaryText)
            }
            .padding(16)
            .background(cardBackground(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func cardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.card)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.cardBorder, lineWidth: 1)
            }
    }
}

#Preview {
    CSHomeScreen(viewModel: AppContainer().makeHomeViewModel())
}
