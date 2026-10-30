import Foundation

// These checks use temporary files, never the app's real saved thoughts.
@main
struct ThoughtStoreChecks {
    @MainActor
    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "ThreadCatChecks-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let fileURL = root.appending(path: "round-trip/thoughts.json")
        let store = ThoughtStore(fileURL: fileURL)
        try expect(store.thoughts.isEmpty && store.errorMessage == nil, "First launch should be empty")
        try expect(!store.capture(" \n\t "), "Blank input should be ignored")
        try expect(!FileManager.default.fileExists(atPath: fileURL.path), "Blank input should not create a file")
        try expect(store.capture("  First thought  "), "First capture should save")
        try expect(store.capture("Second thought"), "Second capture should save")
        try expect(store.capture("Second thought"), "Duplicate text should be allowed")
        try expect(store.thoughts.map(\.text) == ["Second thought", "Second thought", "First thought"], "Order and trimming should be preserved")
        try expect(Set(store.thoughts.map(\.id)).count == 3, "Duplicate text should have distinct IDs")
        let reopened = ThoughtStore(fileURL: fileURL)
        try expect(reopened.thoughts == store.thoughts, "Text, order, IDs, and creation times should survive reload")
        print("PASS: first launch, blank input, ordered captures, duplicate IDs, and disk round trip")

        let validData = try Data(contentsOf: fileURL)
        let brokenURL = root.appending(path: "broken.json")
        let brokenData = Data("not valid JSON".utf8)
        try brokenData.write(to: brokenURL)
        let brokenStore = ThoughtStore(fileURL: brokenURL)
        try expect(brokenStore.hasLoadError && brokenStore.errorMessage != nil, "Invalid JSON should show an error")
        try expect(!brokenStore.capture("Must not overwrite"), "Capture should pause after a load failure")
        try expect(try Data(contentsOf: brokenURL) == brokenData, "Invalid file must remain unchanged")
        try validData.write(to: brokenURL)
        brokenStore.retryLoading()
        try expect(!brokenStore.hasLoadError && brokenStore.errorMessage == nil, "Loading should recover after the file is repaired")
        try expect(brokenStore.thoughts == store.thoughts, "Retry should restore the saved thoughts")
        print("PASS: invalid JSON protection and load retry")

        let futureURL = root.appending(path: "future.json")
        let futureData = Data("{\"version\":99,\"thoughts\":[]}".utf8)
        try futureData.write(to: futureURL)
        let futureStore = ThoughtStore(fileURL: futureURL)
        try expect(futureStore.hasLoadError, "Unknown versions should be rejected")
        try expect(!futureStore.capture("Must not overwrite"), "Unknown versions should block writes")
        try expect(try Data(contentsOf: futureURL) == futureData, "Unknown-version file must remain unchanged")
        print("PASS: unsupported version protection")

        let duplicateURL = root.appending(path: "duplicate-ids.json")
        var duplicateDocument = try JSONSerialization.jsonObject(with: validData) as! [String: Any]
        let records = duplicateDocument["thoughts"] as! [[String: Any]]
        duplicateDocument["thoughts"] = [records[0], records[0]]
        let duplicateData = try JSONSerialization.data(withJSONObject: duplicateDocument)
        try duplicateData.write(to: duplicateURL)
        let duplicateStore = ThoughtStore(fileURL: duplicateURL)
        try expect(duplicateStore.hasLoadError, "Repeated IDs in a file should be rejected")
        try expect(!duplicateStore.capture("Must not overwrite"), "Repeated IDs should block writes")
        try expect(try Data(contentsOf: duplicateURL) == duplicateData, "Repeated-ID file must remain unchanged")
        print("PASS: repeated ID protection")

        let blockedDirectory = root.appending(path: "read-only")
        let blockedURL = blockedDirectory.appending(path: "thoughts.json")
        let blockedStore = ThoughtStore(fileURL: blockedURL)
        try expect(blockedStore.capture("Already saved"), "Initial save should succeed")
        let previousThoughts = blockedStore.thoughts
        let previousData = try Data(contentsOf: blockedURL)
        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: blockedDirectory.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: blockedDirectory.path) }
        try expect(!blockedStore.capture("Keep this draft"), "An unwritable directory should fail to save")
        try expect(blockedStore.errorMessage != nil, "A failed save should report an error")
        try expect(blockedStore.thoughts == previousThoughts, "A failed save should leave the list unchanged")
        try expect(try Data(contentsOf: blockedURL) == previousData, "A failed save should preserve the existing file")
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: blockedDirectory.path)
        try expect(blockedStore.capture("Keep this draft"), "Capture should succeed once writing is restored")
        try expect(blockedStore.errorMessage == nil, "A successful retry should clear the save error")
        try expect(ThoughtStore(fileURL: blockedURL).thoughts.count == 2, "Retry should save exactly once")
        print("PASS: failed-save protection and successful retry")
    }

    private static func expect(_ condition: Bool, _ message: String) throws {
        if !condition {
            throw NSError(domain: "ThoughtStoreChecks", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }
}
