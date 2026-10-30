# Thread Cat

A native macOS app for catching stray thoughts, starting with a small cat.
Type a thought and press Enter or click **Catch thought**. Thoughts appear newest first below the emoji cat; blank input is ignored. They are saved locally and return when you reopen the app.

## Run

Open `ThreadCat.xcodeproj` in Xcode, select the **ThreadCat** scheme and **My Mac**, then press **⌘R**. Quit with **⌘Q** or **Thread Cat → Quit Thread Cat**.

From the VS Code terminal, quit any running copy of Thread Cat, then build and open the app:

```sh
xcodebuild -project ThreadCat.xcodeproj -scheme ThreadCat -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath build build
open build/Build/Products/Debug/ThreadCat.app
```

Requires Xcode with the macOS SDK. The deployment target (oldest macOS version we intend to support) is macOS 14. Only the current development Mac has been checked; older-system compatibility is not verified. Local builds use ad hoc signing and need no paid developer account. Distribution signing is a later step.

## Check capture

1. Enter a thought and press Enter. It should appear once and the field should clear.
2. Add another with **Catch thought**. It should appear above the first.
3. Try empty input and spaces. The button should be disabled and Enter should add nothing.
4. Capture the same text twice. Both entries should be visible.
5. Quit and reopen the app. Your thoughts should still appear in the same order.

Thoughts are stored in `ThreadCat/thoughts.json` inside the app's Application Support folder. For this sandboxed build, that is `~/Library/Containers/dev.threadcat.ThreadCat/Data/Library/Application Support/ThreadCat/thoughts.json`, outside the repository.

If saving fails, the app keeps your draft and shows an error so you can retry. If a saved file cannot be read, capture pauses to protect it; **Retry loading** tries again after the file problem is resolved.

## Small steps

- `ThreadCat/ThreadCatApp.swift`: starts the app and owns the store shared by its windows.
- `ThreadCat/Thought.swift`: a thought's text, ID, and creation time, with support for saving and loading.
- `ThreadCat/ThoughtStore.swift`: loads the collection and saves each successful capture to a versioned JSON file.
- `ThreadCat/ContentView.swift`: keeps the current draft, handles submission, and displays the list.
- [Project status](thread-cat-handoff/PROJECT_STATUS.md): verified progress and next step.
- [Handoff](thread-cat-handoff/README.md): product intent and reference documents.
- [Git guide](GIT_GUIDE.md): VS Code and terminal workflows, with command explanations.

Run the persistence checks from the repository root with `sh Tests/run-checks.sh`. They use temporary files to check saved-data round trips and failure recovery without changing the app's thoughts.

Next: mark captured thoughts as complete and save that change. Idea Compost and ML stay later in the roadmap. No Python packages or external dependencies are needed.

Suggested commit for this stage: `feat: persist captured thoughts locally`.
