//
//  NowPlaying.swift
//  UITests
//
//  Created by Usanin Ivan on 31.07.2026.
//


import Foundation
import Combine


final class NowPlayingViewModel{

    @Published private(set) var info: NowPlayingInfo?


    private var task: Task<Void, Never>?


    func start() {

        MediaRemoteService.shared.start()


        task = Task { @MainActor [weak self] in

            for await value in MediaRemoteService.shared.stream {

                self?.info = value
            }
        }


        MediaRemoteService.shared.fetch { [weak self] info in

            Task { @MainActor in
                self?.info = info
            }
        }
    }


    deinit {
        task?.cancel()
        MediaRemoteService.shared.stop()
    }
}
