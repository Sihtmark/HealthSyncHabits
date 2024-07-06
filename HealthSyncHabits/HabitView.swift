//
//  HabitView.swift
//  HealthSyncHabits
//
//  Created by sihtmark on 27.01.2024.
//

import SwiftUI
import SwiftData

struct HabitView: View {
    @Environment(ViewModel.self) private var vm
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var habit: Habit
    @State var pickerDate: Date
    let statusArray = ["unchecked", "checked", "skiped"]
    
    var body: some View {
        List {
            Section {
                TextField("Add your habit name here...", text: $habit.name)
            }
            Section {
                DatePicker("Starts from", selection: $pickerDate, displayedComponents: .date)
                    .onSubmit {
                        habit.creationDate = pickerDate.convertToString()
                    }
            }
            Section {
                Picker("Reps per day:", selection: $habit.countPerday) {
                    ForEach(0..<101) { index in
                        Text(String(index))
                            .tag(index)
                    }
                }
                .pickerStyle(.menu)
            }
            Section {
                Button("Delete this habit", role: .destructive) {
                    modelContext.delete(habit)
                    dismiss()
                }
            }
            Section("History") {
                ForEach(habit.checkedInDays.sorted(by: {$0.date > $1.date}), id: \.self) { day in
                    HStack {
                        Text(day.date)
                        Spacer()
                        Text(day.state)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if day.state != "skiped" {
                                    Button("Skip") {
                                        day.state = "skiped"
                                        day.count = 0
                                        habit.calculateScore()
                                    }
                                    .tint(.yellow)
                                }
                                if day.state != "checked" {
                                    Button("Check") {
                                        day.state = "checked"
                                        day.count = habit.countPerday
                                        habit.calculateScore()
                                    }
                                    .tint(.green)
                                }
                                if day.state != "unchecked" {
                                    Button("Uncheck") {
                                        day.state = "unchecked"
                                        day.count = 0
                                        habit.calculateScore()
                                    }
                                    .tint(.orange)
                                }
                            }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

#Preview {
    HabitView(habit: Habit(name: "Yoga", creationDate: "2024-03-19", count: 2, interval: ["daily": []], checkedInDays: [], time: ["30-06", "55-18"]), pickerDate: "2024-03-19".convertToDate())
        .modelContainer(for: Habit.self, inMemory: true)
        .environment(ViewModel())
}
