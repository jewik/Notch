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
    
    static let shared = AppContainer()
    
    let panelState: PanelState
    
    let controller: PanelController

    let fastFolderStore: FastFolderStore
    
    let audioService: AudioDeviceServiceProtocol
    let audioViewModel: AudioDeviceViewModel
    
    let bluetoothService: BluetoothDeviceServiceProtocol
    
    let HUDViewmodel: HUDViewModel

    
    init() {
        
        self.panelState = PanelState()

        self.controller = PanelController(panelState: self.panelState)
        
        self.fastFolderStore = FastFolderStore()

        self.audioService = AudioDeviceService()
        self.bluetoothService = BluetoothDeviceService()
        
        self.audioViewModel = AudioDeviceViewModel(
            audioService: self.audioService,
            bluetoothService: self.bluetoothService
        )
        
        self.HUDViewmodel = HUDViewModel()
        
        print("container init")

    }
    
}
