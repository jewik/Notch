//
//  JLampViewModel.swift
//  UITests
//
//  Created by Usanin Ivan on 03.08.2026.
//

//import Foundation
import Combine
import SwiftUI

@Observable
final class JLampModel {
    
    var jBrightness: Int = 0
    var jSpeed: Int = 0
    var jScale: Int = 0
    
    deinit {
        print("PlayerViewModel deinit")
    }
}
