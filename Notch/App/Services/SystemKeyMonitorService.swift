

import Cocoa
import ApplicationServices

final class SystemKeyMonitorService {
    
    
    func setupEventTap() {
        // 14 — это числовое значение (Raw Value) для событий NX_SYSDEFINED (медиа-клавиши)
        let sysDefinedRawValue = 14
        let eventMask = (1 << sysDefinedRawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask), // передаем маску с флагом 14
            callback: myEventTapCallback,
            userInfo: nil
        ) else {
            print("Ошибка: Требуются права Accessibility (Специальные возможности)!")
            return
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    // Колбэк, который проверяет нажатые клавиши
    let myEventTapCallback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
        // Проверяем тип события по его числовому идентификатору (14 = System Defined)
        if type.rawValue == 14 { // 14 = NX_SYSDEFINED (Системные медиа-клавиши)
            let nsEvent = NSEvent(cgEvent: event)
            
            if nsEvent?.subtype.rawValue == 8 { // Subtype 8 = Auxiliary keys
                let data = nsEvent?.data1 ?? 0
                let keyCode = (data & 0xFFFF0000) >> 16
                let keyState = ((data & 0xFF00) >> 8)
                let isKeyDown = keyState == 0x0A // 0x0A - Нажатие кнопки
                
                if isKeyDown {
                    switch keyCode {
                    case 0: // NX_KEYTYPE_SOUND_UP
                        print("Нажата кнопка: Громкость ВВЕРХ")
                        //                            adjustVolume(by: 0.0625)
                        SystemControlService.shared.adjustVolume(by: 0.0625)
                        return nil // Блокируем системный HUD громкости
                        
                    case 1: // NX_KEYTYPE_SOUND_DOWN
                        print("Нажата кнопка: Громкость ВНИЗ")
                        //                            adjustVolume(by: -0.0625)
                        SystemControlService.shared.adjustVolume(by: -0.0625)
                        return nil // Блокируем системный HUD громкости
                        
                    case 2: // NX_KEYTYPE_BRIGHTNESS_UP
                        print("Нажата кнопка: Яркость ВВЕРХ")
                        //                            adjustBrightness(by: 0.0625)
                        return nil // Блокируем системный HUD яркости
                        //
                        //                        case 3: // NX_KEYTYPE_BRIGHTNESS_DOWN
                        //                            print("Нажата кнопка: Яркость ВНИЗ")
                        ////                            adjustBrightness(by: -0.0625)
                        //                            return nil // Блокируем системный HUD яркости
                        //
                        //                        case 7: // NX_KEYTYPE_MUTE
                        //                            print("Нажата кнопка: MUTE")
                        ////                            toggleMute()
                        //                            return nil // Блокируем системный HUD мьюта
                        
                    default:
                        break
                    }
                }
            }
        }
            
            let key = Unmanaged.passRetained(event)
            print("key pressed", key)
            return key
        
        
    }
}
