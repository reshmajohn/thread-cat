import SwiftUI

struct ContentView: View {
    let store: ThoughtStore
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
                    .disabled(store.hasLoadError)

                Button("Catch thought", action: catchThought)
                    .disabled(trimmedDraft.isEmpty || store.hasLoadError)
            }

            Text("Thoughts are saved on this Mac.")
                .font(.callout)
                .foregroundStyle(.secondary)

            if let message = store.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text(message)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)

                    if store.hasLoadError {
                        Button("Retry loading") {
                            store.retryLoading()
                        }
                    }
                }
            }

            if store.thoughts.isEmpty && !store.hasLoadError {
                Text("No thoughts caught yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(store.thoughts) { thought in
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
        if store.capture(draft) {
            draft = ""
        }
    }
}
