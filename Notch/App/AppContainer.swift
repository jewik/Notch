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
    
    let panelController: PanelController
    let notificationController: NotificationController

    let fastFolderStore: FastFolderStore
    
    init() {
        let panelState = PanelState()
        self.panelState = panelState

        self.panelController = PanelController(panelState: panelState)
        self.notificationController = NotificationController(panelState: panelState)
        
        self.fastFolderStore = FastFolderStore()
    }
}
