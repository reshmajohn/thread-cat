import SwiftUI

// The app entry point. WindowGroup supplies standard Mac window and menu behavior.
@main
struct ThreadCatApp: App {
    @State private var store = ThoughtStore()

    var body: some Scene {
        WindowGroup("Thread Cat") {
            ContentView(store: store)
        }
        .defaultSize(width: 520, height: 460)
    }
}
