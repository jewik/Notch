enum PanelRoute: Hashable {
    case home
    case sysMonitor
    case clipboard

    var sizePreset: PanelSizePreset {
        switch self {
        case .home:
            .home
        case .sysMonitor:
            .sysMonitor
        case .clipboard:
            .clipboard
        }
    }
}
