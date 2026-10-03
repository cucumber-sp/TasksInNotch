import SwiftUI

struct HistoryView: View {
    let store: TaskStore
    @State private var selectedDay = Date()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("Мои задачи").font(.system(size: 18, weight: .medium))
                Spacer()
                Text(store.progress(on: selectedDay).label)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 18)

            HStack(spacing: 12) {
                Button { moveDay(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Предыдущий день")
                DatePicker("Дата задач", selection: $selectedDay, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.field)
                    .accessibilityLabel("Дата задач")
                Button { moveDay(1) } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel("Следующий день")
                Spacer()
                Button("Сегодня") { selectedDay = Date() }
            }
            .buttonStyle(.borderless)
            .padding(.bottom, 14)

            Divider()
            let tasks = store.tasks(on: selectedDay)
            if tasks.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checklist")
                        .font(.system(size: 28, weight: .light))
                    Text("На эту дату задач нет")
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks) { task in
                            TaskRow(task: task, store: store)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            TaskInputView(store: store, day: selectedDay)
                .padding(.top, 12)
        }
        .padding(24)
        .frame(minWidth: 440, minHeight: 380)
        .environment(\.locale, Locale(identifier: "ru_RU"))
        .taskStorageAlert(store: store)
    }

    private func moveDay(_ offset: Int) {
        if let day = Calendar.autoupdatingCurrent.date(byAdding: .day, value: offset, to: selectedDay) {
            selectedDay = day
        }
    }
}
