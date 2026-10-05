import SwiftUI

struct HistoryView: View {
    let store: TaskStore
    let language: LanguageSettings
    @State private var selectedDay = Date()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text(language.text("My Tasks")).font(.system(size: 18, weight: .medium))
                Spacer()
                Text(store.progress(on: selectedDay).label)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 18)

            HStack(spacing: 12) {
                Button { moveDay(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel(language.text("Previous day"))
                DatePicker(language.text("Task date"), selection: $selectedDay, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.field)
                    .accessibilityLabel(language.text("Task date"))
                Button { moveDay(1) } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel(language.text("Next day"))
                Spacer()
                Button(language.text("Today")) { selectedDay = Date() }
            }
            .buttonStyle(.borderless)
            .padding(.bottom, 14)

            Divider()
            let tasks = store.tasks(on: selectedDay)
            if tasks.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checklist")
                        .font(.system(size: 28, weight: .light))
                    Text(language.text("No tasks for this date"))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks) { task in
                            TaskRow(task: task, store: store, language: language)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            TaskInputView(store: store, day: selectedDay, language: language)
                .padding(.top, 12)
        }
        .padding(24)
        .frame(minWidth: 440, minHeight: 380)
        .environment(\.locale, language.locale)
        .taskStorageAlert(store: store, language: language)
    }

    private func moveDay(_ offset: Int) {
        if let day = Calendar.autoupdatingCurrent.date(byAdding: .day, value: offset, to: selectedDay) {
            selectedDay = day
        }
    }
}
