import Foundation
import Observation

@Observable
final class AudioDeviceViewModel {
    // Списки для UI
    private(set) var activeDevices: [AudioDevice] = []
    private(set) var rememberedBluetoothDevices: [BluetoothDevice] = []
    private(set) var activeDeviceID: UInt32 = 0
    private(set) var isConnectingBluetooth: Bool = false
    
    private let audioService: AudioDeviceServiceProtocol
    private let bluetoothService: BluetoothDeviceServiceProtocol
    private var bluetoothDevicesObserver: NSObjectProtocol?
    
    init(audioService: AudioDeviceServiceProtocol, bluetoothService: BluetoothDeviceServiceProtocol) {
        self.audioService = audioService
        self.bluetoothService = bluetoothService
        
        setupBindings()
        refreshAll()
    }
    
    func selectActiveDevice(_ device: AudioDevice) {
        audioService.setAsDefaultOutputDevice(device.id)
    }
    
    func connectBluetoothDevice(_ device: BluetoothDevice) {
        isConnectingBluetooth = true
        bluetoothService.connectDevice(device) { [weak self] success in
            self?.isConnectingBluetooth = false
            // При успехе CoreAudio сам стриггерит обновление через листенеры,
            // но мы можем обновить списки вручную для мгновенной реакции
            self?.refreshAll()
        }
    }
    
    func refreshAll() {
        // 1. Получаем активные девайсы из CoreAudio
        self.activeDevices = audioService.fetchAvailableOutputDevices()
        self.activeDeviceID = audioService.fetchActiveOutputDeviceID()
        
        // 2. Получаем все сопряженные BT устройства
        let allBluetooth = bluetoothService.fetchRememberedAudioDevices()
        
        // 3. Фильтруем: оставляем в списке "Запомненные" только ТЕ, которые сейчас отключены
        self.rememberedBluetoothDevices = allBluetooth.filter { !$0.isConnected }
    }
    
    private func setupBindings() {
        // Слушатель изменений в CoreAudio (проводные, встроенные, а также ПОДКЛЮЧЕННЫЕ Bluetooth/AirPlay)
        audioService.onDevicesChanged = { [weak self] _ in
            self?.refreshAll()
        }
        
        audioService.onActiveDeviceChanged = { [weak self] newActiveID in
            self?.activeDeviceID = newActiveID
        }
        
        // NotificationCenter позволяет нескольким feature/view model независимо
        // слушать общий Bluetooth-сервис, не перезаписывая callback друг друга.
        bluetoothDevicesObserver = NotificationCenter.default.addObserver(
            forName: .bluetoothDevicesDidChange,
            object: bluetoothService,
            queue: .main
        ) { [weak self] _ in
            self?.refreshAll()
        }
        
        audioService.startListening()
    }

    deinit {
        if let bluetoothDevicesObserver {
            NotificationCenter.default.removeObserver(bluetoothDevicesObserver)
        }
        audioService.stopListening()
    }
}
