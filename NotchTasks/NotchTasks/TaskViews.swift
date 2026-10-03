import SwiftUI

enum TaskAppearance {
    static let accent = Color(red: 0.61, green: 0.79, blue: 0.67)
    static let rowHeight: CGFloat = 36
    static let listHeight = rowHeight * 6
    static let panelWidth: CGFloat = 410
}

struct CompactCountView: View {
    let store: TaskStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
            Text(store.progress(on: timeline.date).label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .monospacedDigit()
                .frame(width: 38)
                .accessibilityLabel("Задачи на сегодня: \(store.progress(on: timeline.date).label)")
        }
    }
}

struct CompactProgressView: View {
    let store: TaskStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
            let progress = store.progress(on: timeline.date)
            ZStack {
                Circle().stroke(.white.opacity(0.18), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: progress.fraction)
                    .stroke(TaskAppearance.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 16, height: 16)
            .frame(width: 38)
            .animation(.easeInOut(duration: 0.2), value: progress.fraction)
            .accessibilityLabel("Выполнено \(Int(progress.fraction * 100)) процентов")
        }
    }
}

struct NotchTasksView: View {
    let store: TaskStore
    let showHistory: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
            let day = timeline.date
            let pending = store.pendingTasks(on: day)
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("Мои задачи").font(.system(size: 14, weight: .medium))
                    Text(store.progress(on: day).label)
                        .font(.system(size: 12))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 12)
                    Text(day, format: .dateTime.day().month(.wide))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Button(action: showHistory) {
                        Image(systemName: "calendar")
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Все задачи по датам")
                    .accessibilityLabel("Все задачи по датам")
                }
                .frame(height: 30)

                if pending.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(TaskAppearance.accent)
                        Text("Все задачи на сегодня выполнены")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: TaskAppearance.listHeight)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(pending) { task in
                                TaskRow(task: task, store: store)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .frame(height: TaskAppearance.listHeight)
                }

                TaskInputView(store: store, day: day)
            }
            .padding(.horizontal, 5)
            .frame(width: TaskAppearance.panelWidth)
            .environment(\.locale, Locale(identifier: "ru_RU"))
            .preferredColorScheme(.dark)
        }
        .taskStorageAlert(store: store)
    }
}

struct TaskRow: View {
    let task: TodoTask
    let store: TaskStore

    var body: some View {
        Button {
            do { try store.toggleCompletion(of: task) }
            catch { store.report(error) }
        } label: {
            HStack(spacing: 11) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(task.isCompleted ? TaskAppearance.accent : .secondary)
                Text(task.title)
                    .font(.system(size: 13))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: TaskAppearance.rowHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(task.title)
        .accessibilityLabel(task.title)
        .accessibilityValue(task.isCompleted ? "Выполнена" : "Не выполнена")
        .contextMenu {
            Button("Удалить задачу", role: .destructive) {
                do { try store.deleteTask(task) }
                catch { store.report(error) }
            }
        }
    }
}

struct TaskInputView: View {
    let store: TaskStore
    let day: Date
    @State private var title = ""
    @FocusState private var isFocused: Bool

    private var canAdd: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        HStack(spacing: 6) {
            TextField("Новая задача", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFocused)
                .onSubmit(addTask)
                .accessibilityLabel("Новая задача")
            Button(action: addTask) {
                Image(systemName: "plus")
                    .font(.system(size: 16))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canAdd)
            .accessibilityLabel("Добавить задачу")
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .frame(height: 40)
        .background(.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
        .onAppear { isFocused = true }
    }

    private func addTask() {
        do {
            if try store.addTask(title, on: day) != nil { title = "" }
        } catch {
            store.report(error)
        }
    }
}

private struct TaskStorageAlert: ViewModifier {
    @Bindable var store: TaskStore

    func body(content: Content) -> some View {
        content.alert("Ошибка сохранения", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("Понятно") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

extension View {
    func taskStorageAlert(store: TaskStore) -> some View {
        modifier(TaskStorageAlert(store: store))
    }
}
