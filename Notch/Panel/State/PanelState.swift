

import Observation
import Combine

enum PanelPresets {
    case collapsed
    case home
    case tray
}

@Observable
final class PanelState {
    var preset: PanelPresets = .collapsed
}
