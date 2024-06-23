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
                Section {
                    ForEach(habits.filter({ habit in
                        let today = Date().convertToString()
                        if let day = habit.checkedInDays.first(where: {$0.date == today}) {
                            return day.state == "unchecked"
                        }
                        return false
                    }), id: \.self) { habit in
                        HStack {
                            Text(habit.name)
                            Spacer()
                            Text(habit.todayScore())
                                .foregroundStyle(habit.todayScoreColor())
                            Divider()
                            Text("🔥\(habit.score)")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            path.append(habit)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                habit.addRep()
                                habit.calculateScore()
                            } label: {
                                Image(systemName: "checkmark.seal.fill")
                            }
                            .tint(.green)
                            Button {
                                habit.removeRep()
                                habit.calculateScore()
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if habit.canAlreadyCheck() {
                                Button {
                                    habit.checkFromUnCheck()
                                    habit.calculateScore()
                                } label: {
                                    Text("Check")
                                }
                                .tint(.yellow)
                            }
                            Button {
                                habit.skip()
                                habit.calculateScore()
                            } label: {
                                Text("Skip")
                            }
                            .tint(.red)
                        }
                    }
                } header: {
                    Text("Unchecked ☑️")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.black)
                        .offset(x: -20)
                }
                
                Section {
                    ForEach(habits.filter({ habit in
                        let today = Date().convertToString()
                        if let day = habit.checkedInDays.first(where: {$0.date == today}) {
                            return day.state == "checked"
                        }
                        return false
                    }), id: \.self) { habit in
                        HStack {
                            Text(habit.name)
                            Spacer()
                            Text(habit.todayScore())
                                .foregroundStyle(habit.todayScoreColor())
                            Divider()
                            Text("🔥\(habit.score + 1)")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            path.append(habit)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                habit.addRep()
                                habit.calculateScore()
                            } label: {
                                Image(systemName: "checkmark.seal.fill")
                            }
                            .tint(.green)
                            Button {
                                habit.removeRep()
                                habit.calculateScore()
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .cancel) {
                                habit.skip()
                                habit.calculateScore()
                            } label: {
                                Text("Skip")
                            }
                            .tint(.red)
                        }
                    }
                } header: {
                    Text("Checked ✅")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.black)
                        .offset(x: -20)
                }
                
                Section {
                    ForEach(habits.filter({ habit in
                        let today = Date().convertToString()
                        if let day = habit.checkedInDays.first(where: {$0.date == today}) {
                            return day.state == "skiped"
                        }
                        return false
                    }), id: \.self) { habit in
                        HStack {
                            Text(habit.name)
                            Spacer()
                            Text(habit.todayScore())
                                .foregroundStyle(habit.todayScoreColor())
                            Divider()
                            Text("🔥\(habit.score)")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            path.append(habit)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                habit.AddRepAndReplace()
                                habit.calculateScore()
                            } label: {
                                Image(systemName: "checkmark.seal.fill")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                habit.uncheckFromSkiped()
                                habit.calculateScore()
                            } label: {
                                Text("Uncheck")
                            }
                            .tint(.cyan)
                        }
                    }
                } header: {
                    Text("Skiped ❎")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.black)
                        .offset(x: -20)
                }
            }
            .sheet(isPresented: $showNewHabitSheet) {
                NewHabitView()
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.height(520)])
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem {
                    Button { 
                        showNewHabitSheet.toggle()
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Habit.self) { habit in
                HabitView(habit: habit, pickerDate: habit.creationDate.convertToDate())
            }
            .onAppear {
                appendTodayStruct()
            }
        }
    }
    
    private func appendTodayStruct() {
        for (i, habit) in habits.enumerated() {
            let newDays = habit.creationDate.getDays(for: habit)
            for dayStr in newDays {
                guard let interval = habit.interval.first else {return}
                if interval.key == "by week" {
                    guard let dayOfWeek = dayStr.dayOfWeek() else {return}
                    if interval.value.contains(dayOfWeek) {
                        let day = DayStruct(day: dayStr, habit: habit, state: "unchecked")
                        modelContext.insert(day)
                        habits[i].checkedInDays.append(day)
                    } else {
                        let day = DayStruct(day: dayStr, habit: habit, state: "skiped")
                        modelContext.insert(day)
                        habits[i].checkedInDays.append(day)
                    }
                } else if interval.key == "custom" {
                    guard interval.value.count == 2 else {return}
                    let activeDaysCount = interval.value[0]
                    let offDaysCount = interval.value[1]
                    let state = dayStr.isWorkingDay(from: habit.creationDate, active: activeDaysCount, off: offDaysCount)
                    let day = DayStruct(day: dayStr, habit: habit, state: state)
                    modelContext.insert(day)
                    habits[i].checkedInDays.append(day)
                } else {
                    let day = DayStruct(day: dayStr, habit: habit)
                    modelContext.insert(day)
                    habits[i].checkedInDays.append(day)
                }
            }
        }
    }
}

#Preview {
    MainList()
        .modelContainer(for: Habit.self, inMemory: true)
        .environment(ViewModel())
}
