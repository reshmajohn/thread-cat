import SwiftUI

// The app entry point. WindowGroup supplies standard Mac window and menu behavior.
@main
struct ThreadCatApp: App {
    @State private var thoughts: [Thought] = []

    var body: some Scene {
        WindowGroup("Thread Cat") {
            ContentView(thoughts: $thoughts)
        }
        .defaultSize(width: 520, height: 460)
    }
}
