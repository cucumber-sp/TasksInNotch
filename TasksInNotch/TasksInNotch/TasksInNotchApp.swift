//
//  TasksInNotchApp.swift
//  TasksInNotch
//
//  Created by Andrey Onischenko on 03.10.2026.
//

import SwiftUI

@main
struct TasksInNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        @Bindable var language = delegate.language

        MenuBarExtra("TasksInNotch", systemImage: "checklist") {
            Button(language.text("Today's tasks")) { delegate.toggleNotch() }
            Button(language.text("All tasks by date")) { delegate.showHistory() }
            Picker(language.text("Language"), selection: $language.language) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.name).tag(option)
                }
            }
            Divider()
            Button(language.text("Quit TasksInNotch")) { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
