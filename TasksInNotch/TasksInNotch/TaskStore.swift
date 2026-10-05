import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class TaskStore {
    private(set) var tasks: [TodoTask]
    var errorMessage: String?
    @ObservationIgnored private let context: ModelContext

    init(container: ModelContainer) throws {
        context = ModelContext(container)
        context.autosaveEnabled = false
        tasks = try context.fetch(FetchDescriptor<TodoTask>(sortBy: [SortDescriptor(\.createdAt)]))
    }

    func tasks(on day: Date) -> [TodoTask] {
        let key = TaskDay.key(for: day)
        return tasks.filter { $0.dayKey == key }
    }

    func pendingTasks(on day: Date) -> [TodoTask] {
        tasks(on: day).filter { !$0.isCompleted }
    }

    func progress(on day: Date) -> DailyProgress {
        let dailyTasks = tasks(on: day)
        return DailyProgress(completed: dailyTasks.filter(\.isCompleted).count, total: dailyTasks.count)
    }

    @discardableResult
    func addTask(_ title: String, on day: Date) throws -> TodoTask? {
        let title = title.components(separatedBy: .newlines)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        let task = TodoTask(title: title, dayKey: TaskDay.key(for: day))
        context.insert(task)
        do {
            try context.save()
            tasks.append(task)
            return task
        } catch {
            context.rollback()
            throw error
        }
    }

    func toggleCompletion(of task: TodoTask) throws {
        task.isCompleted.toggle()
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func deleteTask(_ task: TodoTask) throws {
        let id = task.id
        context.delete(task)
        do {
            try context.save()
            tasks.removeAll { $0.id == id }
        } catch {
            context.rollback()
            throw error
        }
    }

    func report(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}
