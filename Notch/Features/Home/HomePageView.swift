import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct HomePageView: View {
    let pointMultiplier: CGFloat
    let openRoute: (PanelRoute) -> Void
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
                next: mediaViewModel.next
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, points(10))
                .padding(.horizontal, points(5))

            HomeRouteButtonsView(
                pointMultiplier: pointMultiplier,
                openRoute: openRoute
            )
            .frame(width: points(80))
            .frame(maxHeight: .infinity)

            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, points(10))
                .padding(.horizontal, points(5))
            
            HomeAirDropZoneView(pointMultiplier: pointMultiplier)
                .frame(width: points(70), height: points(70))

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

private struct HomeRouteButtonsView: View {
    let pointMultiplier: CGFloat
    let openRoute: (PanelRoute) -> Void

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        VStack(spacing: points(7)) {
            HomeRouteButton(
                systemName: "doc.on.clipboard",
                title: "Clip",
                accessibilityLabel: "Clip",
                pointMultiplier: pointMultiplier
            ) {
                openRoute(.clipboard)
            }

            HomeRouteButton(
                systemName: "waveform.path.ecg",
                title: "Monitor",
                accessibilityLabel: "System Monitor",
                pointMultiplier: pointMultiplier
            ) {
                openRoute(.sysMonitor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct HomeRouteButton: View {
    let systemName: String
    let title: String
    let accessibilityLabel: String
    let pointMultiplier: CGFloat
    let action: () -> Void
    @State private var isHovered = false

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: points(6)) {
                Image(systemName: systemName)
                    .font(.system(size: points(15), weight: .semibold))

                Text(title)
                    .font(.system(size: points(12), weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .padding(.horizontal, points(8))
            .frame(width: points(80), height: points(28))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.72))
        .background {
            if isHovered {
                RoundedRectangle(cornerRadius: points(6), style: .continuous)
                    .fill(.white.opacity(0.14))
            }
        }
        .onHover { isHovered = $0 }
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }
}

private struct HomeAirDropZoneView: View {
    let pointMultiplier: CGFloat
    @State private var isDropTargeted = false
    @State private var isHintVisible = false

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        Button {
            showHint()
        } label: {
            ZStack {
                HomeAirDropLavaBackground(pointMultiplier: pointMultiplier)
                    .opacity(isDropTargeted ? 1 : 0.88)

                RoundedRectangle(cornerRadius: points(20), style: .continuous)
                    .fill(.black.opacity(isDropTargeted ? 0.2 : 0.3))

                if isHintVisible {
                    Text("Drop here")
                        .font(.system(size: points(10), weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.32), radius: points(3), y: points(1))
                        .transition(.opacity)
                } else {
                    Text("AirDrop")
                        .font(.system(size: points(10), weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(isDropTargeted ? 0.9 : 0.84))
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.35), radius: points(4), y: points(1))
                        .transition(.opacity)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: points(20), style: .continuous))
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: points(20), style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: points(20), style: .continuous)
                .stroke(.white.opacity(isDropTargeted ? 0.28 : 0.09), lineWidth: 1)
        )
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
            HomeAirDropService.share(providers)
        }
        .accessibilityLabel("AirDrop")
        .help("AirDrop")
    }

    private func showHint() {
        withAnimation(.easeInOut(duration: 0.16)) {
            isHintVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.16)) {
                isHintVisible = false
            }
        }
    }
}

private struct HomeAirDropLavaBackground: View {
    let pointMultiplier: CGFloat

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let bounds = CGRect(origin: .zero, size: size)
                context.fill(
                    Path(bounds),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.12, green: 0.06, blue: 0.2),
                            Color(red: 0.29, green: 0.12, blue: 0.46),
                            Color(red: 0.42, green: 0.3, blue: 0.12),
                            Color(red: 0.16, green: 0.06, blue: 0.24),
                        ]),
                        startPoint: CGPoint(x: size.width * wave(time, phase: 0.1), y: 0),
                        endPoint: CGPoint(x: size.width * wave(time, phase: 0.6), y: size.height)
                    )
                )

                context.addFilter(.blur(radius: points(9)))
                drawLavaBlob(
                    in: &context,
                    size: size,
                    time: time,
                    phase: 0,
                    color: Color(red: 0.72, green: 0.53, blue: 0.18).opacity(0.52)
                )
                drawLavaBlob(
                    in: &context,
                    size: size,
                    time: time,
                    phase: 1.7,
                    color: Color(red: 0.48, green: 0.17, blue: 0.72).opacity(0.62)
                )
                drawLavaBlob(
                    in: &context,
                    size: size,
                    time: time,
                    phase: 3.2,
                    color: Color(red: 0.88, green: 0.68, blue: 0.24).opacity(0.35)
                )
            }
        }
    }

    private func drawLavaBlob(
        in context: inout GraphicsContext,
        size: CGSize,
        time: TimeInterval,
        phase: Double,
        color: Color
    ) {
        let width = size.width * 0.82
        let height = size.height * 0.58
        let center = CGPoint(
            x: size.width * (0.5 + 0.28 * sin(time * 0.8 + phase)),
            y: size.height * (0.5 + 0.3 * cos(time * 0.65 + phase))
        )
        let rect = CGRect(
            x: center.x - width / 2,
            y: center.y - height / 2,
            width: width,
            height: height
        )

        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    private func wave(_ time: TimeInterval, phase: Double) -> CGFloat {
        CGFloat(0.5 + 0.35 * sin(time * 0.45 + phase))
    }
}

private enum HomeAirDropService {
    static func share(_ urls: [URL]) {
        guard !urls.isEmpty,
              let service = NSSharingService(named: .sendViaAirDrop) else { return }
        service.perform(withItems: urls)
    }

    static func share(_ providers: [NSItemProvider]) -> Bool {
        let providers = providers.filter {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }
        guard !providers.isEmpty else { return false }

        let group = DispatchGroup()
        let lock = NSLock()
        var fileURLs: [URL] = []

        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let url = fileURL(from: item) {
                    lock.lock()
                    fileURLs.append(url)
                    lock.unlock()
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            share(fileURLs)
        }

        return true
    }

    private static func fileURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL, url.isFileURL {
            return url
        }

        if let data = item as? Data,
           let url = URL(dataRepresentation: data, relativeTo: nil),
           url.isFileURL {
            return url
        }

        if let string = item as? String,
           let url = URL(string: string),
           url.isFileURL {
            return url
        }

        return nil
    }
}

private struct HomeMediaPlayerView: View {
    let item: HomeMediaItem
    let isAvailable: Bool
    let pointMultiplier: CGFloat
    let previous: () -> Void
    let togglePlayPause: () -> Void
    let next: () -> Void

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
