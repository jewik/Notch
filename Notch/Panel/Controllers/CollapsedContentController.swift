//
//  CollapsedContentController.swift
//  Notch
//
//  Created by Usanin Ivan on 08.08.2026.
//

import SwiftUI

@MainActor
final class CollapsedContentController {

    private let panelState: PanelState
    
    init(panelState: PanelState) {
        self.panelState = panelState
    }

    func setPreset(_ preset: CollapsedPanelPresets) {
        withAnimation (.smooth(duration: 0.5)) {
            self.panelState.collapsedPreset = preset
        }
    }
}
