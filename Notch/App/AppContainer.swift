//
//  AppContainer.swift
//  UITests
//
//  Created by Usanin Ivan on 04.08.2026.
//

import Observation

@Observable
@MainActor
final class AppContainer {
    let panelState: PanelState
    let expandedContentController: ExpandedContentController
    let collapsedContentController: CollapsedContentController
    
    
    init() {
        let panelState = PanelState()
        
        self.panelState = panelState
        self.expandedContentController = ExpandedContentController(panelState: panelState)
        self.collapsedContentController = CollapsedContentController(panelState: panelState)
    }
}
