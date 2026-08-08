//
//  DragDestinationView.swift
//  UITests
//
//  Created by Usanin Ivan on 03.08.2026.
//

import SwiftUI
import AppKit

struct DragDestinationView: NSViewRepresentable {

    var onEnter: () -> Void
    var onExit: () -> Void
    var onDrop: ([URL]) -> Void

    func makeNSView(context: Context) -> DragDestinationNSView {
        let view = DragDestinationNSView()

        view.onEnter = onEnter
        view.onExit = onExit
        view.onDrop = onDrop

        return view
    }

    func updateNSView(_ nsView: DragDestinationNSView, context: Context) { }
}

final class DragDestinationNSView: NSView {

    var onEnter: (() -> Void)?
    var onExit: (() -> Void)?
    var onDrop: (([URL]) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        onEnter?()
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onExit?()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {

        let pasteboard = sender.draggingPasteboard

        guard let items = pasteboard.readObjects(
            forClasses: [NSURL.self]
        ) as? [URL] else {
            return false
        }

        onDrop?(items)

        return true
    }
}
