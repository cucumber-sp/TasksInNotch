import AppKit
import SwiftData
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let language = LanguageSettings()
    private var store: TaskStore?
    private var notchController: NotchController?
    private var historyController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        do {
            let configuration = ModelConfiguration("Tasks", cloudKitDatabase: .none)
            let container = try ModelContainer(for: TodoTask.self, configurations: configuration)
            let store = try TaskStore(container: container)
            self.store = store
            let controller = NotchController(store: store, language: language) { [weak self] in self?.showHistory() }
            notchController = controller
            controller.start()
        } catch {
            NSApplication.shared.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = language.text("Unable to open tasks")
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: language.text("Quit"))
            alert.runModal()
            NSApplication.shared.terminate(nil)
        }
    }

    func applicationDidResignActive(_ notification: Notification) {
        notchController?.collapse()
    }

    func applicationWillTerminate(_ notification: Notification) {
        notchController?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func toggleNotch() {
        notchController?.toggle()
    }

    func showHistory() {
        guard let store else { return }
        notchController?.collapse()
        if historyController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "TasksInNotch"
            window.contentViewController = NSHostingController(rootView: HistoryView(store: store, language: language))
            window.contentMinSize = NSSize(width: 440, height: 380)
            window.isReleasedWhenClosed = false
            window.setFrameAutosaveName("TaskHistory")
            window.center()
            historyController = NSWindowController(window: window)
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        historyController?.showWindow(nil)
        historyController?.window?.makeKeyAndOrderFront(nil)
    }
}
