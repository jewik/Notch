import AppKit
import Foundation
import UniformTypeIdentifiers

enum ClipboardContentKind: String, Codable, CaseIterable, Identifiable {
    case text
    case link
    case image
    case file
    case pdf
    case richText
    case other

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .text:
            "Text"
        case .link:
            "Link"
        case .image:
            "Image"
        case .file:
            "File"
        case .pdf:
            "PDF"
        case .richText:
            "Rich"
        case .other:
            "Other"
        }
    }

    nonisolated var systemImageName: String {
        switch self {
        case .text:
            "text.alignleft"
        case .link:
            "link"
        case .image:
            "photo"
        case .file:
            "doc"
        case .pdf:
            "doc.richtext"
        case .richText:
            "textformat"
        case .other:
            "shippingbox"
        }
    }

    nonisolated var isTextLike: Bool {
        switch self {
        case .text, .link, .richText:
            true
        case .image, .file, .pdf, .other:
            false
        }
    }
}

struct ClipboardCapture: Codable, Identifiable, Equatable {
    var id: UUID
    var createdAt: Date
    var lastCopiedAt: Date
    var sourceBundleIdentifier: String?
    var sourceApplicationName: String?
    var changeCount: Int
    var items: [ClipboardItem]
    var primaryKind: ClipboardContentKind
    var displayTitle: String
    var searchableText: String
    var exactHash: String
    var semanticHash: String
    var copyCount: Int
    var isPinned: Bool
    var totalByteCount: Int

    var itemCount: Int {
        items.count
    }
}

struct ClipboardItem: Codable, Identifiable, Equatable {
    var id: UUID
    var index: Int
    var kind: ClipboardContentKind
    var title: String
    var subtitle: String
    var representations: [ClipboardRepresentation]
}

struct ClipboardRepresentation: Codable, Identifiable, Equatable {
    var id: UUID
    var typeIdentifier: String
    var data: Data
    var size: Int
    var canIndexSafely: Bool

    init(typeIdentifier: String, data: Data, canIndexSafely: Bool) {
        self.id = UUID()
        self.typeIdentifier = typeIdentifier
        self.data = data
        self.size = data.count
        self.canIndexSafely = canIndexSafely
    }

    nonisolated var pasteboardType: NSPasteboard.PasteboardType {
        NSPasteboard.PasteboardType(typeIdentifier)
    }

    nonisolated var uniformType: UTType? {
        UTType(typeIdentifier)
    }
}

extension ClipboardCapture {
    var preferredDisplayTitle: String {
        if let title = items.first(where: { $0.kind.isTextLike })?.preferredDisplayTitle, !title.isEmpty {
            return title
        }
        if let title = items.first?.preferredDisplayTitle, !title.isEmpty {
            return title
        }
        if !searchableText.isEmpty {
            return ClipboardTitleFormatter.normalized(searchableText, limit: 90)
        }
        return "\(items.count) item\(items.count == 1 ? "" : "s")"
    }

    var primaryTextRepresentation: ClipboardRepresentation? {
        for item in items {
            if let representation = item.representations.first(where: { $0.isPlainText }) {
                return representation
            }
        }
        return nil
    }

    var primaryImageRepresentation: ClipboardRepresentation? {
        for item in items {
            if let representation = item.representations.first(where: { $0.isImage }) {
                return representation
            }
        }
        return nil
    }

    var primaryFileURLs: [URL] {
        items.flatMap { item in
            item.representations.compactMap { representation in
                guard representation.isFileURL else { return nil }
                return representation.fileURL
            }
        }
    }

    var matchesPinnedFilter: Bool {
        isPinned
    }

    var hasRawTextFormatting: Bool {
        items.contains { item in
            item.kind.isTextLike &&
                item.representations.contains(where: { $0.isFormattedText })
        }
    }
}

extension ClipboardItem {
    var preferredDisplayTitle: String {
        ClipboardTitleFormatter.title(for: representations, kind: kind)
    }

    nonisolated var plainTextForPaste: String? {
        let directText = representations
            .filter { $0.isPastePlainText || $0.isURL }
            .compactMap(\.decodedText)
            .first

        if let directText {
            return directText
        }

        return representations
            .filter(\.isFormattedText)
            .compactMap(\.renderedPlainText)
            .first
    }
}

extension ClipboardRepresentation {
    nonisolated var isPastePlainText: Bool {
        typeIdentifier == NSPasteboard.PasteboardType.string.rawValue ||
            (uniformType?.conforms(to: .plainText) == true && !isMarkupText && !isFileURL)
    }

    nonisolated var isPlainText: Bool {
        typeIdentifier == NSPasteboard.PasteboardType.string.rawValue ||
            uniformType?.conforms(to: .plainText) == true ||
            uniformType?.conforms(to: .text) == true
    }

    nonisolated var isDisplayText: Bool {
        typeIdentifier == NSPasteboard.PasteboardType.string.rawValue ||
            (uniformType?.conforms(to: .plainText) == true && !isMarkupText && !isFileURL && !isURL)
    }

    nonisolated var isRichText: Bool {
        typeIdentifier == NSPasteboard.PasteboardType.rtf.rawValue ||
            typeIdentifier == NSPasteboard.PasteboardType.rtfd.rawValue ||
            uniformType?.conforms(to: .rtf) == true ||
            uniformType?.conforms(to: .html) == true
    }

    nonisolated var isFormattedText: Bool {
        isRichText
    }

    nonisolated var hasRenderedTextContent: Bool {
        guard let text = renderedPlainText else {
            return false
        }

        return text.contains { character in
            !character.isWhitespace && character != "\u{fffc}"
        }
    }

    nonisolated var isMarkupText: Bool {
        let lowercasedType = typeIdentifier.lowercased()
        return typeIdentifier == NSPasteboard.PasteboardType.rtf.rawValue ||
            typeIdentifier == NSPasteboard.PasteboardType.rtfd.rawValue ||
            uniformType?.conforms(to: .rtf) == true ||
            uniformType?.conforms(to: .html) == true ||
            uniformType?.conforms(to: .xml) == true ||
            lowercasedType.contains("html") ||
            lowercasedType.contains("xml")
    }

    nonisolated var isImage: Bool {
        typeIdentifier == NSPasteboard.PasteboardType.png.rawValue ||
            typeIdentifier == NSPasteboard.PasteboardType.tiff.rawValue ||
            uniformType?.conforms(to: .image) == true
    }

    nonisolated var isPDF: Bool {
        typeIdentifier == NSPasteboard.PasteboardType.pdf.rawValue ||
            uniformType?.conforms(to: .pdf) == true
    }

    nonisolated var isFileURL: Bool {
        typeIdentifier == NSPasteboard.PasteboardType.fileURL.rawValue ||
            uniformType?.conforms(to: .fileURL) == true
    }

    nonisolated var isURL: Bool {
        !isFileURL && uniformType?.conforms(to: .url) == true
    }

    nonisolated var decodedText: String? {
        if let value = String(data: data, encoding: .utf8) {
            return value
        }
        if let value = String(data: data, encoding: .utf16) {
            return value
        }
        if let value = String(data: data, encoding: .utf16LittleEndian) {
            return value
        }
        if let value = String(data: data, encoding: .utf16BigEndian) {
            return value
        }
        return nil
    }

    nonisolated var renderedPlainText: String? {
        if isPastePlainText || isURL {
            return decodedText
        }

        let documentType: NSAttributedString.DocumentType?
        if typeIdentifier == NSPasteboard.PasteboardType.rtf.rawValue ||
            uniformType?.conforms(to: .rtf) == true {
            documentType = .rtf
        } else if typeIdentifier == NSPasteboard.PasteboardType.rtfd.rawValue {
            documentType = .rtfd
        } else if uniformType?.conforms(to: .html) == true ||
                    typeIdentifier.lowercased().contains("html") {
            documentType = .html
        } else {
            documentType = nil
        }

        if let documentType,
           let attributedString = try? NSAttributedString(
               data: data,
               options: [
                   .documentType: documentType,
                   .characterEncoding: String.Encoding.utf8.rawValue,
               ],
               documentAttributes: nil
           ) {
            return attributedString.string
        }

        guard isMarkupText, let text = decodedText else {
            return nil
        }

        return ClipboardTitleFormatter.markupText(text)
    }

    nonisolated var fileURL: URL? {
        guard let text = decodedText else { return nil }
        return URL(string: text)
    }
}

enum ClipboardTitleFormatter {
    nonisolated static func title(
        for representations: [ClipboardRepresentation],
        kind: ClipboardContentKind
    ) -> String {
        switch kind {
        case .file:
            return fileTitle(for: representations) ?? kind.title
        case .link:
            return linkTitle(for: representations) ??
                textTitle(for: representations, allowURLText: true) ??
                kind.title
        case .text, .richText:
            return textTitle(for: representations, allowURLText: false) ??
                textTitle(for: representations, allowURLText: true) ??
                renderedMarkupTitle(for: representations) ??
                kind.title
        case .image, .pdf:
            return kind.title
        case .other:
            return textTitle(for: representations, allowURLText: true) ??
                representations.first?.typeIdentifier ??
                kind.title
        }
    }

    nonisolated static func hasNonURLDisplayText(in representations: [ClipboardRepresentation]) -> Bool {
        textTitle(for: representations, allowURLText: false) != nil
    }

    nonisolated static func hasLink(in representations: [ClipboardRepresentation]) -> Bool {
        linkTitle(for: representations) != nil
    }

    nonisolated static func normalized(_ text: String, limit: Int) -> String {
        let normalized = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String(normalized.prefix(limit))
    }

    nonisolated private static func fileTitle(for representations: [ClipboardRepresentation]) -> String? {
        let fileNames = representations
            .compactMap(\.fileURL)
            .map(\.lastPathComponent)
            .filter { !$0.isEmpty }
        guard !fileNames.isEmpty else { return nil }
        return fileNames.joined(separator: ", ")
    }

    nonisolated private static func linkTitle(for representations: [ClipboardRepresentation]) -> String? {
        if let explicitURL = representations
            .first(where: { $0.isURL })?
            .decodedText {
            return normalized(explicitURL, limit: 90)
        }

        return representations
            .filter { $0.isDisplayText }
            .compactMap(\.decodedText)
            .map { normalized($0, limit: 90) }
            .first(where: isURLText)
    }

    nonisolated private static func textTitle(
        for representations: [ClipboardRepresentation],
        allowURLText: Bool
    ) -> String? {
        representations
            .filter(\.isDisplayText)
            .compactMap(\.decodedText)
            .map { normalized($0, limit: 90) }
            .first { !$0.isEmpty && (allowURLText || !isURLText($0)) }
    }

    nonisolated private static func renderedMarkupTitle(
        for representations: [ClipboardRepresentation]
    ) -> String? {
        representations
            .filter(\.isMarkupText)
            .compactMap(\.decodedText)
            .map(markupText)
            .map { normalized($0, limit: 90) }
            .first { !$0.isEmpty }
    }

    nonisolated static func markupText(_ text: String) -> String {
        let withoutTags = text.replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )
        return withoutTags
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }

    nonisolated private static func isURLText(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.contains(where: { $0.isWhitespace }),
              let url = URL(string: trimmed) else {
            return false
        }
        return url.scheme != nil
    }
}
