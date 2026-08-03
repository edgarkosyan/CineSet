//
//  CSCameraViewModel+SwiftUI.swift
//  CineSet
//
//  Created by edgar kosyan on 03/08/2026.
//

import SwiftUI

extension CSCameraViewModel {
    var settingsSheetPresented: Binding<Bool> {
        Binding(
            get: { self.viewData.chrome.isSettingsPresented },
            set: { self.setSettingsPresented($0) }
        )
    }

    func settingBinding<Value>(
        _ keyPath: KeyPath<CSCameraViewData, Value>,
        send change: @escaping (Value) -> CSCameraSettingsChange
    ) -> Binding<Value> {
        Binding(
            get: { self.viewData[keyPath: keyPath] },
            set: { self.send(change($0)) }
        )
    }
}
