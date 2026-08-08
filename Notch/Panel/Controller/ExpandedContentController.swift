//
//  PanelController.swift
//  UITests
//
//  Created by Usanin Ivan on 04.08.2026.
//


import SwiftUI


@MainActor
final class ExpandedContentController {

    private let panelState: PanelState
    
    init(panelState: PanelState) {
        self.panelState = panelState
    }

    func setPreset(_ preset: ExpandedPanelPresets) {
        withAnimation {
            self.panelState.expandedPreset = preset
        }
    }
}
