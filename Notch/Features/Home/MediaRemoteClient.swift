import AppKit
import Foundation

final class MediaRemoteClient {
    enum Command {
        case previous
        case togglePlayPause
        case next
    }

    private typealias NowPlayingInfoCallback = @convention(block) (NSDictionary?) -> Void
    private typealias IsPlayingCallback = @convention(block) (Bool) -> Void
    private typealias GetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping NowPlayingInfoCallback) -> Void
    private typealias GetNowPlayingApplicationIsPlayingFunction = @convention(c) (DispatchQueue, @escaping IsPlayingCallback) -> Void
    private typealias SendCommandFunction = @convention(c) (UInt32, NSDictionary?) -> Void

    private enum MediaRemoteCommand: UInt32 {
        case play = 0
        case pause = 1
        case togglePlayPause = 2
        case nextTrack = 4
        case previousTrack = 5
    }

    private let handle: UnsafeMutableRawPointer?
    private let getNowPlayingInfo: GetNowPlayingInfoFunction?
    private let getNowPlayingApplicationIsPlaying: GetNowPlayingApplicationIsPlayingFunction?
    private let sendCommandFunction: SendCommandFunction?
    private let keys: MediaRemoteKeys

    var isAvailable: Bool {
        getNowPlayingInfo != nil && sendCommandFunction != nil
    }

    init() {
        let frameworkPath = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
        handle = dlopen(frameworkPath, RTLD_NOW)

        getNowPlayingInfo = Self.loadFunction(
            from: handle,
            named: "MRMediaRemoteGetNowPlayingInfo",
            as: GetNowPlayingInfoFunction.self
        )
        getNowPlayingApplicationIsPlaying = Self.loadFunction(
            from: handle,
            named: "MRMediaRemoteGetNowPlayingApplicationIsPlaying",
            as: GetNowPlayingApplicationIsPlayingFunction.self
        )
        sendCommandFunction = Self.loadFunction(
            from: handle,
            named: "MRMediaRemoteSendCommand",
            as: SendCommandFunction.self
        )
        keys = MediaRemoteKeys(handle: handle)
    }

    deinit {
        if let handle {
            dlclose(handle)
        }
    }

    func fetchNowPlaying(completion: @escaping (HomeMediaItem) -> Void) {
        guard let getNowPlayingInfo else {
            completion(.empty)
            return
        }

        getNowPlayingInfo(.main) { [weak self] info in
            guard let self else { return }

            let mediaInfo = info as? [String: Any]
            let title = self.stringValue(in: mediaInfo, for: self.keys.title)
            let artist = self.stringValue(in: mediaInfo, for: self.keys.artist)
            let albumArtist = self.stringValue(in: mediaInfo, for: self.keys.albumArtist)
            let artwork = self.artwork(in: mediaInfo)
            let hasContent = !(title ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            self.fetchIsPlaying { isPlaying in
                completion(
                    HomeMediaItem(
                        title: hasContent ? (title ?? "Unknown title") : HomeMediaItem.empty.title,
                        artist: artist ?? albumArtist ?? HomeMediaItem.empty.artist,
                        sourceName: nil,
                        artwork: artwork,
                        isPlaying: isPlaying,
                        hasContent: hasContent
                    )
                )
            }
        }
    }

    func send(_ command: Command) {
        guard let sendCommandFunction else { return }

        let mediaRemoteCommand: MediaRemoteCommand
        switch command {
        case .previous:
            mediaRemoteCommand = .previousTrack
        case .togglePlayPause:
            mediaRemoteCommand = .togglePlayPause
        case .next:
            mediaRemoteCommand = .nextTrack
        }

        sendCommandFunction(mediaRemoteCommand.rawValue, nil)
    }

    private func fetchIsPlaying(completion: @escaping (Bool) -> Void) {
        guard let getNowPlayingApplicationIsPlaying else {
            completion(false)
            return
        }

        getNowPlayingApplicationIsPlaying(.main) { isPlaying in
            completion(isPlaying)
        }
    }

    private func stringValue(in info: [String: Any]?, for key: String) -> String? {
        info?[key] as? String
    }

    private func artwork(in info: [String: Any]?) -> NSImage? {
        guard let data = info?[keys.artworkData] as? Data else { return nil }
        return NSImage(data: data)
    }

    private static func loadFunction<T>(
        from handle: UnsafeMutableRawPointer?,
        named symbol: String,
        as type: T.Type
    ) -> T? {
        guard let handle, let symbolPointer = dlsym(handle, symbol) else { return nil }
        return unsafeBitCast(symbolPointer, to: type)
    }
}

private struct MediaRemoteKeys {
    let title: String
    let artist: String
    let albumArtist: String
    let artworkData: String

    init(handle: UnsafeMutableRawPointer?) {
        title = Self.stringConstant(
            from: handle,
            named: "kMRMediaRemoteNowPlayingInfoTitle",
            fallback: "kMRMediaRemoteNowPlayingInfoTitle"
        )
        artist = Self.stringConstant(
            from: handle,
            named: "kMRMediaRemoteNowPlayingInfoArtist",
            fallback: "kMRMediaRemoteNowPlayingInfoArtist"
        )
        albumArtist = Self.stringConstant(
            from: handle,
            named: "kMRMediaRemoteNowPlayingInfoAlbumArtist",
            fallback: "kMRMediaRemoteNowPlayingInfoAlbumArtist"
        )
        artworkData = Self.stringConstant(
            from: handle,
            named: "kMRMediaRemoteNowPlayingInfoArtworkData",
            fallback: "kMRMediaRemoteNowPlayingInfoArtworkData"
        )
    }

    private static func stringConstant(
        from handle: UnsafeMutableRawPointer?,
        named symbol: String,
        fallback: String
    ) -> String {
        guard let handle, let symbolPointer = dlsym(handle, symbol) else {
            return fallback
        }

        let cfString = symbolPointer.assumingMemoryBound(to: CFString?.self).pointee
        return (cfString as String?) ?? fallback
    }
}
