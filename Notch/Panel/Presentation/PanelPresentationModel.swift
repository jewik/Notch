import Combine

final class PanelPresentationModel: ObservableObject {
    @Published var isChromeVisible = false
    @Published var isContentVisible = false
    @Published var route: PanelRoute = .home

    var sizePreset: PanelSizePreset {
        route.sizePreset
    }
}
