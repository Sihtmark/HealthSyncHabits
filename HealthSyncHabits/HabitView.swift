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
    @Query var habits: [Habit]
    @Bindable var habit: Habit
    @State var name: String
    @State var pickerDate: Date
    @State var skipDayCount = 7
    @State var countPerDay: Int
    @State var showTimeSection: Bool
    @State var showRewardSection: Bool
    @State var timeArray: [String]
    @State var smallReward: Double
    @State var bigReward: Double
    let statusArray = ["unchecked", "checked", "skiped"]
    @State private var deleteAlert = false
    let columns = Array(repeating: GridItem(.fixed(25), spacing: 3.5, alignment: nil), count: 7)
    
    // Interval
    @State var pickedInterval: String
    let intervalArray = ["daily", "by week", "custom", "transformer"]
    let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    @State var pickedWeekDays: [Int]
    @State var activeDaysCount: Int
    @State var offDaysCount: Int
    @State var transformerCount: Int
    @State var transformerArray: [Int]
    let emptyItems: Int
    @State private var intervalDidChanged = false
    
    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 2021, month: 1, day: 1)
        return calendar.date(from:startComponents)!
        ...
        Date()
    }()
    
    var habitUpdated: Bool {
        return name != habit.name ||
        pickerDate.convertToString() != habit.creationDate ||
        countPerDay != habit.countPerday ||
        skipDayCount != habit.skipOnceIn ||
        timeArray != habit.time ||
        smallReward != habit.reward ||
        bigReward != habit.bigReward ||
        pickedInterval != habit.interval.first?.key ||
        intervalDidChanged
    }
    
    var body: some View {
        List {
            scoreByCalendarView
            nameSection
            dateSection
            toggleSection
            if showTimeSection {
                timeSection
            }
            if showRewardSection {
                rewardSection
            }
            deleteSection
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    updateHabit()
                }
                .disabled(!habitUpdated)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .onChange(of: pickedWeekDays, { oldValue, newValue in
            intervalDidChanged = true
        })
        .onChange(of: activeDaysCount, { oldValue, newValue in
            intervalDidChanged = true
        })
        .onChange(of: offDaysCount, { oldValue, newValue in
            intervalDidChanged = true
        })
        .onChange(of: countPerDay) { oldValue, newValue in
            if oldValue < newValue {
                for _ in 0..<(newValue - oldValue) {
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
        .onChange(of: transformerCount, { oldValue, newValue in
            intervalDidChanged = true
        })
        .onChange(of: transformerArray, { oldValue, newValue in
            intervalDidChanged = true
        })
        .onChange(of: transformerCount) { oldValue, newValue in
            if oldValue < newValue {
                withAnimation {
                    while transformerArray.count != newValue {
                        transformerArray.append(0)
                    }
                }
            } else if oldValue > newValue {
                withAnimation {
                    while transformerArray.count != newValue {
                        transformerArray.removeLast()
                    }
                }
            }
        }
        .alert("Are you shure you want to delete this habit?", isPresented: $deleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(habit)
                dismiss()
            }
        }
    }
    
    private func updateHabit() {
        var interval: [String: [Int]] = [:]
        if pickedInterval == "daily" {
            interval = ["daily": []]
        } else if pickedInterval == "by week" {
            interval = ["by week": pickedWeekDays]
        } else if pickedInterval == "custom" {
            interval = ["custom": [activeDaysCount, offDaysCount]]
        } else if pickedInterval == "transformer" {
            interval = ["transformer": transformerArray]
        }
        if pickerDate.convertToString() < habit.creationDate {
            let newDaysStr = vm.getDays(for: habit, changing: pickerDate)
            var newDays = [DayStruct]()
            for dayStr in newDaysStr {
                guard let interval = interval.first else {return}
                if interval.key == "by week" {
                    guard let dayOfWeek = dayStr.dayOfWeek() else {return}
                    if interval.value.contains(dayOfWeek) {
                        let day = DayStruct(day: dayStr, habit: habit, state: "unchecked", reward: nil)
                        newDays.append(day)
                        modelContext.insert(day)
                    } else {
                        let day = DayStruct(day: dayStr, habit: habit, state: "skiped", reward: nil)
                        newDays.append(day)
                        modelContext.insert(day)
                    }
                } else if interval.key == "custom" {
                    guard interval.value.count == 2 else {return}
                    let activeDaysCount = interval.value[0]
                    let offDaysCount = interval.value[1]
                    let state: String = dayStr.isWorkingDay(from: pickerDate.convertToString(), active: activeDaysCount, off: offDaysCount)
                    let day = DayStruct(day: dayStr, habit: habit, state: state, reward: showRewardSection ? smallReward : nil)
                    newDays.append(day)
                    modelContext.insert(day)
                } else if interval.key == "transformer" {
                    let state: String = dayStr.isWorkingDay(from: pickerDate.convertToString(), arr: interval.value)
                    let day = DayStruct(day: dayStr, habit: habit, state: state, reward: showRewardSection && dayStr == Date().convertToString() ? smallReward : nil)
                    newDays.append(day)
                    modelContext.insert(day)
                } else {
                    let day = DayStruct(day: dayStr, habit: habit, reward: nil)
                    newDays.append(day)
                    modelContext.insert(day)
                }
            }
            habit.checkedInDays.append(contentsOf: newDays)
        } else {
            habit.checkedInDays.forEach { day in
                if day.date < pickerDate.convertToString() {
                    modelContext.delete(day)
                }
            }
        }
        habit.name = name
        habit.creationDate = pickerDate.convertToString()
        habit.countPerday = countPerDay
        habit.skipOnceIn = skipDayCount
        habit.interval = interval
        habit.time = timeArray
        habit.reward = showRewardSection ? smallReward : nil
        habit.bigReward = showRewardSection ? bigReward : nil
        dismiss()
    }
    
    var nameSection: some View {
        Section {
            TextField("Add your habit name here...", text: $name)
        } footer: {
            if habit.name != name {
                if habits.contains(where: {$0.name == name}) && habit.name != name  {
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
        }
    }
    
    var dateSection: some View {
        Section {
            DatePicker("Starts from:", selection: $pickerDate, in: dateRange, displayedComponents: .date)
            Picker("Day interval:", selection: $pickedInterval) {
                ForEach(intervalArray, id: \.self) { interval in
                    Text(interval)
                        .tag(interval)
                }
            }
            .pickerStyle(.menu)
            if pickedInterval == "by week" {
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
            } else if pickedInterval == "custom" {
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
            } else if pickedInterval == "transformer" {
                VStack {
                    Picker("Total days in one set:", selection: $transformerCount) {
                        ForEach(5..<101) { index in
                            Text(String(index))
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(Array(transformerArray.enumerated()), id: \.offset) { index, value in
                                Button {
                                    transformerArray[index] = value == 0 ? 1 : 0
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(value == 1 ? Color.accentColor : Color.orange.opacity(0.4))
                                            .frame(width: 50, height: 40)
                                        Text("\(index + 1)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                }
                                .foregroundStyle(.white)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollClipDisabled()
                }
            }
            HStack {
                Picker("Can skip once in:", selection: $skipDayCount) {
                    ForEach(0..<101) { index in
                        Text("\(index) days").tag(index)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    var toggleSection: some View {
        Section {
            Picker("Reps per day:", selection: $countPerDay) {
                ForEach(0..<101) { index in
                    Text(String(index))
                        .tag(index)
                }
            }
            .pickerStyle(.menu)
            Toggle("Set time", isOn: $showTimeSection)
            Toggle("Set reward", isOn: $showRewardSection)
        }
    }
    
    var timeSection: some View {
        Section {
            ForEach(Array(timeArray.enumerated()), id: \.offset) { key, value in
                TimePickerCell(time: value.convertTime() ?? Date(), index: key + 1) { time in
                    timeArray[key] = time
                }
            }
        } footer: {
            Text("Choose time for each rep")
        }
    }
    
    var rewardSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("For each rep:   ")
                +
                Text(String(format: "%.2f", smallReward))
                    .foregroundStyle(.cyan)
                    .font(.title3)
                    .fontWeight(.medium)
                +
                Text(" €")
                    .foregroundStyle(.cyan)
                    .font(.title3)
                    .fontWeight(.medium)
                Slider(value: $smallReward, in: 0.1...3, step: 0.1) {
                    Text("Slider value: \(smallReward)")
                } minimumValueLabel: {
                    Image(systemName: "0.square")
                        .font(.title)
                        .foregroundStyle(.cyan)
                } maximumValueLabel: {
                    Image(systemName: "3.square.fill")
                        .font(.title)
                        .foregroundStyle(.cyan)
                }
                .accentColor(.cyan)
            }
            VStack(alignment: .leading) {
                Text("For every 21 days:   ")
                +
                Text(String(format: "%.2f", bigReward))
                    .foregroundStyle(.orange)
                    .font(.title3)
                    .fontWeight(.medium)
                +
                Text(" €")
                    .foregroundStyle(.orange)
                    .font(.title3)
                    .fontWeight(.medium)
                Slider(value: $bigReward, in: 3...30, step: 1.0) {
                    Text("Slider value: \(bigReward)")
                } minimumValueLabel: {
                    Image(systemName: "3.square")
                        .font(.title)
                        .foregroundStyle(.orange)
                } maximumValueLabel: {
                    Image(systemName: "30.square.fill")
                        .font(.title)
                        .foregroundStyle(.orange)
                }
                .accentColor(.orange)
            }
        }
    }
    
    var deleteSection: some View {
        Section {
            Button("Delete this habit", role: .destructive) {
                deleteAlert.toggle()
            }
        }
    }
    
    var scoreByCalendarView: some View {
        Section {
        } footer: {
            ScrollView(.horizontal) {
                LazyHGrid(rows: columns, alignment: .center, spacing: 3.5, content: {
                    ForEach(0..<emptyItems) { _ in
                        RoundedRectangle(cornerRadius: 3.5)
                            .fill(Color.black.opacity(0.001))
                            .frame(width: 25)
                    }
                    ForEach(habit.checkedInDays.sorted(by: {$0.date < $1.date}), id: \.self) { day in
                        Menu {
                            if day.state != "skiped" {
                                Button("Skip") {
                                    day.state = "skiped"
                                    day.count = 0
                                    habit.calculateScore()
                                }
                            }
                            if day.state != "checked" {
                                Button("Check") {
                                    day.state = "checked"
                                    day.count = habit.countPerday
                                    habit.calculateScore()
                                }
                            }
                            if day.state != "unchecked" {
                                Button("Uncheck") {
                                    day.state = "unchecked"
                                    day.count = 0
                                    habit.calculateScore()
                                }
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: 3.5)
                                .fill(scoreVisionCellColor(dayStruct: day))
                                .frame(width: 25)
                        }
                    }
                })
                .flipsForRightToLeftLayoutDirection(true)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal, 20)
            }
            .flipsForRightToLeftLayoutDirection(true)
            .environment(\.layoutDirection, .rightToLeft)
            .scrollIndicators(.hidden)
//            .listRowInsets(EdgeInsets())
            .frame(width: UIScreen.main.bounds.width)
            .listRowInsets(EdgeInsets())
            .ignoresSafeArea()
            .padding(.vertical)
            .background(.ultraThickMaterial)
            .background(LinearGradient(colors: [.orange, .yellow, .green, .cyan, .blue, .pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .padding(.top, -15)
        .padding(.bottom)
    }
    
    func scoreVisionCellColor(dayStruct: DayStruct) -> Color {
        if dayStruct.state == "checked" {
            return Color.green
        } else if dayStruct.state == "skiped" {
            return Color.yellow
        } else {
            return .secondary
        }
    }
}

#Preview {
    HabitView(
        habit: Habit(name: "Yoga", creationDate: "2024-03-19", count: 2, interval: ["daily": []], checkedInDays: [], time: ["30-06", "55-18"]),
        name: "Yoga",
        pickerDate: "2024-03-19".convertToDate(),
        countPerDay: 2,
        showTimeSection: true,
        showRewardSection: true,
        timeArray: ["30-06", "55-18"],
        smallReward: 0.3,
        bigReward: 5.0,
        pickedInterval: "by week",
        pickedWeekDays: [1, 5],
        activeDaysCount: 1,
        offDaysCount: 1,
        transformerCount: 7,
        transformerArray: Array(repeating: 0, count: 7), 
        emptyItems: 3
    )
    .modelContainer(for: Habit.self, inMemory: true)
    .environment(ViewModel())
}
