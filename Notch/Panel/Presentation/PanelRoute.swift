enum PanelRoute: Hashable {
    case home
    case clipboard

    var sizePreset: PanelSizePreset {
        switch self {
        case .home:
            .home
        case .clipboard:
            .clipboard
        }
    }
}
