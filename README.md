# Thread Cat

A native macOS app for catching stray thoughts, starting with a small cat.
Type a thought and press Enter or click **Catch thought**. Thoughts appear newest first below the emoji cat; blank input is ignored. They are saved locally and return when you reopen the app.

Click the circle beside a thought to mark it complete and hide it from the active list. Turn on **Show completed** to see finished thoughts with a checkmark and crossed-out text. Click a checked circle to reopen a thought. Completion is saved too; opening the app starts with the active list.

## Run

Open `ThreadCat.xcodeproj` in Xcode, select the **ThreadCat** scheme and **My Mac**, then press **⌘R**. Quit with **⌘Q** or **Thread Cat → Quit Thread Cat**.

From the VS Code terminal, quit any running copy of Thread Cat, then build and open the app:

```sh
xcodebuild -project ThreadCat.xcodeproj -scheme ThreadCat -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath build build
open build/Build/Products/Debug/ThreadCat.app
```

Requires Xcode with the macOS SDK. The deployment target (oldest macOS version we intend to support) is macOS 14. Only the current development Mac has been checked; older-system compatibility is not verified. Local builds use ad hoc signing and need no paid developer account. Distribution signing is a later step.

## Check capture and completion

1. Enter a thought and press Enter. It should appear once and the field should clear.
2. Add another with **Catch thought**. It should appear above the first.
3. Try empty input and spaces. The button should be disabled and Enter should add nothing.
4. Capture the same text twice. Both entries should be visible.
5. Complete one thought. It should disappear from the active list; an identical-text thought should stay unfinished.
6. Turn on **Show completed** and reopen the finished thought by clicking its checkmark. It should return to its original place among the unfinished thoughts.
7. Complete a thought again, then quit and reopen the app. Unfinished thoughts should remain in order; **Show completed** should reveal the finished thought still checked.

Thoughts are stored in `ThreadCat/thoughts.json` inside the app's Application Support folder. For this sandboxed build, that is `~/Library/Containers/dev.threadcat.ThreadCat/Data/Library/Application Support/ThreadCat/thoughts.json`, outside the repository.

If saving a capture fails, the app keeps your draft; if saving completion fails, the thought stays as it was. An error explains that you can retry. If a saved file cannot be read, changes pause to protect it; **Retry loading** tries again after the file problem is resolved.

Existing version-1 files load with every thought unfinished. The next successful change writes version 2, which includes completion dates and protects them from being silently discarded by an older build.

## Small steps

- `ThreadCat/ThreadCatApp.swift`: starts the app and owns the store shared by its windows.
- `ThreadCat/Thought.swift`: a thought's text, ID, creation time, and optional completion date, with support for saving and loading.
- `ThreadCat/ThoughtStore.swift`: loads the collection and saves captures and completion changes to a versioned JSON file.
- `ThreadCat/ContentView.swift`: keeps the current draft, handles submission, and displays the list.
- [Project status](thread-cat-handoff/PROJECT_STATUS.md): verified progress and next step.
- [Handoff](thread-cat-handoff/README.md): product intent and reference documents.
- [Git guide](GIT_GUIDE.md): VS Code and terminal workflows, with command explanations.

Run the persistence checks from the repository root with `sh Tests/run-checks.sh`. They use temporary files to check saved-data round trips and failure recovery without changing the app's thoughts.

Next: open capture through a global keyboard shortcut. Idea Compost and ML stay later in the roadmap. No Python packages or external dependencies are needed.

Suggested commit for this stage: `feat: complete and reopen captured thoughts`.
