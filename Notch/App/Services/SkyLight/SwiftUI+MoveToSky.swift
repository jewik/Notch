//
//  SwiftUI+MoveToSky.swift
//  SkyLightWindow
//
//  Created by 秋星桥 on 5/23/25.
//

import AppKit
#if OpenSwiftUI
import OpenSwiftUI
#else
import SwiftUI
#endif

public extension View {
    /// Places the containing window on the lock-screen Space.
    func moveToSky() -> some View {
        modifier(SkyLightWindowModifier(destination: .lockScreen))
    }

    /// Adds the containing window to a stationary overlay Space.
    func addToPinnedSpace() -> some View {
        modifier(SkyLightWindowModifier(destination: .pinned))
    }
}

private struct SkyLightWindowModifier: ViewModifier {
    let destination: SkyLightSpace.Destination

    @State private var window: NSWindow?
    @State private var movedWindowNumber: Int?

    func body(content: Content) -> some View {
        content
            .background(WindowReadingView($window))
            .onChange(of: window) {
                moveWindowIfNeeded()
            }
    }

    private func moveWindowIfNeeded() {
        guard let window,
              movedWindowNumber != window.windowNumber else {
            return
        }

        SkyLightSpace.shared.add(window, to: destination)
        movedWindowNumber = window.windowNumber
    }
}
