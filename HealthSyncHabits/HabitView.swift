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
    
    var body: some View {
        VStack {
            List {
                Section {
                    TextField("Add your habit name here...", text: $habit.name)
                }
                Section {
                    DatePicker("Starts from", selection: $habit.creationDate, displayedComponents: .date)
                }
                Section {
                    Picker("Reps per day:", selection: $habit.countPerday) {
                        ForEach(1..<101) { index in
                            Text(String(index))
                        }
                    }
                    .pickerStyle(.menu)
                    Picker("Max reps for daily goal:", selection: $habit.minCount) {
                        ForEach(1..<101) { index in
                            Text(String(index))
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(habit)
                        dismiss()
                    }
                }
//                Section("History") {
//                    ForEach(habit.checkedInDays, id: \.self) { day in
//                        Text(day.date.description)
//                    }
//                }
            }
        }
    }
}

#Preview {
    HabitView(habit: previewHabit)
        .modelContainer(for: Habit.self, inMemory: true)
        .environment(ViewModel())
}

let previewDay = Day(date: Date(timeIntervalSinceNow: -9134003), state: .unchecked, count: 3)
let previewHabit = Habit(name: "Yoga", creationDate: Date(timeIntervalSinceNow: -19134003), minCount: 1, count: 2, checkedInDays: [previewDay])
