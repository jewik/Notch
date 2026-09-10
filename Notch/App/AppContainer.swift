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
    
//    let systemKeyMonitor: SystemKeyMonitorService

    
    init() {
        
        self.panelState = PanelState()

        self.panelController = PanelController(panelState: self.panelState)
        
        self.fastFolderStore = FastFolderStore()

        self.audioService = AudioDeviceService()
        self.bluetoothService = BluetoothDeviceService()
        
        self.audioViewModel = AudioDeviceViewModel(
            audioService: self.audioService,
            bluetoothService: self.bluetoothService
        )
        
//        self.systemKeyMonitor = SystemKeyMonitorService()
        
        print("container init")
    }
}
