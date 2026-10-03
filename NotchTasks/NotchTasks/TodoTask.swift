import Foundation
import SwiftData

@Model
final class TodoTask {
    var id: UUID
    var title: String
    var dayKey: String
    var isCompleted: Bool
    var createdAt: Date

    init(title: String, dayKey: String) {
        id = UUID()
        self.title = title
        self.dayKey = dayKey
        isCompleted = false
        createdAt = Date()
    }
}

enum TaskDay {
    static func key(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }
}

struct DailyProgress {
    let completed: Int
    let total: Int

    var label: String { "\(completed)/\(total)" }
    var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }
}
