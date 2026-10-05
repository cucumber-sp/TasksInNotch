# TasksInNotch

[English](README.md) | [Русский](README.ru.md)

A native macOS task tracker in your MacBook's notch. Keep a simple daily to-do list,
check your progress on hover, and browse completed tasks by date.

Built with SwiftUI and SwiftData. [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit)
provides the panel geometry, positioning, and animations. The dependency is pinned to **1.1.0**.

## Interaction

- **At rest:** the task counter and progress ring are hidden, and their content width collapses.
- **Hover:** the kit's native enlargement reveals completed / total tasks on the left and a progress ring on the right.
  Hovering does not open the list or take keyboard focus.
- **Click the top of the notch:** toggle the task list. Opening the panel focuses the input field.
- **Click outside or switch apps:** collapse the panel.
- **Task list:** unfinished tasks for today, with a fixed height of six rows and scrolling for more.
- **Complete a task:** click its row. Completed tasks remain in history and can be marked unfinished again.
- **Add a task:** enter a single-line title and press **Return** or **+**. Blank input is ignored.
- **History:** the calendar button opens all tasks for the selected date. Use the date field or arrows to switch days.
- **Delete a task:** use its context menu.

With no unfinished tasks, the panel shows “All tasks for today are complete.” Tasks stay on their assigned dates;
unfinished tasks do not automatically move to the next day.

The app runs without a Dock icon. Its menu bar menu opens tasks and history, selects a language, and quits the app.
Displays without a notch use the kit's floating panel, opened from the menu.

## Languages

**English** is the default. Select **Language → Русский** in the app's menu bar menu to switch to Russian.
The preference is saved and updates views, controls, dates, and accessibility labels. Task titles stay as entered.

## Requirements

- **macOS 14+** to run the app.
- **Xcode 26+** to build the current project.
- A MacBook with a notch for the notch interface; other displays use a floating panel.

Verified on Apple Silicon with Xcode 26.6 and macOS 26.6.2. Release builds include Apple Silicon and Intel.

## Run in Xcode

```sh
git clone https://github.com/cucumber-sp/TasksInNotch.git
cd TasksInNotch
open TasksInNotch/TasksInNotch.xcodeproj
```

1. Wait for Swift Package Dependencies to resolve.
2. Select the **TasksInNotch** scheme and **My Mac**.
3. Select your own development team under **Signing & Capabilities**.
4. Press **⌘R**, then hover over or click the notch.

### Release build

For a local Release build with an ad hoc signature:

```sh
xcodebuild \
  -project TasksInNotch/TasksInNotch.xcodeproj \
  -scheme TasksInNotch \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath .build/xcode \
  build CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

Copy `.build/xcode/Build/Products/Release/TasksInNotch.app` to `/Applications` to run it without Xcode.

## Local storage

SwiftData stores tasks in the app's local container. Each addition, completion change, and deletion is saved
immediately. CloudKit is disabled; no account or server is required.

Dates are calendar days; progress includes completed and unfinished tasks. The original bundle identifier,
`com.cucumberspace.NotchTasks`, is retained so renaming the app preserves the existing data container.

## Project structure

Sources are under `TasksInNotch/TasksInNotch/`.

| File | Purpose |
| --- | --- |
| `TasksInNotchApp.swift` | App entry point and menu bar menu |
| `AppDelegate.swift` | App lifecycle, storage, and history window |
| `NotchController.swift` | Clicks, keyboard focus, and the kit's hover state |
| `TaskViews.swift` | Counter, progress ring, list, and input |
| `HistoryView.swift` | All tasks and date navigation |
| `AppLanguage.swift` | Language preference and localized strings |
| `TaskStore.swift` | Task operations and persistence |
| `TodoTask.swift` | Task model and daily progress |

The panel shape and expansion animations remain inside DynamicNotchKit.

The main app icon is `TasksInNotch/TasksInNotch/tasksinnotch.icon`, an editable
[Icon Composer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)
document. The App Icon build setting is `tasksinnotch` in both Debug and Release.

## Verification

Three `TasksInNotchTests` tests cover daily progress and date separation, single-line input and deletion,
and reopening a file-backed SwiftData store. Current test targets require **macOS 26.5+**.

```sh
xcodebuild \
  -project TasksInNotch/TasksInNotch.xcodeproj \
  -scheme TasksInNotch \
  -destination 'platform=macOS' \
  -derivedDataPath .build/xcode \
  -only-testing:TasksInNotchTests \
  -parallel-testing-enabled NO \
  test CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

Hover, click, keyboard focus, language switching, and collapse are checked in the running app.
The original Xcode UI-test templates do not cover notch interactions yet.
