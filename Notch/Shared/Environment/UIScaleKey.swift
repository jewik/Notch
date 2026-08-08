//
//  UIScaleKey.swift
//  UITests
//
//  Created by Usanin Ivan on 01.08.2026.
//

import SwiftUI

private struct UIScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var uiScale: CGFloat {
        get { self[UIScaleKey.self] }
        set { self[UIScaleKey.self] = newValue }
    }
}
