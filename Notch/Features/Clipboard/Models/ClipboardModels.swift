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

    var id: String { rawValue }

    var title: String {
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

    var systemImageName: String {
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

    var pasteboardType: NSPasteboard.PasteboardType {
        NSPasteboard.PasteboardType(typeIdentifier)
    }

    var uniformType: UTType? {
        UTType(typeIdentifier)
    }
}

extension ClipboardCapture {
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
}

extension ClipboardRepresentation {
    var isPlainText: Bool {
        typeIdentifier == NSPasteboard.PasteboardType.string.rawValue ||
            uniformType?.conforms(to: .plainText) == true ||
            uniformType?.conforms(to: .text) == true
    }

    var isRichText: Bool {
        typeIdentifier == NSPasteboard.PasteboardType.rtf.rawValue ||
            typeIdentifier == NSPasteboard.PasteboardType.rtfd.rawValue ||
            uniformType?.conforms(to: .rtf) == true ||
            uniformType?.conforms(to: .html) == true
    }

    var isImage: Bool {
        typeIdentifier == NSPasteboard.PasteboardType.png.rawValue ||
            typeIdentifier == NSPasteboard.PasteboardType.tiff.rawValue ||
            uniformType?.conforms(to: .image) == true
    }

    var isPDF: Bool {
        typeIdentifier == NSPasteboard.PasteboardType.pdf.rawValue ||
            uniformType?.conforms(to: .pdf) == true
    }

    var isFileURL: Bool {
        typeIdentifier == NSPasteboard.PasteboardType.fileURL.rawValue ||
            uniformType?.conforms(to: .fileURL) == true
    }

    var decodedText: String? {
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

    var fileURL: URL? {
        guard let text = decodedText else { return nil }
        return URL(string: text)
    }
}
