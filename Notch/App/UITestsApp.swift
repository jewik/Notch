//
//  UITestsApp.swift
//  UITests
//
//  Created by Usanin Ivan on 02.07.2026.
//

import SwiftUI

@main
struct UITestsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate
    
    @State
        private var panelController = PanelController()

    var body: some Scene {
        // A Settings scene keeps this as a valid SwiftUI app without creating
        // the normal WindowGroup window that macOS app templates usually show.
        Settings {
            EmptyView()
        }
    }
}
