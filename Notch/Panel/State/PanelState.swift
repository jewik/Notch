

import Observation
import SwiftUI

enum ExpandedPreset {
    case home
    case tray
}

enum PanelMode {
    case collapsed
    case expanded
}



@Observable
final class PanelState {
    
    var useGlassPanelSurface: Bool = false
    
    var panelMode: PanelMode = .collapsed
    var expandedPreset: ExpandedPreset = .home

}
