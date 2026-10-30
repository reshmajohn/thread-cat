import SwiftUI

struct ContentView: View {
    let store: ThoughtStore
    @State private var draft = ""
    @State private var showCompleted = false

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Filtering only changes what is displayed; completed thoughts stay in the store.
    private var visibleThoughts: [Thought] {
        store.thoughts.filter { showCompleted || !$0.isCompleted }
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

            HStack {
                Text("Held thoughts")
                    .font(.headline)
                Spacer()
                Toggle("Show completed", isOn: $showCompleted)
                    .toggleStyle(.checkbox)
            }

            if visibleThoughts.isEmpty && !store.hasLoadError {
                Text(store.thoughts.isEmpty ? "No thoughts caught yet." : "All caught thoughts are complete.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(visibleThoughts) { thought in
                    HStack(alignment: .top, spacing: 10) {
                        Button {
                            _ = store.setCompleted(!thought.isCompleted, for: thought.id)
                        } label: {
                            Image(systemName: thought.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(thought.isCompleted ? "Reopen" : "Complete"): \(thought.text)")
                        .help(thought.isCompleted ? "Mark as unfinished" : "Mark as complete")
                        .disabled(store.hasLoadError)

                        Text(thought.text)
                            .strikethrough(thought.isCompleted)
                            .foregroundStyle(thought.isCompleted ? .secondary : .primary)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .contain)
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
