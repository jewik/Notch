//
//  MouseTrackingView.swift
//  UITests
//
//  Created by Usanin Ivan on 03.08.2026.
//

import SwiftUI
import AppKit

struct MouseTrackingView: NSViewRepresentable {
    var onEnter: () -> Void
    var onExit: () -> Void
//    var onClick: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = CustomTrackingNSView()
        view.onEnter = onEnter
        view.onExit = onExit
//        view.onClick = onClick
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// Custom NSView to handle NSTrackingArea
class CustomTrackingNSView: NSView {
    var onEnter: (() -> Void)?
    var onExit: (() -> Void)?
//    var onClick: (() -> Void)?
    private var trackingArea: NSTrackingArea?
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // Remove old tracking area to avoid duplication
        if let existingArea = trackingArea {
            removeTrackingArea(existingArea)
        }
        
        // Create new tracking area matching current view bounds
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeInActiveApp,
            .inVisibleRect
        ]
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: options,
            owner: self,
            userInfo: nil
        )
        
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        onEnter?()
    }

    override func mouseExited(with event: NSEvent) {
        onExit?()
    }
    
//    override func mouseDown(with event: NSEvent) {
//        onClick?()
//    }
}
