import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("🐈")
                .font(.system(size: 72))
                .accessibilityLabel("Cat placeholder")

            Text("Thread Cat")
                .font(.largeTitle.bold())

            Text("A little place for your stray thoughts.")
                .foregroundStyle(.secondary)

            Text("Your cat is here. Thought capture comes next.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(minWidth: 380, minHeight: 280)
    }
}
