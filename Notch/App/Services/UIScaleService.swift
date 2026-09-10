//
//  UIScaleService.swift
//  UITests
//
//  Created by Usanin Ivan on 24.07.2026.
//

import AppKit
import Combine
import CoreGraphics

enum UIScaleService {
    /// Private design density for scale-invariant UI. Raise this to make every
    /// design point physically smaller, lower it to make the UI physically larger.
    private static let designPointsPerMillimeter: CGFloat = 5

    static func pointMultiplier(for screen: NSScreen) -> CGFloat {
        let displayPointsPerMillimeter = appKitPointsPerMillimeter(for: screen)
        guard displayPointsPerMillimeter > 0 else { return 1 }

        return displayPointsPerMillimeter / designPointsPerMillimeter
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

    private static func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard let number = screen.deviceDescription[key] as? NSNumber else { return nil }
        return CGDirectDisplayID(number.uint32Value)
    }
}

final class UIMetrics: ObservableObject {
    @Published private(set) var pointMultiplier: CGFloat = 1

    func update(for screen: NSScreen) {
        pointMultiplier = UIScaleService.pointMultiplier(for: screen)
    }

    func points(_ designPoints: CGFloat) -> CGFloat {
        designPoints * pointMultiplier
    }
}
