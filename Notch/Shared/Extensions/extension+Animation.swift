//
//  extension+Animation.swift
//  UITests
//
//  Created by Usanin Ivan on 01.08.2026.
//

import SwiftUI

extension Animation {
    static var smoothCollapceAnimation = Animation.smooth(duration: 0.4)

    static var bouncyExpandAnimation = Animation.spring(
        response: 0.4,
        dampingFraction: 0.6
    )
}
