//
//  CSRouter.swift
//  CineSet
//
//  Created by edgar kosyan on 20/06/2026.
//

import SwiftUI

@Observable
final class CSRouter {
    var path = NavigationPath()
    var sheet: CSRoute?
    var fullScreenCover: CSRoute?

    func navigate(to route: CSRoute, style: CSNavigationStyle, animated: Bool = true) {
        let action = {
            switch style {
            case .push:
                self.sheet = nil
                self.fullScreenCover = nil
                self.path.append(route)
            case .sheet:
                self.fullScreenCover = nil
                self.sheet = route
            case .fullScreenCover:
                self.sheet = nil
                self.fullScreenCover = route
            }
        }

        if animated {
            action()
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction, action)
        }
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func dismiss() {
        sheet = nil
        fullScreenCover = nil
    }

    var canPop: Bool {
        !path.isEmpty
    }
}
