import AppKit
import Combine
import Foundation

@MainActor
final class ClipboardViewModel: ObservableObject {
    @Published private(set) var captures: [ClipboardCapture]
    @Published var searchText = ""
    @Published var selectedKind: ClipboardContentKind?
    @Published var selectedCaptureID: UUID?
    @Published private(set) var lastStatusMessage: String?

    private let store: ClipboardHistoryStore
    private let pasteboardService: ClipboardPasteboardService
    private let maxCaptures = 200

    convenience init() {
        self.init(
            store: ClipboardHistoryStore(),
            pasteboardService: ClipboardPasteboardService()
        )
    }

    init(
        store: ClipboardHistoryStore,
        pasteboardService: ClipboardPasteboardService
    ) {
        self.store = store
        self.pasteboardService = pasteboardService
        self.captures = store.loadCaptures()

        pasteboardService.onCapture = { [weak self] capture in
            Task { @MainActor in
                self?.insertOrUpdate(capture)
            }
        }
    }

    var filteredCaptures: [ClipboardCapture] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return captures.filter { capture in
            let matchesKind = selectedKind.map { capture.primaryKind == $0 } ?? true
            guard matchesKind else { return false }

            guard !query.isEmpty else { return true }
            return capture.preferredDisplayTitle.lowercased().contains(query) ||
                capture.displayTitle.lowercased().contains(query) ||
                capture.searchableText.lowercased().contains(query) ||
                capture.sourceApplicationName?.lowercased().contains(query) == true
        }
    }

    var selectedCapture: ClipboardCapture? {
        if let selectedCaptureID,
           let capture = filteredCaptures.first(where: { $0.id == selectedCaptureID }) {
            return capture
        }
        return filteredCaptures.first
    }

    var canPasteAutomatically: Bool {
        pasteboardService.canPasteAutomatically
    }

    func start() {
        pasteboardService.start()
    }

    func stop() {
        pasteboardService.stop()
    }

    func select(_ capture: ClipboardCapture) {
        selectedCaptureID = capture.id
    }

    func selectPrevious() {
        moveSelection(by: -1)
    }

    func selectNext() {
        moveSelection(by: 1)
    }

    func ensureSelection() {
        let captures = filteredCaptures
        guard !captures.isEmpty else {
            selectedCaptureID = nil
            return
        }

        if let selectedCaptureID,
           captures.contains(where: { $0.id == selectedCaptureID }) {
            return
        }

        selectedCaptureID = captures[0].id
    }

    func rememberPasteTarget() {
        pasteboardService.rememberPasteTarget()
    }

    func setFilter(_ kind: ClipboardContentKind?) {
        selectedKind = selectedKind == kind ? nil : kind
        if let selectedCapture, !filteredCaptures.contains(where: { $0.id == selectedCapture.id }) {
            selectedCaptureID = filteredCaptures.first?.id
        }
    }

    func copy(_ capture: ClipboardCapture) {
        updateCopyMetadata(for: capture.id)
        if let updatedCapture = captures.first(where: { $0.id == capture.id }) {
            pasteboardService.copy(updatedCapture)
        }
        lastStatusMessage = "Copied"
    }

    func paste(_ capture: ClipboardCapture) {
        if let updatedCapture = captures.first(where: { $0.id == capture.id }) {
            let didPaste = pasteboardService.paste(updatedCapture)
            lastStatusMessage = didPaste ? "Pasted" : "Copied. Enable Accessibility to paste automatically."
        } else {
            lastStatusMessage = "Item unavailable"
        }
    }

    func togglePinned(_ capture: ClipboardCapture) {
        guard let index = captures.firstIndex(where: { $0.id == capture.id }) else { return }
        captures[index].isPinned.toggle()
        sortAndPersist()
    }

    func delete(_ capture: ClipboardCapture) {
        captures.removeAll { $0.id == capture.id }
        if selectedCaptureID == capture.id {
            selectedCaptureID = filteredCaptures.first?.id
        }
        persist()
    }

    func clearUnpinned() {
        captures.removeAll { !$0.isPinned }
        selectedCaptureID = filteredCaptures.first?.id
        persist()
    }

    func clearHistory() {
        captures.removeAll()
        selectedCaptureID = nil
        persist()
    }

    func requestAccessibilityPermission() {
        pasteboardService.requestAccessibilityPermission()
    }

    private func insertOrUpdate(_ capture: ClipboardCapture) {
        if let index = captures.firstIndex(where: { $0.exactHash == capture.exactHash }) {
            let wasPinned = captures[index].isPinned
            let copyCount = captures[index].copyCount + 1
            captures[index].lastCopiedAt = Date()
            captures[index].copyCount = copyCount
            captures[index].isPinned = wasPinned
        } else {
            captures.insert(capture, at: 0)
            selectedCaptureID = selectedCaptureID ?? capture.id
        }

        sortAndPersist()
    }

    private func updateCopyMetadata(for captureID: UUID) {
        guard let index = captures.firstIndex(where: { $0.id == captureID }) else { return }
        captures[index].lastCopiedAt = Date()
        captures[index].copyCount += 1
        sortAndPersist()
    }

    private func moveSelection(by offset: Int) {
        let captures = filteredCaptures
        guard !captures.isEmpty else {
            selectedCaptureID = nil
            return
        }

        guard let selectedCaptureID,
              let currentIndex = captures.firstIndex(where: { $0.id == selectedCaptureID }) else {
            selectedCaptureID = offset < 0 ? captures.last?.id : captures.first?.id
            return
        }

        let nextIndex = min(max(currentIndex + offset, 0), captures.count - 1)
        self.selectedCaptureID = captures[nextIndex].id
    }

    private func sortAndPersist() {
        captures.sort { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.lastCopiedAt > rhs.lastCopiedAt
        }

        if captures.count > maxCaptures {
            let pinned = captures.filter(\.isPinned)
            let unpinned = captures.filter { !$0.isPinned }
            captures = pinned + Array(unpinned.prefix(max(0, maxCaptures - pinned.count)))
        }

        persist()
    }

    private func persist() {
        store.saveCaptures(captures)
    }
}

@MainActor
enum ClipboardFeature {
    static let shared = ClipboardViewModel()
}
