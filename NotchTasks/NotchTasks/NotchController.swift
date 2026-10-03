import AppKit
import DynamicNotchKit
import SwiftUI

/// Only controls interaction and focus. DynamicNotchKit owns the window,
/// notch geometry, native hover feedback, and all expansion animations.
@MainActor
final class NotchController: NSObject, NSWindowDelegate {
    private typealias Surface = DynamicNotch<NotchTasksView, CompactCountView, CompactProgressView>
    private let notch: Surface
    private var isExpanded = false
    private var transition: Task<Void, Never>?
    private var localClicks: Any?
    private var globalClicks: Any?
    private var screenChanges: NSObjectProtocol?

    private var screen: NSScreen? {
        NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main ?? NSScreen.screens.first
    }

    init(store: TaskStore, showHistory: @escaping () -> Void) {
        notch = Surface(hoverBehavior: [.hapticFeedback, .increaseShadow], style: .auto) {
            NotchTasksView(store: store, showHistory: showHistory)
        } compactLeading: {
            CompactCountView(store: store)
        } compactTrailing: {
            CompactProgressView(store: store)
        }
        notch.transitionConfiguration = .init(skipIntermediateHides: true)
        super.init()
    }

    func start() {
        localClicks = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self else { return event }
            if let panel = self.notch.windowController?.window, event.window === panel {
                let point = panel.convertPoint(toScreen: event.locationInWindow)
                if self.isInTopStrip(point) {
                    self.toggle()
                    return nil
                }
            } else {
                self.collapse()
            }
            return event
        }
        globalClicks = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            self?.collapse()
        }
        screenChanges = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // The kit rebuilds its panel on display changes; reconnect its delegate
            // after the notification has also reached the kit's own observer.
            Task { @MainActor [weak self] in
                await Task.yield()
                self?.present()
            }
        }
        present()
    }

    func stop() {
        transition?.cancel()
        if let localClicks { NSEvent.removeMonitor(localClicks) }
        if let globalClicks { NSEvent.removeMonitor(globalClicks) }
        if let screenChanges { NotificationCenter.default.removeObserver(screenChanges) }
        localClicks = nil
        globalClicks = nil
        screenChanges = nil
        notch.windowController?.close()
    }

    func toggle() {
        isExpanded.toggle()
        present()
    }

    func collapse() {
        guard isExpanded, NSApplication.shared.modalWindow == nil else { return }
        isExpanded = false
        notch.windowController?.window?.resignKey()
        present()
    }

    func windowDidResignKey(_ notification: Notification) {
        collapse()
    }

    private func present() {
        guard let screen else { return }
        transition?.cancel()
        let expanded = isExpanded
        transition = Task { @MainActor [weak self] in
            guard let self else { return }
            if expanded {
                await self.notch.expand(on: screen)
            } else {
                await self.notch.compact(on: screen)
            }
            guard !Task.isCancelled, expanded == self.isExpanded,
                  let panel = self.notch.windowController?.window else { return }
            panel.delegate = self
            panel.hidesOnDeactivate = false
            panel.collectionBehavior.insert(.fullScreenAuxiliary)
            if expanded {
                NSApplication.shared.activate(ignoringOtherApps: true)
                panel.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func isInTopStrip(_ point: NSPoint) -> Bool {
        guard let screen else { return false }
        let cutoutWidth: CGFloat
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            cutoutWidth = right.minX - left.maxX
        } else {
            cutoutWidth = 180
        }
        let height = max(screen.safeAreaInsets.top, screen.frame.maxY - screen.visibleFrame.maxY, 24)
        return NSRect(
            x: screen.frame.midX - cutoutWidth / 2 - 58,
            y: screen.frame.maxY - height,
            width: cutoutWidth + 116,
            height: height
        ).contains(point)
    }
}
