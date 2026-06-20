//
//  CSAppSettingsStoring.swift
//  CineSet
//
//  Created by edgar kosyan on 20/06/2026.
//

import Foundation

protocol CSAppSettingsStoring: AnyObject {
    func value<T: Codable>(for key: CSAppSettingsKey) -> T?
    func setValue<T: Codable>(_ value: T?, for key: CSAppSettingsKey)
}

extension CSAppSettingsStoring {
    var lastSetup: CineSetSetup? {
        get { value(for: .lastSetup) }
        set { setValue(newValue, for: .lastSetup) }
    }
}
