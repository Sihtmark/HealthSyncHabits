//
//  NewHabitView.swift
//  HealthSyncHabits
//
//  Created by Markus Ray on 02.06.2024.
//

import SwiftUI
import SwiftData

enum Interval: String, Equatable, CaseIterable {
    case daily = "daily"
    case byWeek = "by week"
    case custom = "custom"
}

struct NewHabitView: View {
    @Environment(ViewModel.self) private var vm
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query var habits: [Habit]
    @State private var name = ""
    @State private var pickerDate = Date()
    @State private var countPerDay = 1
    @State private var showTimeSection = false
    @State private var timeArray = ["00-00"]
    
    // Interval
    @State private var pickedInterval: Interval = .daily
    let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    @State private var pickedWeekDays = [Int]()
    @State private var activeDaysCount = 1
    @State private var offDaysCount = 1
    
    var body: some View {
        NavigationStack {
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
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    Toggle("Set time", isOn: $showTimeSection)
                }
                if showTimeSection {
                    Section {
                        ForEach(Array(timeArray.enumerated()), id: \.offset) { key, value in
                            TimePickerCell(index: key + 1) { time in
                                timeArray[key] = time
                            }
                        }
                    } footer: {
                        Text("Choose time for each rep")
                    }
                }
                Section {
                    Picker("Day interval:", selection: $pickedInterval) {
                        ForEach(Interval.allCases, id: \.self) { interval in
                            Text(interval.rawValue)
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.menu)
                    if pickedInterval == .byWeek {
                        HStack(spacing: 0) {
                            ForEach(Array(weekDays.enumerated()), id: \.element) { index, day in
                                ZStack {
                                    pickedWeekDays.contains(index) ? Color.blue : Color.black.opacity(0.001)
                                    Text(day)
                                        .foregroundStyle(pickedWeekDays.contains(index) ? .white : .primary)
                                        .onTapGesture {
                                            if pickedWeekDays.contains(index) {
                                                pickedWeekDays.removeAll(where: {$0 == (index)})
                                            } else {
                                                pickedWeekDays.append(index)
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
                    } else if pickedInterval == .custom {
                        Picker("Active days in a row:", selection: $activeDaysCount) {
                            ForEach(0..<101) { index in
                                Text(String(index))
                                    .tag(index)
                            }
                        }
                        .pickerStyle(.menu)
                        Picker("Off days in a row:", selection: $offDaysCount) {
                            ForEach(0..<101) { index in
                                Text(String(index))
                                    .tag(index)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                Section {
                    Button("Create new habit") {
                        createNewHabit()
                    }
                    .disabled(name.count < 3 || habits.contains(where: {$0.name == name}) || countPerDay < 1 || (pickedInterval == .byWeek && pickedWeekDays.isEmpty) || (pickedInterval == .custom && (activeDaysCount == 0 || offDaysCount == 0)))
                }
            }
            .onChange(of: countPerDay) { oldValue, newValue in
                if oldValue < newValue {
                    for e in 0..<(newValue - oldValue) {
                        timeArray.append("00-00")
                    }
                } else {
                    var count = oldValue - 1
                    while count != newValue - 1 {
                        timeArray.remove(at: count)
                        count -= 1
                    }
                }
            }
        }
    }
    
    private func createNewHabit() {
        var interval: [String: [Int]] = [:]
        if pickedInterval == .daily {
            interval = ["daily": []]
        } else if pickedInterval == .byWeek {
            interval = ["by week": pickedWeekDays]
        } else if pickedInterval == .custom {
            interval = ["custom": [activeDaysCount, offDaysCount]]
        }
        let habit = Habit(name: name, creationDate: pickerDate.convertToString(), count: countPerDay, interval: interval, time: timeArray)
        modelContext.insert(habit)
        let newDaysStr = habit.creationDate.getDays(for: habit)
        var newDays = [DayStruct]()
        for dayStr in newDaysStr {
            guard let interval = habit.interval.first else {return}
            if interval.key == "by week" {
                guard let dayOfWeek = dayStr.dayOfWeek() else {return}
                if interval.value.contains(dayOfWeek) {
                    let day = DayStruct(day: dayStr, habit: habit, state: "unchecked")
                    newDays.append(day)
                    modelContext.insert(day)
                } else {
                    let day = DayStruct(day: dayStr, habit: habit, state: "skiped")
                    newDays.append(day)
                    modelContext.insert(day)
                }
            } else if interval.key == "custom" {
                guard interval.value.count == 2 else {return}
                let activeDaysCount = interval.value[0]
                let offDaysCount = interval.value[1]
                let state = dayStr.isWorkingDay(from: habit.creationDate, active: activeDaysCount, off: offDaysCount)
                let day = DayStruct(day: dayStr, habit: habit, state: state)
                newDays.append(day)
                modelContext.insert(day)
            } else {
                let day = DayStruct(day: dayStr, habit: habit)
                newDays.append(day)
                modelContext.insert(day)
            }
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

struct TimePickerCell: View {
    @State private var time = Date()
    let index: Int
    let onDismiss: (String) -> Void
    
    var body: some View {
        HStack {
            DatePicker(
                "Rep \(index)",
                selection: $time,
                displayedComponents: .hourAndMinute
            )
            .onChange(of: time) { oldValue, newValue in
                onDismiss(time.timeToString())
            }
        }
    }
}
