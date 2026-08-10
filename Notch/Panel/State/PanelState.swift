

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

enum NotificationPreset {
    case greeting
    case valediction
}


@Observable
final class PanelState {
    
    var panelMode: PanelMode = .collapsed
    var expandedPreset: ExpandedPreset = .home
    var notification: NotificationPreset = .greeting
    
    var isNotificationTime: Bool = false

}
