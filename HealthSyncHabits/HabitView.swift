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
    @Query var days: [DayStruct]
    @State var pickerDate: Date
    let status = ["unchecked", "checked", "skiped"]
    
    var body: some View {
        VStack {
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
                        }
                    }
                    .pickerStyle(.menu)
                    Picker("Min reps for daily goal:", selection: $habit.minCount) {
                        ForEach(0..<101) { index in
                            Text(String(index))
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
                    ForEach(days, id: \.self) { day in
                        if day.habit?.id == habit.id {
                            HStack {
                                Text(day.date)
                                Text(day.state)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }
}

//#Preview {
//    HabitView(habit: previewHabit)
//        .modelContainer(for: Habit.self, inMemory: true)
//        .environment(ViewModel())
//}
//
//let previewHabit = Habit(name: "Yoga", creationDate: "2024-02-15", minCount: 1, count: 2, checkedInDays: [previewDay])
//let previewDay = Day(date: "2024-01-01", state: .unchecked, count: 3, habit: previewHabit)
//
