//
//  CSAppSettingsService.swift
//  CineSet
//
//  Created by edgar kosyan on 20/06/2026.
//

import Foundation

final class CSAppSettingsService: CSAppSettingsStoring {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func value<T: Codable>(for key: CSAppSettingsKey) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    func setValue<T: Codable>(_ value: T?, for key: CSAppSettingsKey) {
        guard let value else {
            defaults.removeObject(forKey: key.rawValue)
            return
        }

        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key.rawValue)
    }
}
