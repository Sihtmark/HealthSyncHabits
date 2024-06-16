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
                    ForEach(habit.checkedInDays.sorted(by: {$0.date > $1.date}), id: \.self) { day in
                        HStack {
                            Text(day.date)
                            Spacer()
                            Text(day.state)
//                            if let index = habit.checkedInDays.firstIndex(where: {$0.date == day.date}) {
//                                habit.checkedInDays[index].replaceStatus(with: status)
//                            } else {
//                                print("we couln't change day")
//                            }
                        }
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
                                    day.count = habit.minCount
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
