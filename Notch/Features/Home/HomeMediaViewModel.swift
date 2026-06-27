import AppKit
import Combine
import Foundation

final class HomeMediaViewModel: ObservableObject {
    @Published private(set) var item = HomeMediaItem.empty

    private let mediaRemote = MediaRemoteClient()
    private var refreshTimer: Timer?

    var isMediaRemoteAvailable: Bool {
        mediaRemote.isAvailable
    }

    func start() {
        refresh()

        guard refreshTimer == nil else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func previous() {
        mediaRemote.send(.previous)
        scheduleFollowUpRefresh()
    }

    func togglePlayPause() {
        mediaRemote.send(.togglePlayPause)
        scheduleFollowUpRefresh()
    }

    func next() {
        mediaRemote.send(.next)
        scheduleFollowUpRefresh()
    }

    private func refresh() {
        mediaRemote.fetchNowPlaying { [weak self] item in
            self?.item = item
        }
    }

    private func scheduleFollowUpRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.refresh()
        }
    }
}
