//
//  CSSettingsScreen.swift
//  CineSet
//
//  Created by edgar kosyan on 20/06/2026.
//

import SwiftUI

struct CSSettingsScreen: View {
    @StateObject private var viewModel: CSSettingsViewModel

    init(viewModel: CSSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Settings",
                systemImage: "gearshape",
                description: Text("App settings coming soon.")
            )
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.didTapDone()
                    }
                }
            }
        }
    }
}

#Preview {
    CSSettingsScreen(viewModel: AppContainer().makeSettingsViewModel())
}
