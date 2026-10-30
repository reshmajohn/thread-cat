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

        return save(
            [Thought(text: text)] + thoughts,
            failureMessage: "Couldn’t save your thought. Your draft is still here; try catching it again."
        )
    }

    func setCompleted(_ completed: Bool, for id: UUID) -> Bool {
        guard !hasLoadError,
              let index = thoughts.firstIndex(where: { $0.id == id }) else { return false }
        guard thoughts[index].isCompleted != completed else { return true }

        var updatedThoughts = thoughts
        updatedThoughts[index].completedAt = completed ? Date() : nil
        return save(
            updatedThoughts,
            failureMessage: "Couldn’t change completion. The thought is unchanged; try again."
        )
    }

    private func save(_ updatedThoughts: [Thought], failureMessage: String) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(SavedThoughts(version: 2, thoughts: updatedThoughts))
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
            errorMessage = "\(failureMessage) \(error.localizedDescription)"
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
            // Version 1 has no completion dates. Codable reads those missing values as nil.
            guard saved.version == 1 || saved.version == 2 else {
                throw SavedFileError.unsupportedVersion(saved.version)
            }
            guard Set(saved.thoughts.map(\.id)).count == saved.thoughts.count else {
                throw SavedFileError.duplicateIDs
            }
            thoughts = saved.thoughts
            hasLoadError = false
            errorMessage = nil
        } catch {
            // Never overwrite an unreadable file with an empty collection.
            hasLoadError = true
            errorMessage = "Couldn’t open saved thoughts. Changes are paused to protect the file. \(error.localizedDescription)"
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
