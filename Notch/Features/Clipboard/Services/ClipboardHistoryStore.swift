import Foundation

final class ClipboardHistoryStore {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var fileURL: URL {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return applicationSupportURL
            .appendingPathComponent("Notch", isDirectory: true)
            .appendingPathComponent("clipboard-history.json")
    }

    func loadCaptures() -> [ClipboardCapture] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([ClipboardCapture].self, from: data)
        } catch {
            return []
        }
    }

    func saveCaptures(_ captures: [ClipboardCapture]) {
        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            let data = try encoder.encode(captures)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Failed to save clipboard history: \(error)")
        }
    }
}
