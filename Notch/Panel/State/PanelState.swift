

import Observation
import SwiftUI

enum ExpandedPanelPresets {
    case greeting
    case home
    case tray
    case valediction
}

enum CollapsedPanelPresets {
    case none
    case player
    case tray
}

@Observable
final class PanelState {
    
    var isExpanded: Bool = true
    var collapsedPreset: CollapsedPanelPresets = .none
    var expandedPreset: ExpandedPanelPresets = .greeting
    
    func expand() {
        withAnimation {
            isExpanded = true
        }
    }
    func collapse(force: Bool = false) {
        if !force && (expandedPreset == .greeting || expandedPreset == .valediction) {
            return
        }
        withAnimation {
            isExpanded = false
        }
    }
}
