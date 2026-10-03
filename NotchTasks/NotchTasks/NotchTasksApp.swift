//
//  NotchTasksApp.swift
//  NotchTasks
//
//  Created by Andrey Onischenko on 03.10.2026.
//

import SwiftUI

@main
struct NotchTasksApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("Notch Tasks", systemImage: "checklist") {
            Button("Задачи на сегодня") { delegate.toggleNotch() }
            Button("Все задачи по датам") { delegate.showHistory() }
            Divider()
            Button("Выйти из Notch Tasks") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
