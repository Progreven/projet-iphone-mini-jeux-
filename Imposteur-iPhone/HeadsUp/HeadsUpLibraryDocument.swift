import SwiftUI
import UniformTypeIdentifiers

struct HeadsUpLibraryDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var names: [String]

    init(names: [String]) {
        self.names = names
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        if let decoded = try? JSONDecoder().decode([String].self, from: data) {
            names = decoded
            return
        }
        if let decodedEntries = try? JSONDecoder().decode([HeadsUpEntry].self, from: data) {
            names = decodedEntries.map(\.name)
            return
        }

        throw CocoaError(.fileReadCorruptFile)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let clean = HeadsUpLogic.cleanedNames(names)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(clean)
        return FileWrapper(regularFileWithContents: data)
    }
}
