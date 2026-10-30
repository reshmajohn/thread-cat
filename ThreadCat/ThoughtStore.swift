import Foundation
import Observation

// All windows use this store. MainActor keeps their load/save actions in order.
@MainActor
@Observable
final class ThoughtStore {
    private(set) var thoughts: [Thought] = []
    private(set) var errorMessage: String?
    private(set) var hasLoadError = false

    private let fileURL: URL

    init(fileURL: URL = URL.applicationSupportDirectory.appending(path: "ThreadCat/thoughts.json")) {
        self.fileURL = fileURL
        load()
    }

    // Return success so the view only clears a draft after it is safely saved.
    func capture(_ draft: String) -> Bool {
        guard !hasLoadError else { return false }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }

        let updatedThoughts = [Thought(text: text)] + thoughts
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(SavedThoughts(version: 1, thoughts: updatedThoughts))
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            // Write a temporary file, then replace the old file as one operation.
            try data.write(to: fileURL, options: .atomic)
            thoughts = updatedThoughts
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Couldn’t save your thought. Your draft is still here; try catching it again. \(error.localizedDescription)"
            return false
        }
    }

    func retryLoading() {
        load()
    }

    private func load() {
        do {
            let data: Data
            do {
                data = try Data(contentsOf: fileURL)
            } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
                // A missing file is normal on first launch; other read errors are not.
                thoughts = []
                hasLoadError = false
                errorMessage = nil
                return
            }

            let saved = try JSONDecoder().decode(SavedThoughts.self, from: data)
            guard saved.version == 1 else { throw SavedFileError.unsupportedVersion(saved.version) }
            guard Set(saved.thoughts.map(\.id)).count == saved.thoughts.count else {
                throw SavedFileError.duplicateIDs
            }
            thoughts = saved.thoughts
            hasLoadError = false
            errorMessage = nil
        } catch {
            // Never overwrite an unreadable file with an empty collection.
            hasLoadError = true
            errorMessage = "Couldn’t open saved thoughts. Capture is paused to protect the file. \(error.localizedDescription)"
        }
    }
}

private struct SavedThoughts: Codable {
    let version: Int
    let thoughts: [Thought]
}

private enum SavedFileError: LocalizedError {
    case unsupportedVersion(Int)
    case duplicateIDs

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            "This file uses an unsupported storage version (\(version))."
        case .duplicateIDs:
            "The saved file contains repeated thought IDs."
        }
    }
}
