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
    @State var habit = Habit()
    
    var body: some View {
        List {
            Section {
                TextField("Add your habit name here...", text: $habit.name)
            } footer: {
                if habits.contains(where: {$0.name == habit.name}) {
                    Text("⚠️There is one habit with the same name already, try another one")
                        .foregroundStyle(.red)
                        .font(.caption)
                } else if habit.name.count >= 3 {
                    Text("✅This name can be used")
                        .foregroundStyle(.green)
                        .font(.caption)
                } else if habit.name.count < 3 {
                    Text("⚠️Min name length is three characters")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
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
                Picker("Min reps for daily goal:", selection: $habit.minCount) {
                    ForEach(1..<101) { index in
                        Text(String(index))
                    }
                }
                .pickerStyle(.menu)
            }
            Section {
                Button("Create new habit") {
                    modelContext.insert(habit)
                    dismiss()
                }
                .disabled(habit.name.count < 3 || habits.contains(where: {$0.name == habit.name}))
            }
        }
    }
    
    private func createNewHabit() {
        let day = Day(date: habit.creationDate, state: .unchecked, count: 0)
        habit.checkedInDays.append(day)
        modelContext.insert(habit)
        dismiss()
    }
}

#Preview {
    NewHabitView()
        .modelContainer(for: Habit.self, inMemory: true)
        .environment(ViewModel())
}
