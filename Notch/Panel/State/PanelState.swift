

import Observation
import SwiftUI

enum ExpandedPanelPresets {
    case home
    case tray
}

enum CollapsedPanelPresets {
    case none
    case player
    case tray
}

@Observable
final class PanelState {
    
    var isExpanded: Bool = false
    var collapsedPreset: CollapsedPanelPresets = .none
    var expandedPreset: ExpandedPanelPresets = .home
    
    func expand() {
        withAnimation {
            isExpanded = true
        }
    }
    func collapse() {
        withAnimation {
            isExpanded = false
        }
    }
}
