//
//  MediaRemoteService.swift
//  UITests
//
//  Created by Usanin Ivan on 31.07.2026.
//

import Foundation
import AppKit


struct NowPlayingInfo: Equatable {

    let title: String?
    let artist: String?
    let album: String?
    let artwork: NSImage?

    
    static func == (
        lhs: NowPlayingInfo,
        rhs: NowPlayingInfo
    ) -> Bool {

        lhs.title == rhs.title &&
        lhs.artist == rhs.artist &&
        lhs.album == rhs.album
    }
}



final class MediaRemoteService {

    static let shared = MediaRemoteService()


    private var frameworkHandle: UnsafeMutableRawPointer?


    // MARK: Functions

    private var getNowPlayingInfo:
    (
        (@escaping (CFDictionary?) -> Void) -> Void
    )?


    private var registerForNotifications:
    (
        (@escaping () -> Void) -> Void
    )?



    private var notificationToken: NSObjectProtocol?


    private init() {
        loadFramework()
    }



    // MARK: Load MediaRemote


    private func loadFramework() {

        frameworkHandle = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
            RTLD_NOW
        )
        
        print(
            "MediaRemote handle:",
            frameworkHandle as Any
        )


        guard let frameworkHandle else {

            print("❌ Cannot load MediaRemote.framework")
            return
        }



        // MARK: MRMediaRemoteGetNowPlayingInfo

        if let symbol = dlsym(
            frameworkHandle,
            "MRMediaRemoteGetNowPlayingInfo"
        ) {


            let function =
            unsafeBitCast(
                symbol,
                to:
                (
                    @convention(c)
                    (
                        DispatchQueue,
                        @escaping (CFDictionary?) -> Void
                    ) -> Void
                ).self
            )


            getNowPlayingInfo = { completion in

                function(
                    DispatchQueue.main,
                    completion
                )
            }
        }
        else {

            print("❌ MRMediaRemoteGetNowPlayingInfo unavailable")
        }



        // MARK: MRMediaRemoteRegisterForNowPlayingNotifications


        if let symbol = dlsym(
            frameworkHandle,
            "MRMediaRemoteRegisterForNowPlayingNotifications"
        ) {


            let function =
            unsafeBitCast(
                symbol,
                to:
                (
                    @convention(c)
                    (
                        DispatchQueue
                    ) -> Void
                ).self
            )


            registerForNotifications = { completion in

                function(
                    DispatchQueue.main
                )

                completion()
            }

        }
        else {

            print(
                "⚠️ MRMediaRemoteRegisterForNowPlayingNotifications unavailable"
            )
        }
    }



    // MARK: Start


    func start() {


        registerForNotifications? {

            print(
                "✅ MediaRemote notifications registered"
            )

        }



        notificationToken =
        DistributedNotificationCenter
            .default()
            .addObserver(
                forName:
                    NSNotification.Name(
                        "kMRMediaRemoteNowPlayingInfoDidChangeNotification"
                    ),
                object: nil,
                queue: .main
            ) { [weak self] _ in

                self?.nowPlayingChanged()
            }


        print("▶️ MediaRemote started")
    }



    func stop() {

        if let token = notificationToken {

            DistributedNotificationCenter
                .default()
                .removeObserver(token)

            notificationToken = nil
        }
    }




    // MARK: Async Stream


    private var continuation:
        AsyncStream<NowPlayingInfo>.Continuation?



    lazy var stream:
    AsyncStream<NowPlayingInfo> = {


        AsyncStream { continuation in

            self.continuation = continuation
        }

    }()




    private func nowPlayingChanged() {

        fetch { [weak self] info in

            guard let info else {
                return
            }


            self?.continuation?
                .yield(info)
        }
    }




    // MARK: Fetch


    func fetch(
        completion:
        @escaping (NowPlayingInfo?) -> Void
    ) {


        guard let getNowPlayingInfo else {

            print(
                "❌ getNowPlayingInfo unavailable"
            )

            completion(nil)
            return
        }



        getNowPlayingInfo { dictionary in


            guard
                let dictionary
            else {

                print(
                    "⚠️ MediaRemote returned nil"
                )

                completion(nil)
                return
            }



            let info =
                dictionary as NSDictionary



            let title =
                info[
                    "kMRMediaRemoteNowPlayingInfoTitle"
                ] as? String



            let artist =
                info[
                    "kMRMediaRemoteNowPlayingInfoArtist"
                ] as? String



            let album =
                info[
                    "kMRMediaRemoteNowPlayingInfoAlbum"
                ] as? String



            var artwork: NSImage?



            if let data =
                info[
                    "kMRMediaRemoteNowPlayingInfoArtworkData"
                ] as? Data {

                artwork =
                    NSImage(
                        data: data
                    )
            }



            let result =
                NowPlayingInfo(
                    title: title,
                    artist: artist,
                    album: album,
                    artwork: artwork
                )


            completion(result)
        }
    }



    deinit {

        stop()

        if let frameworkHandle {

            dlclose(frameworkHandle)
        }
    }
}
