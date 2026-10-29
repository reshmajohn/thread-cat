import SwiftUI

// The app entry point. WindowGroup supplies standard Mac window and menu behavior.
@main
struct ThreadCatApp: App {
    var body: some Scene {
        WindowGroup("Thread Cat") {
            ContentView()
        }
        .defaultSize(width: 420, height: 320)
    }
}
