import Foundation

final class ClipboardHistoryStore {
    private let key = "notch.clipboard.history.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func loadCaptures() -> [ClipboardCapture] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }

        do {
            return try decoder.decode([ClipboardCapture].self, from: data)
        } catch {
            return []
        }
    }

    func saveCaptures(_ captures: [ClipboardCapture]) {
        do {
            let data = try encoder.encode(captures)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            assertionFailure("Failed to save clipboard history: \(error)")
        }
    }
}
