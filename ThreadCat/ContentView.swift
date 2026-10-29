import SwiftUI

// A unique ID lets the list distinguish thoughts even when their text is identical.
struct Thought: Identifiable {
    let id = UUID()
    let text: String
}

struct ContentView: View {
    @Binding var thoughts: [Thought]
    @State private var draft = ""

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Text("🐈")
                    .font(.system(size: 48))
                    .accessibilityLabel("Cat placeholder")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Thread Cat")
                        .font(.largeTitle.bold())

                    Text("A little place for your stray thoughts.")
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                TextField("What would you like the cat to hold?", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Thought")
                    .onSubmit(catchThought)

                Button("Catch thought", action: catchThought)
                    .disabled(trimmedDraft.isEmpty)
            }

            Text("Thoughts stay in memory until you quit the app.")
                .font(.callout)
                .foregroundStyle(.secondary)

            if thoughts.isEmpty {
                Text("No thoughts caught yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(thoughts) { thought in
                    Text(thought.text)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
        }
        .padding(24)
        .frame(minWidth: 460, minHeight: 360)
    }

    private func catchThought() {
        let text = trimmedDraft
        guard !text.isEmpty else { return }

        thoughts.insert(Thought(text: text), at: 0)
        draft = ""
    }
}
