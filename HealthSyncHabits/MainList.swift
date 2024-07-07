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
    @State private var rewardUpdateAmount = 0.0
    @State private var showRewardEditor = false
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                if showRewardEditor {
                    rewardSlider
                }
                uncheckedSection
                checkedSection
                skipedSection
            }
            .scrollDismissesKeyboard(.immediately)
            .sheet(isPresented: $showNewHabitSheet) {
                NewHabitView()
                    .presentationDragIndicator(.visible)
            }
            .navigationTitle("Habits")
            .toolbar {
                if let userSettings {
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Text("💰")
                            +
                            Text(String(format: "%.2f", self.userSettings?.totalReward ?? 0.0))
                            +
                            Text(" €")
                        }
                        .font(.title)
                        .foregroundStyle(Color.accentColor)
                        .onTapGesture {
                            if userSettings.totalReward > 0.1 {
                                withAnimation(.smooth) {
                                    showRewardEditor.toggle()
                                }
                            }
                        }
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
                HabitView(
                    habit: habit,
                    name: habit.name,
                    pickerDate: habit.creationDate.convertToDate(),
                    countPerDay: habit.countPerday,
                    showTimeSection: true,
                    showRewardSection: habit.reward != nil,
                    timeArray: habit.time,
                    smallReward: habit.reward ?? 0.3,
                    bigReward: habit.bigReward ?? 5.0,
                    pickedInterval: habit.interval.first?.key ?? "daily",
                    pickedWeekDays: habit.interval.first?.key == "by week" ? habit.interval.first?.value ?? [] : [],
                    activeDaysCount: habit.interval.first?.key == "custom" ?
                    habit.interval.first?.value[0] ?? 1 : 1,
                    offDaysCount: habit.interval.first?.key == "custom" ?
                    habit.interval.first?.value[1] ?? 1 : 1
                )
            }
            .onAppear {
                onAppearMethod()
            }
        }
    }
    
    private var rewardSlider: some View {
        VStack {
            Button {
            let newEntry = LedgerEntry(
                id: UUID().uuidString,
                date: Date().convertToString(),
                amount: rewardUpdateAmount
            )
            modelContext.insert(newEntry)
            self.userSettings?.ledger.append(newEntry)
            userSettings?.totalReward -= rewardUpdateAmount
            showRewardEditor.toggle()
        } label: {
            Text("Withdraw ")
            +
            Text(String(format: "%.2f", rewardUpdateAmount))
            +
            Text(" €")
        }
        .font(.title3)
        .accentColor(.cyan)
            Slider(value: $rewardUpdateAmount, in: 0...(userSettings?.totalReward ?? 0.0), step: 0.1) {
                Text("Slider value: \(rewardUpdateAmount)")
            } minimumValueLabel: {
                Text("0")
                    .font(.title)
                    .foregroundStyle(.cyan)
            } maximumValueLabel: {
                Text(String(format: "%.0f", userSettings?.totalReward ?? 0.0))
                    .font(.title)
                    .foregroundStyle(.cyan)
            }
            .accentColor(.cyan)
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
                        .font(.footnote)
                        .foregroundStyle(.placeholder)
                    Divider()
                    Text("\(habit.score)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
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
            }), id: \.self) { habit in
                HStack {
                    Text(habit.name)
                    Spacer()
                    Text(habit.todayScore())
                        .font(.footnote)
                        .foregroundStyle(.placeholder)
                    Divider()
                    Text("\(habit.score)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
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
            }), id: \.self) { habit in
                HStack {
                    Text(habit.name)
                    Spacer()
                    Text(habit.todayScore())
                        .font(.footnote)
                        .foregroundStyle(.placeholder)
                    Divider()
                    Text("\(habit.score)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
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
        userSettings?.ledger.forEach({ entry in
            userSettings?.totalReward -= entry.amount
        })
        habits.forEach { habit in
            habit.checkedInDays.forEach { dayStruct in
                if let reward = dayStruct.reward {
                    userSettings?.totalReward += (reward * Double(dayStruct.count))
                }
            }
        }
    }
    
    private func appendTodayStruct() {
        for (i, habit) in habits.enumerated() {
            let newDays = vm.getDays(for: habit)
            for dayStr in newDays {
                guard let interval = habit.interval.first else {return}
                if interval.key == "by week" {
                    guard let dayOfWeek = dayStr.dayOfWeek() else {return}
                    if interval.value.contains(dayOfWeek) {
                        let day = DayStruct(day: dayStr, habit: habit, state: "unchecked", reward: habit.reward)
                        modelContext.insert(day)
                        habits[i].checkedInDays.append(day)
                    } else {
                        let day = DayStruct(day: dayStr, habit: habit, state: "skiped", reward: habit.reward)
                        modelContext.insert(day)
                        habits[i].checkedInDays.append(day)
                    }
                } else if interval.key == "custom" {
                    guard interval.value.count == 2 else {return}
                    let activeDaysCount = interval.value[0]
                    let offDaysCount = interval.value[1]
                    let state = dayStr.isWorkingDay(from: habit.creationDate, active: activeDaysCount, off: offDaysCount)
                    let day = DayStruct(day: dayStr, habit: habit, state: state, reward: habit.reward)
                    modelContext.insert(day)
                    habits[i].checkedInDays.append(day)
                } else {
                    let day = DayStruct(day: dayStr, habit: habit, reward: habit.reward)
                    modelContext.insert(day)
                    habits[i].checkedInDays.append(day)
                }
            }
            habit.calculateScore()
        }
    }
}

#Preview {
    MainList()
        .modelContainer(for: Habit.self, inMemory: true)
        .environment(ViewModel())
}
