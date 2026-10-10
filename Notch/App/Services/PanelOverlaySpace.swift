import AppKit

/// Keeps the panel outside desktop Spaces so switching desktops does not move it.
///
/// The window must be added before it is shown for the first time. These CGS
/// symbols are private macOS APIs and are resolved dynamically so the app can
/// keep working without this behavior if they are unavailable.
final class PanelOverlaySpace {
    private typealias ConnectionID = UInt32
    private typealias CreateFunction = @convention(c) (ConnectionID, Int32, CFDictionary?) -> UInt64
    private typealias SpacesFunction = @convention(c) (ConnectionID, CFArray) -> Int32
    private typealias WindowsFunction = @convention(c) (ConnectionID, CFArray, CFArray) -> Void
    private typealias DestroyFunction = @convention(c) (ConnectionID, UInt64) -> Void

    private struct Bridge {
        let connection: ConnectionID
        let create: CreateFunction
        let show: SpacesFunction
        let hide: SpacesFunction
        let add: WindowsFunction
        let remove: WindowsFunction
        let destroy: DestroyFunction
    }

    private static let bridge: Bridge? = {
        func symbol(_ name: String) -> UnsafeMutableRawPointer? {
            dlsym(UnsafeMutableRawPointer(bitPattern: -2), name)
        }

        guard let main = symbol("CGSMainConnectionID"),
              let create = symbol("CGSSpaceCreate"),
              let show = symbol("CGSShowSpaces"),
              let hide = symbol("CGSHideSpaces"),
              let add = symbol("CGSAddWindowsToSpaces"),
              let remove = symbol("CGSRemoveWindowsFromSpaces"),
              let destroy = symbol("CGSSpaceDestroy") else {
            return nil
        }

        let connection = unsafeBitCast(main, to: (@convention(c) () -> ConnectionID).self)()
        guard connection != 0 else { return nil }

        return Bridge(
            connection: connection,
            create: unsafeBitCast(create, to: CreateFunction.self),
            show: unsafeBitCast(show, to: SpacesFunction.self),
            hide: unsafeBitCast(hide, to: SpacesFunction.self),
            add: unsafeBitCast(add, to: WindowsFunction.self),
            remove: unsafeBitCast(remove, to: WindowsFunction.self),
            destroy: unsafeBitCast(destroy, to: DestroyFunction.self)
        )
    }()

    private let bridge: Bridge
    private let space: UInt64
    private var windows = Set<Int>()
    private var isClosed = false

    init?() {
        guard let bridge = Self.bridge else { return nil }

        // Flag 1 creates an overlay Space without Finder desktop icons.
        let space = bridge.create(bridge.connection, 1, nil)
        guard space != 0 else { return nil }

        self.bridge = bridge
        self.space = space
        _ = bridge.show(bridge.connection, [NSNumber(value: space)] as CFArray)
    }

    deinit {
        close()
    }

    /// Call before the window is ordered in for the first time.
    func add(_ window: NSWindow) {
        guard !isClosed,
              window.windowNumber > 0,
              windows.insert(window.windowNumber).inserted else {
            return
        }

        bridge.add(
            bridge.connection,
            [NSNumber(value: window.windowNumber)] as CFArray,
            [NSNumber(value: space)] as CFArray
        )
    }

    /// Windows must leave before their only Space is destroyed.
    func close() {
        guard !isClosed else { return }
        isClosed = true

        if !windows.isEmpty {
            bridge.remove(
                bridge.connection,
                windows.map { NSNumber(value: $0) } as CFArray,
                [NSNumber(value: space)] as CFArray
            )
            windows.removeAll()
        }

        _ = bridge.hide(bridge.connection, [NSNumber(value: space)] as CFArray)
        bridge.destroy(bridge.connection, space)
    }
}
