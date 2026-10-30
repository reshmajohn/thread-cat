import Foundation

struct Thought: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date
    var completedAt: Date?

    var isCompleted: Bool {
        completedAt != nil
    }

    init(text: String) {
        id = UUID()
        self.text = text
        createdAt = Date()
        completedAt = nil
    }
}
