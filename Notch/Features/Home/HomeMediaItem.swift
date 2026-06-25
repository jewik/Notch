import AppKit
import Foundation

struct HomeMediaItem: Equatable {
    var title: String
    var artist: String
    var sourceName: String?
    var artwork: NSImage?
    var isPlaying: Bool
    var hasContent: Bool

    static let empty = HomeMediaItem(
        title: "Nothing playing",
        artist: "Start media in any app",
        sourceName: nil,
        artwork: nil,
        isPlaying: false,
        hasContent: false
    )

    var subtitle: String {
        guard hasContent else { return artist }

        let author = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = sourceName?.trimmingCharacters(in: .whitespacesAndNewlines)

        switch (author.isEmpty, source?.isEmpty == false) {
        case (false, true):
            return "\(author) · \(source ?? "")"
        case (false, false):
            return author
        case (true, true):
            return source ?? ""
        case (true, false):
            return "Unknown author"
        }
    }

    static func == (lhs: HomeMediaItem, rhs: HomeMediaItem) -> Bool {
        lhs.title == rhs.title
            && lhs.artist == rhs.artist
            && lhs.sourceName == rhs.sourceName
            && lhs.artwork?.tiffRepresentation == rhs.artwork?.tiffRepresentation
            && lhs.isPlaying == rhs.isPlaying
            && lhs.hasContent == rhs.hasContent
    }
}
