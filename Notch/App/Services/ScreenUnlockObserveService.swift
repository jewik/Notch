//
//  ScreenUnlockObserveService.swift
//  Notch
//
//  Created by Usanin Ivan on 20.10.2026.
//

import Cocoa
import os

class ScreenUnlockObserveService: NSObject {
    
    static let shared = ScreenUnlockObserveService()
        
        // This initializer runs immediately when ScreenUnlockObserveService.shared is called
        override private init() {
            super.init()

        }

    
    func setupWorkspaceObservers() {
        let nc = NSWorkspace.shared.notificationCenter
        
        // 1. Detect when the Mac wakes up from sleep
        nc.addObserver(self,
                       selector: #selector(handleWakeUp),
                       name: NSWorkspace.didWakeNotification,
                       object: nil)
        
//        // 2. Detect when Fast User Switching switches back to this desktop
//        nc.addObserver(self,
//                       selector: #selector(handleWorkspaceActive),
//                       name: NSWorkspace.sessionDidBecomeActiveNotification,
//                       object: nil)
        
        // 3. Detect when the screen is explicitly unlocked
        DistributedNotificationCenter.default().addObserver(self,
                       selector: #selector(handleUnlock),
                       name: NSNotification.Name("com.apple.screenIsUnlocked"),
                       object: nil)
        
        Log.service.info("ScreenUnlockObserveService: setupWorkspaceObservers called")
    }
    
    @objc func handleUnlock(notification: Notification) {
        // Ensure UI updates happen on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.triggerGreetingAnimation()
        }
    }
    
    @objc func handleWakeUp(notification: Notification) {}
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    func triggerGreetingAnimation(){
        Log.service.info("Screen unlock event received")
        PanelNotificationsService.shared.post(AppleHelloNotificationView())
    }
}
