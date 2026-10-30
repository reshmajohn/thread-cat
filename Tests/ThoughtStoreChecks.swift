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

        // Recreate the old version-1 shape to check upgrading real existing collections.
        let legacyURL = root.appending(path: "legacy.json")
        var legacyDocument = try JSONSerialization.jsonObject(with: validData) as! [String: Any]
        legacyDocument["version"] = 1
        let legacyData = try JSONSerialization.data(withJSONObject: legacyDocument)
        try legacyData.write(to: legacyURL)
        let legacyStore = ThoughtStore(fileURL: legacyURL)
        try expect(!legacyStore.hasLoadError && legacyStore.thoughts == store.thoughts, "Version 1 should load with every thought unfinished")
        try expect(try Data(contentsOf: legacyURL) == legacyData, "Loading an old file should not rewrite it")
        let completedID = legacyStore.thoughts[0].id
        try expect(legacyStore.setCompleted(true, for: completedID), "Completion should save")
        try expect(legacyStore.thoughts[0].completedAt != nil, "Completion should record a date")
        try expect(!legacyStore.thoughts[1].isCompleted, "Completing one duplicate text must not complete another")
        try expect(legacyStore.thoughts.map(\.id) == store.thoughts.map(\.id), "Completion should preserve IDs and order")
        try expect(legacyStore.thoughts.map(\.createdAt) == store.thoughts.map(\.createdAt), "Completion should preserve creation times")
        let completedData = try Data(contentsOf: legacyURL)
        let upgradedDocument = try JSONSerialization.jsonObject(with: completedData) as! [String: Any]
        try expect(upgradedDocument["version"] as? Int == 2, "A successful change should upgrade storage to version 2")
        let completedStore = ThoughtStore(fileURL: legacyURL)
        try expect(completedStore.thoughts == legacyStore.thoughts, "Completion dates should survive reload")
        try expect(completedStore.setCompleted(true, for: completedID), "Repeated completion should be harmless")
        try expect(try Data(contentsOf: legacyURL) == completedData, "Repeated completion should not replace its date or rewrite the file")
        try expect(completedStore.capture("Another capture"), "Capture should still work after completing a thought")
        try expect(completedStore.thoughts[1] == legacyStore.thoughts[0], "A new capture should retain existing completion")
        try expect(completedStore.setCompleted(false, for: completedID), "Reopening should save")
        let reopenedStore = ThoughtStore(fileURL: legacyURL)
        try expect(reopenedStore.thoughts.allSatisfy { !$0.isCompleted }, "Reopening should survive reload without deleting thoughts")
        try expect(reopenedStore.thoughts.count == 4, "Complete/reopen should retain every record")
        let unchangedData = try Data(contentsOf: legacyURL)
        try expect(!reopenedStore.setCompleted(true, for: UUID()), "A missing ID should not change another thought")
        try expect(try Data(contentsOf: legacyURL) == unchangedData, "A missing ID should leave the saved file unchanged")
        print("PASS: version-1 upgrade, completion/reopen round trips, duplicate independence, and stable IDs/order/dates")

        let brokenURL = root.appending(path: "broken.json")
        let brokenData = Data("not valid JSON".utf8)
        try brokenData.write(to: brokenURL)
        let brokenStore = ThoughtStore(fileURL: brokenURL)
        try expect(brokenStore.hasLoadError && brokenStore.errorMessage != nil, "Invalid JSON should show an error")
        try expect(!brokenStore.capture("Must not overwrite"), "Capture should pause after a load failure")
        try expect(!brokenStore.setCompleted(true, for: completedID), "Completion should pause after a load failure")
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
        let blockedID = previousThoughts[0].id
        try expect(!blockedStore.setCompleted(true, for: blockedID), "An unwritable directory should fail to complete a thought")
        try expect(blockedStore.thoughts == previousThoughts, "Failed completion should leave the thought unfinished")
        try expect(try Data(contentsOf: blockedURL) == previousData, "Failed completion should preserve the saved file")
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: blockedDirectory.path)
        try expect(blockedStore.setCompleted(true, for: blockedID), "Completion should succeed once writing is restored")
        try expect(ThoughtStore(fileURL: blockedURL).thoughts[0].isCompleted, "Retried completion should persist")
        try expect(blockedStore.capture("Keep this draft"), "Capture should succeed once writing is restored")
        try expect(blockedStore.errorMessage == nil, "A successful retry should clear the save error")
        try expect(ThoughtStore(fileURL: blockedURL).thoughts.count == 2, "Retry should save exactly once")
        print("PASS: failed capture/completion protection and successful retries")
    }

    private static func expect(_ condition: Bool, _ message: String) throws {
        if !condition {
            throw NSError(domain: "ThoughtStoreChecks", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }
}
