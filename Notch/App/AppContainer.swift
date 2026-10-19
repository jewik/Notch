//
//  AppContainer.swift
//  UITests
//
//  Created by Usanin Ivan on 04.08.2026.
//

import os
import Observation

@MainActor
final class AppContainer {
    
    static let shared = AppContainer()
    
    let panelState: PanelState
    
    let controller: PanelController
    
    let fastFolderStore: FastFolderStore
    
    let audioService: AudioDeviceServiceProtocol
    
    let audioViewModel: AudioDeviceViewModel
    
    let bluetoothService: BluetoothDeviceServiceProtocol
    let bluetoothNotificationsService: BluetoothNotificationService
    
    let HUDViewmodel: HUDViewModel
    
    
    init() {
        
        let panelState = PanelState()
        
        self.panelState = panelState
        
        self.controller = PanelController(
            panelState: panelState
        )
        
        self.fastFolderStore = FastFolderStore()
        
        self.audioService = AudioDeviceService()
        self.bluetoothService = BluetoothDeviceService.shared
        self.bluetoothNotificationsService = BluetoothNotificationService()
        
        self.audioViewModel = AudioDeviceViewModel(
            audioService: self.audioService,
            bluetoothService: self.bluetoothService
        )
        
        self.HUDViewmodel = HUDViewModel()
        
        Log.general.info("AppContainer init.")
        
    }
    
}
