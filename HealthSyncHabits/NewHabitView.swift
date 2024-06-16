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
    @State private var maxCount = 0
    @State private var minCount = 0
    
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
                Picker("Reps per day:", selection: $maxCount) {
                    ForEach(0..<101) { index in
                        Text(String(index))
                    }
                }
                .pickerStyle(.menu)
                Picker("Min reps for daily goal:", selection: $minCount) {
                    ForEach(0..<101) { index in
                        Text(String(index))
                    }
                }
                .pickerStyle(.menu)
            }
            Section {
                Button("Create new habit") {
                    createNewHabit()
                }
                .disabled(name.count < 3 || habits.contains(where: {$0.name == name}) || minCount > maxCount || maxCount < 1)
            }
        }
    }
    
    private func createNewHabit() {
        let habit = Habit(name: name, creationDate: pickerDate.convertToString(), minCount: minCount, count: maxCount)
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
        .modelContainer(for: Habit.self, inMemory: true)
        .environment(ViewModel())
}
