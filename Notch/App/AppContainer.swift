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

    let fastFolderStore: FastFolderStore
    
    let audioService: AudioDeviceServiceProtocol
    let audioViewModel: AudioDeviceViewModel
    
    let bluetoothService: BluetoothDeviceServiceProtocol

    
    init() {
        let panelState = PanelState()
        self.panelState = panelState

        self.panelController = PanelController(panelState: panelState)
        
        self.fastFolderStore = FastFolderStore()
        
        
        let audio = AudioDeviceService()
        let bluetooth = BluetoothDeviceService()

        self.audioService = audio
        self.bluetoothService = bluetooth
        
        self.audioViewModel = AudioDeviceViewModel(
            audioService: audio,
            bluetoothService: bluetooth
        )
        
        print("container init")
    }
}
