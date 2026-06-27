import AppKit
import SwiftUI

struct ClipboardPageView: View {
    let pointMultiplier: CGFloat

    @ObservedObject private var viewModel: ClipboardViewModel
    @FocusState private var isSearchFocused: Bool

    init(pointMultiplier: CGFloat) {
        self.init(pointMultiplier: pointMultiplier, viewModel: ClipboardFeature.shared)
    }

    init(pointMultiplier: CGFloat, viewModel: ClipboardViewModel) {
        self.pointMultiplier = pointMultiplier
        self.viewModel = viewModel
    }

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        VStack(spacing: points(8)) {
            searchRow

            if viewModel.captures.isEmpty {
                ClipboardEmptyStateView(
                    title: "Copy something",
                    subtitle: "History will appear here.",
                    pointMultiplier: pointMultiplier
                )
            } else if viewModel.filteredCaptures.isEmpty {
                ClipboardEmptyStateView(
                    title: "No matches",
                    subtitle: "Try another search.",
                    pointMultiplier: pointMultiplier
                )
            } else {
                historyList
            }
        }
        .padding(.horizontal, points(14))
        .padding(.top, points(10))
        .padding(.bottom, points(12))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            viewModel.start()
            DispatchQueue.main.async {
                isSearchFocused = true
            }
        }
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.ensureSelection()
        }
        .onKeyPress(.return) {
            pasteSelected()
            return .handled
        }
        .onKeyPress(.upArrow) {
            viewModel.selectPrevious()
            return .handled
        }
        .onKeyPress(.downArrow) {
            viewModel.selectNext()
            return .handled
        }
    }

    private var searchRow: some View {
        HStack(spacing: points(7)) {
            searchField
            clearHistoryButton
        }
    }

    private var searchField: some View {
        HStack(spacing: points(7)) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: points(11), weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))

            TextField("Search", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: points(12), weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .focused($isSearchFocused)
                .onSubmit {
                    pasteSelected()
                }
        }
        .padding(.horizontal, points(10))
        .frame(maxWidth: .infinity)
        .frame(height: points(30))
        .background(
            RoundedRectangle(cornerRadius: points(15), style: .continuous)
                .fill(.white.opacity(0.09))
        )
    }

    private var clearHistoryButton: some View {
        Button {
            viewModel.clearHistory()
        } label: {
            Image(systemName: "trash")
                .font(.system(size: points(12), weight: .semibold))
                .frame(width: points(30), height: points(30))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(viewModel.captures.isEmpty ? 0.28 : 0.72))
        .background(
            RoundedRectangle(cornerRadius: points(15), style: .continuous)
                .fill(.white.opacity(viewModel.captures.isEmpty ? 0.04 : 0.09))
        )
        .disabled(viewModel.captures.isEmpty)
        .accessibilityLabel("Clear history")
        .help("Clear history")
    }

    private var historyList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: points(6)) {
                    ForEach(viewModel.filteredCaptures) { capture in
                        ClipboardHistoryRow(
                            capture: capture,
                            isSelected: viewModel.selectedCapture?.id == capture.id,
                            pointMultiplier: pointMultiplier,
                            select: { viewModel.select(capture) },
                            paste: { viewModel.paste(capture) },
                            pasteRaw: { viewModel.paste(capture, style: .raw) }
                        )
                        .id(capture.id)
                    }
                }
                .padding(.vertical, points(1))
                
            }
            .onChange(of: viewModel.selectedCaptureID) { _, selectedCaptureID in
                guard let selectedCaptureID else { return }
                withAnimation(.easeInOut(duration: 0.16)) {
                    proxy.scrollTo(selectedCaptureID, anchor: .center)
                }
            }
        }
    }

    private func pasteSelected() {
        guard let capture = viewModel.selectedCapture else { return }
        viewModel.paste(capture)
    }
}

private struct ClipboardHistoryRow: View {
    let capture: ClipboardCapture
    let isSelected: Bool
    let pointMultiplier: CGFloat
    let select: () -> Void
    let paste: () -> Void
    let pasteRaw: () -> Void

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        HStack(spacing: points(10)) {
            ClipboardItemPreviewIcon(capture: capture, pointMultiplier: pointMultiplier)
                .frame(width: points(50), height: points(50))

            VStack(alignment: .leading, spacing: points(4)) {
                Text(capture.preferredDisplayTitle)
                    .font(.system(size: points(12), weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(.white.opacity(0.92))

                Text(metadata)
                    .font(.system(size: points(9), weight: .medium))
                    .lineLimit(1)
                    .foregroundStyle(.white.opacity(0.54))
            }

            Spacer(minLength: 0)

            if capture.hasRawTextFormatting {
                rawPasteButton
            }
        }
        .padding(points(8))
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: points(15), style: .continuous)
                .fill(isSelected ? .white.opacity(0.13) : .white.opacity(0.055))
        )
        .overlay(
            RoundedRectangle(cornerRadius: points(15), style: .continuous)
                .stroke(.white.opacity(isSelected ? 0.18 : 0.07), lineWidth: 1)
        )
        .simultaneousGesture(TapGesture(count: 1).onEnded {
            select()
        })
        .simultaneousGesture(TapGesture(count: 2).onEnded {
            select()
            paste()
        })
    }

    private var rawPasteButton: some View {
        Button {
            select()
            pasteRaw()
        } label: {
            Text("Raw")
                .font(.system(size: points(9), weight: .bold))
                .foregroundStyle(.white.opacity(0.82))
                .frame(width: points(38), height: points(24))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: points(8), style: .continuous)
                .fill(.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: points(8), style: .continuous)
                .stroke(.white.opacity(0.11), lineWidth: 1)
        )
        .accessibilityLabel("Paste with formatting")
        .help("Paste with formatting")
    }

    private var metadata: String {
        let source = capture.sourceApplicationName ?? "Unknown app"
        let date = RelativeDateTimeFormatter.clipboardShort.localizedString(for: capture.lastCopiedAt, relativeTo: Date())
        let itemCount = capture.itemCount > 1 ? " · \(capture.itemCount) items" : ""
        return "\(source) · \(date)\(itemCount)"
    }
}

private struct ClipboardItemPreviewIcon: View {
    let capture: ClipboardCapture
    let pointMultiplier: CGFloat

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: points(10), style: .continuous)
                .fill(.white.opacity(0.1))

            switch capture.primaryKind {
            case .image:
                imagePreview
            case .file:
                filePreview
            case .pdf, .other:
                fallbackPreview
            case .text, .link, .richText:
                fallbackPreview
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: points(10), style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: points(10), style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let representation = capture.primaryImageRepresentation,
           let image = NSImage(data: representation.data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            fallbackPreview
        }
    }

    private var filePreview: some View {
        VStack(spacing: points(2)) {
            Image(systemName: firstFileURL?.hasDirectoryPath == true ? "folder.fill" : "doc.fill")
                .font(.system(size: points(15), weight: .semibold))
            Text(firstFileURL?.pathExtension.uppercased() ?? "FILE")
                .font(.system(size: points(6), weight: .bold))
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.82))
        .padding(points(4))
    }

    private var fallbackPreview: some View {
        Image(systemName: capture.primaryKind.systemImageName)
            .font(.system(size: points(16), weight: .semibold))
            .foregroundStyle(.white.opacity(0.8))
    }

    private var firstFileURL: URL? {
        capture.primaryFileURLs.first
    }

}

private struct ClipboardEmptyStateView: View {
    let title: String
    let subtitle: String
    let pointMultiplier: CGFloat

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        VStack(spacing: points(5)) {
            Text(title)
                .font(.system(size: points(12), weight: .semibold))
                .foregroundStyle(.white.opacity(0.86))
            Text(subtitle)
                .font(.system(size: points(10), weight: .medium))
                .foregroundStyle(.white.opacity(0.52))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension RelativeDateTimeFormatter {
    static let clipboardShort: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}
