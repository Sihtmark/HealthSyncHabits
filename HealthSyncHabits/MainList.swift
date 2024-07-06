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
    @Query var habits: [Habit]
    @State private var path = NavigationPath()
    @State private var showNewHabitSheet = false
    @State private var onAppOpening = true
    @State private var userSettings: UserSettings?

    var body: some View {
        NavigationStack(path: $path) {
            List {
                uncheckedSection
                checkedSection
                skipedSection
            }
            .sheet(isPresented: $showNewHabitSheet) {
                NewHabitView()
                    .presentationDragIndicator(.visible)
            }
            .navigationTitle("Habits")
            .toolbar {
                if let userSettings {
                    ToolbarItem(placement: .principal) {
                        Button {
                            // ⚠️ remove some value from total ammount
                        } label: {
                            Text("💰")
                            +
                            Text(String(format: "%.2f", userSettings.totalReward))
                            +
                            Text(" €")
                        }
                        .font(.title)
                    }
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
                HabitView(habit: habit, pickerDate: habit.creationDate.convertToDate())
            }
            .onAppear {
                onAppearMethod()
            }
        }
    }
    
    private var uncheckedSection: some View {
        Section {
            ForEach(habits.filter({ habit in
                let today = Date().convertToString()
                if let day = habit.checkedInDays.first(where: {$0.date == today}) {
                    return day.state == "unchecked"
                }
                return false
            }).sorted(by: { topHabit, bottomHabit in
                let topCount = topHabit.checkedInDays.first(where: {$0.date == Date().convertToString()})?.count ?? 0
                let bottomCount = bottomHabit.checkedInDays.first(where: {$0.date == Date().convertToString()})?.count ?? 0
                return topHabit.time[topCount] < bottomHabit.time[bottomCount]
            }), id: \.self) { habit in
                HStack {
                    Text(habit.name)
                    Spacer()
                    Text(habit.todayScore())
                        .foregroundStyle(habit.todayScoreColor())
                    Divider()
                    Text("\(habit.score)")
                        .foregroundStyle(scoreColor(score: habit.score))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    path.append(habit)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        habit.addRep()
                        if let reward = habit.reward {
                            userSettings?.totalReward += reward
                        }
                        habit.calculateScore()
                    } label: {
                        Image(systemName: "checkmark.seal.fill")
                    }
                    .tint(.green)
                    Button {
                        habit.removeRep()
                        if let reward = habit.reward {
                            userSettings?.totalReward += reward
                        }
                        habit.calculateScore()
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .tint(.orange)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        let today = Date().convertToString()
                        if let index = habit.checkedInDays.firstIndex(where: {$0.date == today}), let reward = habit.reward {
                            userSettings?.totalReward -= (Double(habit.checkedInDays[index].count) * reward)
                        }
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
                .foregroundStyle(.black)
                .offset(x: -20)
        }
    }
    
    private var checkedSection: some View {
        Section {
            ForEach(habits.filter({ habit in
                let today = Date().convertToString()
                if let day = habit.checkedInDays.first(where: {$0.date == today}) {
                    return day.state == "checked"
                }
                return false
            }).sorted(by: { topHabit, bottomHabit in
                let topCount = topHabit.checkedInDays.first(where: {$0.date == Date().convertToString()})?.count ?? 0
                let bottomCount = bottomHabit.checkedInDays.first(where: {$0.date == Date().convertToString()})?.count ?? 0
                return topHabit.time[topCount] < bottomHabit.time[bottomCount]
            }), id: \.self) { habit in
                HStack {
                    Text(habit.name)
                    Spacer()
                    Text(habit.todayScore())
                        .foregroundStyle(habit.todayScoreColor())
                    Divider()
                    Text("\(habit.score)")
                        .foregroundStyle(scoreColor(score: habit.score))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    path.append(habit)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        habit.addRep()
                        if let reward = habit.reward {
                            userSettings?.totalReward += reward
                        }
                        habit.calculateScore()
                    } label: {
                        Image(systemName: "checkmark.seal.fill")
                    }
                    .tint(.green)
                    Button {
                        habit.removeRep()
                        if let reward = habit.reward {
                            userSettings?.totalReward -= reward
                        }
                        habit.calculateScore()
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .tint(.orange)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .cancel) {
                        let today = Date().convertToString()
                        if let index = habit.checkedInDays.firstIndex(where: {$0.date == today}), let reward = habit.reward {
                            userSettings?.totalReward -= (Double(habit.checkedInDays[index].count) * reward)
                        }
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
                .foregroundStyle(.black)
                .offset(x: -20)
        }
    }
    
    private var skipedSection: some View {
        Section {
            ForEach(habits.filter({ habit in
                let today = Date().convertToString()
                if let day = habit.checkedInDays.first(where: {$0.date == today}) {
                    return day.state == "skiped"
                }
                return false
            }).sorted(by: { topHabit, bottomHabit in
                let topCount = topHabit.checkedInDays.first(where: {$0.date == Date().convertToString()})?.count ?? 0
                let bottomCount = bottomHabit.checkedInDays.first(where: {$0.date == Date().convertToString()})?.count ?? 0
                return topHabit.time[topCount] < bottomHabit.time[bottomCount]
            }), id: \.self) { habit in
                HStack {
                    Text(habit.name)
                    Spacer()
                    Text(habit.todayScore())
                        .foregroundStyle(habit.todayScoreColor())
                    Divider()
                    Text("\(habit.score)")
                        .foregroundStyle(scoreColor(score: habit.score))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    path.append(habit)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        habit.addRepAndReplace()
                        if let reward = habit.reward {
                            userSettings?.totalReward += reward
                        }
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
                .foregroundStyle(.black)
                .offset(x: -20)
        }
    }
    
    private func onAppearMethod() {
        if onAppOpening {
            let request = FetchDescriptor<UserSettings>()
            let data = try? modelContext.fetch(request)
            if data?.first != nil {
                userSettings = data?.first
                userSettings?.totalReward = 0.0
            } else {
                modelContext.insert(UserSettings(totalReward: 0.0, ledger: []))
                let request = FetchDescriptor<UserSettings>()
                let data = try? modelContext.fetch(request)
                if data?.first != nil {
                    userSettings = data?.first
                }
            }
            appendTodayStruct()
            sumTotalReward()
            onAppOpening = false
        }
    }
    
    private func sumTotalReward() {
        for habit in habits {
            for dayStruct in habit.checkedInDays {
                if let reward = habit.reward {
                    userSettings?.totalReward += (reward * Double(dayStruct.count))
                }
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
            habit.calculateScore()
        }
    }
    
    private func scoreColor(score: Int) -> Color {
        switch score {
        case 0..<7:
            return .red
        case 7..<14:
            return .orange
        case 14..<21:
            return .yellow
        case 21..<28:
            return .cyan
        default:
            return .green
        }
    }
}

#Preview {
    MainList()
        .modelContainer(for: Habit.self, inMemory: true)
        .environment(ViewModel())
}
