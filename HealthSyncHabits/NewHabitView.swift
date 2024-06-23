//
//  NewHabitView.swift
//  HealthSyncHabits
//
//  Created by Markus Ray on 02.06.2024.
//

import SwiftUI
import SwiftData

struct NewHabitView: View {
    @Environment(ViewModel.self) private var vm
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query var habits: [Habit]
    @State private var name = ""
    @State private var pickerDate = Date()
    @State private var countPerDay = 1
    
    // Interval
    let array = ["daily", "by week", "custom"]
    @State private var pickedInterval = "Daily"
    let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    @State private var pickedWeekDays = [Int]()
    @State private var activeDaysCount = 1
    @State private var offDaysCount = 1
    
    var body: some View {
        List {
            Section {
                TextField("Add your habit name here...", text: $name)
            } footer: {
                if habits.contains(where: {$0.name == name}) {
                    Text("⚠️There is one habit with the same name already, try another one")
                        .foregroundStyle(.red)
                        .font(.caption)
                } else if name.count >= 3 {
                    Text("✅This name can be used")
                        .foregroundStyle(.green)
                        .font(.caption)
                } else if name.count < 3 {
                    Text("⚠️Min name length is three characters")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
            Section {
                DatePicker("Starts from", selection: $pickerDate, displayedComponents: .date)
            }
            Section {
                Picker("Reps per day:", selection: $countPerDay) {
                    ForEach(0..<101) { index in
                        Text(String(index))
                    }
                }
                .pickerStyle(.menu)
            }
            Section {
                Picker("Day interval:", selection: $pickedInterval) {
                    ForEach(array, id: \.self) { interval in
                        Text(interval)
                    }
                }
                .pickerStyle(.menu)
                if pickedInterval == "by week" {
                    HStack(spacing: 0) {
                        ForEach(Array(weekDays.enumerated()), id: \.element) { index, day in
                            ZStack {
                                pickedWeekDays.contains(index + 1) ? Color.blue : Color.black.opacity(0.001)
                                Text(day)
                                    .foregroundStyle(pickedWeekDays.contains(index + 1) ? .white : .primary)
                                    .onTapGesture {
                                        if pickedWeekDays.contains(index + 1) {
                                            pickedWeekDays.removeAll(where: {$0 == (index + 1)})
                                        } else {
                                            pickedWeekDays.append(index + 1)
                                        }
                                    }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            if index != 6 {
                                Divider()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                } else if pickedInterval == "custom" {
                    Picker("Active days in a row:", selection: $activeDaysCount) {
                        ForEach(0..<101) { index in
                            Text(String(index))
                        }
                    }
                    .pickerStyle(.menu)
                    Picker("Off days in a row:", selection: $offDaysCount) {
                        ForEach(0..<101) { index in
                            Text(String(index))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            Section {
                Button("Create new habit") {
                    createNewHabit()
                }
                .disabled(name.count < 3 || habits.contains(where: {$0.name == name}) || countPerDay < 1 || (pickedInterval == "by week" && pickedWeekDays.isEmpty) || (pickedInterval == "custom" && (activeDaysCount == 0 || offDaysCount == 0)))
            }
        }
    }
    
    private func createNewHabit() {
        var interval: [String: [Int]] = [:]
        if pickedInterval == "daily" {
            interval = ["daily": []]
        } else if pickedInterval == "by week" {
            interval = ["by week": pickedWeekDays]
        } else if pickedInterval == "custom" {
            interval = ["custom": [activeDaysCount, offDaysCount]]
        }
        let habit = Habit(name: name, creationDate: pickerDate.convertToString(), count: countPerDay, interval: interval)
        modelContext.insert(habit)
        let newDaysStr = habit.creationDate.getDays(for: habit)
        var newDays = [DayStruct]()
        for dayStr in newDaysStr {
            let day = DayStruct(day: dayStr, habit: habit)
            newDays.append(day)
            modelContext.insert(day)
        }
        habit.checkedInDays = newDays
        dismiss()
    }
}

#Preview {
    NewHabitView()
        .modelContainer(for: Habit.self, inMemory: false)
        .environment(ViewModel())
}
