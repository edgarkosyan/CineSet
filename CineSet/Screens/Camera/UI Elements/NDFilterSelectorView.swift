//
//  NDFilterSelectorView.swift
//  CineSet
//
//  Created by edgar kosyan on 12/06/2026.
//

import SwiftUI
import UIKit

struct WheelPickerRow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    private let rowHeight: CGFloat = 44

    var body: some View {
        content()
            .frame(maxWidth: .infinity)
            .frame(height: rowHeight)
            .scrollTransition(.interactive, axis: .vertical) { content, phase in
                content
                    .scaleEffect(phase.isIdentity ? 1.0 : 0.82)
                    .opacity(phase.isIdentity ? 1.0 : 0.55)
            }
    }
}

struct NDFilterSelectorView: View {
    let filters: [NDFilter]
    @Binding var selectedFilter: NDFilter

    @State private var centeredID: NDFilter.ID?

    private let rowHeight: CGFloat = 44
    private let spacing: CGFloat = 8
    private let visibleRows: CGFloat = 5
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    private var viewportHeight: CGFloat {
        rowHeight * visibleRows + spacing * (visibleRows - 1)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: spacing) {
                ForEach(filters) { filter in
                    WheelPickerRow {
                        Text(filter.title)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .frame(height: 40)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.orange.opacity(0.6))
                            }
                    }
                    .id(filter.id)
                }
            }
            .scrollTargetLayout()
        }
        .frame(width: 64, height: viewportHeight)
        .contentMargins(.vertical, (viewportHeight - rowHeight) / 2, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $centeredID, anchor: .center)
        .onAppear {
            centeredID = selectedFilter.id
            haptic.prepare()
        }
        .onChange(of: centeredID) { old, new in
            guard new != old, new != nil else { return }
            haptic.impactOccurred()
            haptic.prepare()
        }
        .onScrollPhaseChange { _, phase in
            guard phase == .idle,
                  let id = centeredID,
                  let filter = filters.first(where: { $0.id == id })
            else { return }
            selectedFilter = filter
        }
        .onChange(of: selectedFilter) { _, newFilter in
            if centeredID != newFilter.id {
                centeredID = newFilter.id
            }
        }
    }
}

#Preview {
    @Previewable @State var selected = NDFilter.clear

    ZStack {
        Color.gray
        NDFilterSelectorView(
            filters: NDFilter.presets,
            selectedFilter: $selected
        )
    }
}
