//
//  ContentView.swift
//  HealthSyncHabits
//
//  Created by sihtmark on 20.01.2024.
//

import SwiftUI
import SwiftData

struct MainList: View {
    @Environment(ViewModel.self) private var vm
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.name, order: .forward, animation: .easeInOut) var habits: [Habit]
    @State private var path = NavigationPath()
    @State private var showNewHabitSheet = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(habits) { habit in
                    HStack {
                        Text(habit.name)
                        Spacer()
                        Text("\(habit.score)")
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        path.append(habit)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            
                        } label: {
                            Label("Done", systemImage: "checkmark.seal.fill")
                        }
                        .tint(.green)
                        
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            
                        } label: {
                            Text("Skip once")
                        }
                        .tint(.yellow)
                        Button {
                            
                        } label: {
                            Text("Skip all")
                        }
                        .tint(.red)
                    }
                }
                .onDelete(perform: deleteHabit)
            }
            .sheet(isPresented: $showNewHabitSheet) {
                NewHabitView()
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.medium])
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button { 
                        showNewHabitSheet.toggle()
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Habit.self) { habit in
                HabitView(habit: habit)
            }
//            .task {
//                let day = Day(date: Date(timeIntervalSinceNow: -9134003), state: .unchecked, count: 3)
//                let habit = Habit(name: "Yoga", creationDate: Date(timeIntervalSinceNow: -19134003), minCount: 1, count: 2, checkedInDays: [day])
//                modelContext.insert(habit)
//            }
        }
    }

    private func deleteHabit(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(habits[index])
        }
    }
}

#Preview {
    MainList()
        .modelContainer(for: Habit.self, inMemory: true)
        .environment(ViewModel())
}
