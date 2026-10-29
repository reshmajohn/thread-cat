# Thread Cat

A native macOS app for catching stray thoughts, starting with a small cat.
The current milestone is a runnable window with an emoji cat placeholder.

## Run

Open `ThreadCat.xcodeproj` in Xcode, select the **ThreadCat** scheme and **My Mac**, then press **⌘R**. Quit with **⌘Q** or **Thread Cat → Quit Thread Cat**.

From the VS Code terminal, build with:

```sh
xcodebuild -project ThreadCat.xcodeproj -scheme ThreadCat -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/ThreadCat.app
```

Requires Xcode with the macOS SDK. The deployment target (oldest macOS version we intend to support) is macOS 14. Only the current development Mac has been checked; older-system compatibility is not verified. Local builds use ad hoc signing and need no paid developer account. Distribution signing is a later step.

## Small steps

- `ThreadCat/ThreadCatApp.swift`: the app entry point and window.
- `ThreadCat/ContentView.swift`: the window's SwiftUI contents.
- [Project status](thread-cat-handoff/PROJECT_STATUS.md): verified progress and next step.
- [Handoff](thread-cat-handoff/README.md): product intent and reference documents.

Next: capture and display thoughts in memory. Local saving follows in its own milestone. Idea Compost and ML stay later in the roadmap. No Python packages or external dependencies are needed.

Suggested first commit: `feat: launch minimal macOS app with cat placeholder`.
Review and commit the source and documentation; `build/`, Xcode personal settings, and the existing Python environment are ignored.
