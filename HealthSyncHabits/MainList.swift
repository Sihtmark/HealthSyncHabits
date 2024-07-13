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
    @State private var showRewardEditor = false
    @State private var showChecked = false
    @State private var showSkipped = false
    @State private var showHidden = false
    @State private var rewardString = ""
    @FocusState private var focus: Bool
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                if showRewardEditor {
                    rewardSlider
                }
                uncheckedSection
                if showChecked {
                    checkedSection
                }
                if showSkipped {
                    skipedSection
                }
                if showHidden {
                    hiddenSection
                }
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
                            Text("🏆")
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
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            withAnimation(.smooth) {
                                showChecked.toggle()
                            }
                        } label: {
                            Label("Completed", systemImage: showChecked ? "checkmark.circle" : "circle")
                        }
                        Button {
                            withAnimation(.smooth) {
                                showSkipped.toggle()
                            }
                        } label: {
                            Label("Skipped", systemImage: showSkipped ? "checkmark.circle" : "circle")
                        }
                        Button {
                            withAnimation(.smooth) {
                                showHidden.toggle()
                            }
                        } label: {
                            Label("Hidden", systemImage: showHidden ? "checkmark.circle" : "circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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
        Section {
            HStack(spacing: 20) {
                TextField("Add amount...", text: $rewardString)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .focused($focus, equals: true)
                    .keyboardType(.decimalPad)
                Button {
                    withAnimation(.smooth) {
                        focus = false
                    }
                    if let amount = Double(rewardString.replacingOccurrences(of: ",", with: ".")), amount <= userSettings?.totalReward ?? 0.0 {
                        let newEntry = LedgerEntry(
                            id: UUID().uuidString,
                            date: Date().convertToString(),
                            amount: amount
                        )
                        modelContext.insert(newEntry)
                        self.userSettings?.ledger.append(newEntry)
                        userSettings?.totalReward -= amount
                        rewardString = ""
                    }
                    withAnimation(.smooth) {
                        showRewardEditor.toggle()
                    }
                } label: {
                    Text("Withdraw")
                        .foregroundStyle(.white)
                }
                .disabled(Double(rewardString.replacingOccurrences(of: ",", with: ".")) ?? 0.0 > userSettings?.totalReward ?? 0.0 || Double(rewardString.replacingOccurrences(of: ",", with: ".")) ?? 0.0 == 0.0)
                .font(.title3)
                .buttonStyle(.borderedProminent)
            }
        } footer: {
            if Double(rewardString.replacingOccurrences(of: ",", with: ".")) ?? 0.0 > userSettings?.totalReward ?? 0.0 {
                Text("⚠️ Max \(String(format: "%.2f", userSettings?.totalReward ?? 0.0)) € ‼️")
                    .foregroundStyle(.red)
            } else {
                Text("Max \(String(format: "%.2f", userSettings?.totalReward ?? 0.0)) €")
                    .foregroundStyle(.orange)
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
                    Button("Hide") {
                        habit.hide()
                    }
                    .tint(.blue)
                    if habit.canSkip() {
                        Button("Skip") {
                            let today = Date().convertToString()
                            if let index = habit.checkedInDays.firstIndex(where: {$0.date == today}), let reward = habit.reward {
                                userSettings?.totalReward -= (Double(habit.checkedInDays[index].count) * reward)
                            }
                            habit.skip()
                            habit.calculateScore()
                        }
                        .tint(.red)
                    }
                }
            }
        } header: {
            Text("☑️ Unchecked")
                .foregroundStyle(.black)
                .font(.subheadline)
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
                    if habit.canSkip() {
                        Button("Skip", role: .cancel) {
                            let today = Date().convertToString()
                            if let index = habit.checkedInDays.firstIndex(where: {$0.date == today}), let reward = habit.reward {
                                userSettings?.totalReward -= (Double(habit.checkedInDays[index].count) * reward)
                            }
                            habit.skip()
                            habit.calculateScore()
                        }
                        .tint(.red)
                    }
                }
            }
        } header: {
            Text("✅ Checked")
                .foregroundStyle(.black)
                .font(.subheadline)
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
                    Button("Uncheck") {
                        habit.uncheckFromSkiped()
                        habit.calculateScore()
                    }
                    .tint(.cyan)
                }
            }
        } header: {
            Text("❌ Skiped")
                .foregroundStyle(.black)
                .font(.subheadline)
        }
    }
    
    private var hiddenSection: some View {
        Section {
            ForEach(habits.filter({ habit in
                let today = Date().convertToString()
                if let day = habit.checkedInDays.first(where: {$0.date == today}) {
                    return day.state == "hide"
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
                    Button("Unhide") {
                        habit.unhide()
                    }
                    .tint(.blue)
                    if habit.canSkip() {
                        Button("Skip") {
                            let today = Date().convertToString()
                            if let index = habit.checkedInDays.firstIndex(where: {$0.date == today}), let reward = habit.reward {
                                userSettings?.totalReward -= (Double(habit.checkedInDays[index].count) * reward)
                            }
                            habit.skip()
                            habit.calculateScore()
                        }
                        .tint(.red)
                    }
                }
            }
        } header: {
            Text("🫣 Hidden")
                .foregroundStyle(.black)
                .font(.subheadline)
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
                    let state: String = dayStr.isWorkingDay(from: habit.creationDate, active: activeDaysCount, off: offDaysCount)
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
