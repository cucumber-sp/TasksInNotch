//
//  TasksInNotchTests.swift
//  TasksInNotchTests
//
//  Created by Andrey Onischenko on 03.10.2026.
//

import Testing
import Foundation
import SwiftData
@testable import TasksInNotch

@MainActor
struct TasksInNotchTests {
    @Test func completionKeepsTheTotalAndSeparatesDays() throws {
        let store = try makeStore()
        let today = Date()
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: today))
        let first = try #require(try store.addTask("Первая задача", on: today))
        let second = try #require(try store.addTask("Вторая задача", on: today))
        _ = try store.addTask("Вчерашняя задача", on: yesterday)

        try store.toggleCompletion(of: first)

        #expect(store.progress(on: today).label == "1/2")
        #expect(store.progress(on: today).fraction == 0.5)
        #expect(store.pendingTasks(on: today).map(\.id) == [second.id])
        #expect(store.tasks(on: today).count == 2)
        #expect(store.progress(on: yesterday).label == "0/1")

        try store.toggleCompletion(of: first)
        #expect(store.progress(on: today).label == "0/2")
        #expect(store.pendingTasks(on: today).count == 2)
    }

    @Test func blankInputIsRejectedAndTasksStayOnOneLine() throws {
        let store = try makeStore()
        #expect(try store.addTask(" \n\t ", on: .now) == nil)
        let task = try #require(try store.addTask("  Купить\nмолоко  ", on: .now))
        #expect(task.title == "Купить молоко")
        #expect(store.progress(on: .now).label == "0/1")

        try store.deleteTask(task)
        #expect(store.tasks.isEmpty)
        #expect(store.progress(on: .now).fraction == 0)
    }

    @Test func tasksSurviveReopeningThePersistentStore() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("tasks.store")
        let day = Date()

        let originalID = try autoreleasepool {
            let container = try ModelContainer(for: TodoTask.self, configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
            let store = try TaskStore(container: container)
            let task = try #require(try store.addTask("Сохранённая задача", on: day))
            try store.toggleCompletion(of: task)
            return task.id
        }

        let reopenedContainer = try ModelContainer(for: TodoTask.self, configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
        let reopenedStore = try TaskStore(container: reopenedContainer)
        let task = try #require(reopenedStore.tasks(on: day).first)
        #expect(task.id == originalID)
        #expect(task.title == "Сохранённая задача")
        #expect(task.isCompleted)
        #expect(reopenedStore.progress(on: day).label == "1/1")
        #expect(reopenedStore.pendingTasks(on: day).isEmpty)
    }

    private func makeStore() throws -> TaskStore {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try TaskStore(container: ModelContainer(for: TodoTask.self, configurations: configuration))
    }
}
