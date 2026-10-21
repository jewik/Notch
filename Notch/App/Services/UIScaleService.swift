//
//  UIScaleService.swift
//  UITests
//
//  Created by Usanin Ivan on 24.07.2026.
//

import AppKit
import Combine
import CoreGraphics
import Observation

enum UIScaleService {
    /// Private design density for scale-invariant UI. Raise this to make every
    /// design point physically smaller, lower it to make the UI physically larger.
    private static let designPointsPerMillimeter: CGFloat = 5

    static func pointMultiplier(for screen: NSScreen) -> CGFloat {
        let displayPointsPerMillimeter = appKitPointsPerMillimeter(for: screen)
        guard displayPointsPerMillimeter > 0 else { return 1 }

        return displayPointsPerMillimeter / designPointsPerMillimeter
    }

    static func collapsedPointMultiplier(for screen: NSScreen) -> CGFloat {
        // External displays already size the collapsed panel from the menu bar.
        // Only a built-in display needs resolution-independent physical sizing.
        guard isBuiltIn(screen) else { return 1 }
        return pointMultiplier(for: screen)
    }

    static func points(_ designPoints: CGFloat, for screen: NSScreen) -> CGFloat {
        designPoints * pointMultiplier(for: screen)
    }

    private static func appKitPointsPerMillimeter(for screen: NSScreen) -> CGFloat {
        let physicalSize = physicalSizeInMillimeters(for: screen)
        guard physicalSize.width > 0, screen.frame.width > 0 else { return designPointsPerMillimeter }

        return screen.frame.width / physicalSize.width
    }

    private static func physicalSizeInMillimeters(for screen: NSScreen) -> CGSize {
        guard let displayID = displayID(for: screen) else { return .zero }
        return CGDisplayScreenSize(displayID)
    }

    private static func isBuiltIn(_ screen: NSScreen) -> Bool {
        guard let displayID = displayID(for: screen) else { return false }
        return CGDisplayIsBuiltin(displayID) != 0
    }

    private static func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard let number = screen.deviceDescription[key] as? NSNumber else { return nil }
        return CGDirectDisplayID(number.uint32Value)
    }
}


@Observable
final class UIMetrics {
    private(set) var pointMultiplier: CGFloat = 1

    func update(for screen: NSScreen) {
        pointMultiplier = UIScaleService.collapsedPointMultiplier(for: screen)
    }

    func points(_ designPoints: CGFloat) -> CGFloat {
        designPoints * pointMultiplier
    }
}
