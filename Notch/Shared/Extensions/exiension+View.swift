//
//  exiension+View.swift
//  UITests
//
//  Created by Usanin Ivan on 01.08.2026.
//

import SwiftUI


extension View {
    func uiMultiplier(_ ui: CGFloat) -> some View {
        environment(\.uiScale, ui)
    }
}
