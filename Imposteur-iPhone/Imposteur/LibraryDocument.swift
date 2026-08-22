import SwiftUI
import UniformTypeIdentifiers

struct LibraryDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var pairs: [WordPair]

    init(pairs: [WordPair]) {
        self.pairs = pairs
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        if let decoded = try? JSONDecoder().decode([WordPair].self, from: data) {
            pairs = decoded
            return
        }

        if let legacy = try? JSONDecoder().decode([[String]].self, from: data) {
            let converted = legacy.compactMap { row -> WordPair? in
                guard row.count == 2 else { return nil }
                return WordPair(first: row[0], second: row[1])
            }
            guard !converted.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
            pairs = converted
            return
        }

        throw CocoaError(.fileReadCorruptFile)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(pairs)
        return .init(regularFileWithContents: data)
    }
}
