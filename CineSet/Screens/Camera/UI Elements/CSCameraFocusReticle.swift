//
//  CSCameraFocusReticle.swift
//  CineSet
//
//  Created by edgar kosyan on 10/06/2026.
//

import SwiftUI

struct CSCameraFocusReticle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(Color.yellow, lineWidth: 1.5)
            .frame(width: 72, height: 72)
            .shadow(color: .black.opacity(0.4), radius: 2)
    }
}
