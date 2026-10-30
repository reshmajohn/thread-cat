import Foundation

struct Thought: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date

    init(text: String) {
        id = UUID()
        self.text = text
        createdAt = Date()
    }
}
