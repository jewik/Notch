import SwiftUI

struct HomePageView: View {
    let pointMultiplier: CGFloat
    @StateObject private var mediaViewModel = HomeMediaViewModel()

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        HStack(spacing: 0) {
            HomeMediaPlayerView(
                item: mediaViewModel.item,
                isAvailable: mediaViewModel.isMediaRemoteAvailable,
                pointMultiplier: pointMultiplier,
                previous: mediaViewModel.previous,
                togglePlayPause: mediaViewModel.togglePlayPause,
                next: mediaViewModel.next,
                showOutputSource: mediaViewModel.showOutputSource
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, points(10))
                .padding(.horizontal, points(5))

            Spacer(minLength: 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
        .padding(.horizontal, points(10))
        .padding(.bottom, points(10))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear {
            mediaViewModel.start()
        }
        .onDisappear {
            mediaViewModel.stop()
        }
    }
}

private struct HomeMediaPlayerView: View {
    let item: HomeMediaItem
    let isAvailable: Bool
    let pointMultiplier: CGFloat
    let previous: () -> Void
    let togglePlayPause: () -> Void
    let next: () -> Void
    let showOutputSource: () -> Void

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
            HStack(spacing: points(12)) {
                HomeMediaArtworkView(image: item.artwork, pointMultiplier: pointMultiplier)
                    .frame(width: points(70), height: points(70))

                VStack(alignment: .leading, spacing: points(5)) {
                    Spacer(minLength: 0)

                    Text(item.title)
                        .font(.system(size: points(15), weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(item.hasContent ? 0.92 : 0.48))
                        .lineLimit(1)

                    Text(item.subtitle)
                        .font(.system(size: points(10), weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)

                    HStack(spacing: points(7)) {
                        HomePlayerButton(
                            systemName: "backward.end.fill",
                            accessibilityLabel: "Previous",
                            pointMultiplier: pointMultiplier,
                            action: previous
                        )

                        HomePlayerButton(
                            systemName: item.isPlaying ? "pause.fill" : "play.fill",
                            accessibilityLabel: item.isPlaying ? "Pause" : "Play",
                            pointMultiplier: pointMultiplier,
                            action: togglePlayPause
                        )

                        HomePlayerButton(
                            systemName: "forward.end.fill",
                            accessibilityLabel: "Next",
                            pointMultiplier: pointMultiplier,
                            action: next
                        )

                        HomePlayerButton(
                            systemName: "airplayaudio",
                            accessibilityLabel: "Output source",
                            pointMultiplier: pointMultiplier,
                            action: showOutputSource
                        )
                    }
                    .disabled(!isAvailable)
                    .opacity(isAvailable ? 1 : 0.42)
                    .padding(.top, points(2))

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

private struct HomeMediaArtworkView: View {
    let image: NSImage?
    let pointMultiplier: CGFloat

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: points(20), style: .continuous)
                .fill(.white.opacity(0.08))

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: points(26), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.42))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: points(20), style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: points(20), style: .continuous)
                .stroke(.white.opacity(0.09), lineWidth: 1)
        )
    }
}

private struct HomePlayerButton: View {
    let systemName: String
    let accessibilityLabel: String
    let pointMultiplier: CGFloat
    let action: () -> Void

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: points(11), weight: .semibold))
                .frame(width: points(27), height: points(27))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.78))
        .background(
            RoundedRectangle(cornerRadius: points(7), style: .continuous)
                .fill(.white.opacity(0.09))
        )
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }
}
