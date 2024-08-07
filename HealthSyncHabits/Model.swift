//
//  Item.swift
//  HealthSyncHabits
//
//  Created by sihtmark on 20.01.2024.
//

import SwiftUI
import SwiftData

@Model
final class UserSettings {
    var totalReward: Double
    var ledger: [LedgerEntry]
    
    init(totalReward: Double, ledger: [LedgerEntry]) {
        self.totalReward = totalReward
        self.ledger = ledger
    }
}

@Model class LedgerEntry {
    var id: String
    var date: String
    var amount: Double
    
    init(id: String, date: String, amount: Double) {
        self.id = id
        self.date = date
        self.amount = amount
    }
}

@Model
final class Habit {
    @Attribute(.unique) var name: String
    var creationDate: String
    var isArchived: Bool
    var countPerday: Int
    var score: Int
    var interval: [String: [Int]]
    var skipOnceIn: Int
    var time: [String]
    var reward: Double?
    var bigReward: Double?
    @Relationship(deleteRule: .cascade, inverse: \DayStruct.habit) var checkedInDays = [DayStruct]()
    
    // Создание новой привычки
    init(name: String, creationDate: String, count: Int, interval: [String: [Int]], skipOnceIn: Int, time: [String], reward: Double?, bigReward: Double?) {
        self.name = name
        self.creationDate = creationDate
        self.isArchived = false
        self.countPerday = count
        self.score = 0
        self.interval = interval
        self.skipOnceIn = skipOnceIn
        self.time = time
        self.reward = reward
        self.bigReward = bigReward
    }
    
    init() {
        self.name = ""
        self.creationDate = Date().convertToString()
        self.isArchived = false
        self.countPerday = 1
        self.score = 0
        self.interval = ["daily": []]
        self.skipOnceIn = 7
        self.time = ["00-00"]
        self.reward = 0.1
        self.bigReward = 5.0
    }
    
    // для превью
    init(name: String, creationDate: String, count: Int, interval: [String: [Int]], checkedInDays: [DayStruct], time: [String]) {
        self.name = name
        self.creationDate = creationDate
        self.isArchived = false
        self.countPerday = count
        self.score = 0
        self.interval = interval
        self.skipOnceIn = 7
        self.checkedInDays = checkedInDays
        self.time = time
        self.reward = 0.3
        self.bigReward = 5.0
    }
    
    func todayScore(date: Date) -> String {
        let today = date.convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            return "\(checkedInDays[index].count) / \(countPerday)"
        }
        return "0"
    }
    
    func addRep(date: Date) {
        let today = date.convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            checkedInDays[index].count += 1
            if checkedInDays[index].count >= countPerday {
                checkedInDays[index].state = "checked"
            }
        }
    }
    
    func removeRep(date: Date) {
        let today = date.convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}), checkedInDays[index].count > 0 {
            checkedInDays[index].count -= 1
            if checkedInDays[index].count < countPerday {
                if checkedInDays[index].state == "checked" || checkedInDays[index].state == "skiped" {
                    checkedInDays[index].state = "unchecked"
                }
            }
        }
    }
    
    func canSkip() -> Bool {
        guard let interval = interval.first else {
            print("⚠️ canSkip() -> interval array is empty")
            return false
        }
        var count = 0
        if interval.key == "by week" {
            for day in checkedInDays.sorted(by: {$0.date > $1.date}) {
                if count < skipOnceIn {
                    guard let dayOfWeek = day.date.dayOfWeek() else {
                        print("⚠️ canSkip() -> by week -> dayOfWeek() return nil ")
                        return false
                    }
                    if interval.value.contains(dayOfWeek) {
                        if day.state == "skiped" {
                            return false
                        } else {
                            count += 1
                        }
                    } else {
                        count += 1
                    }
                } else {
                    return true
                }
            }
        } else if interval.key == "custom" {
            guard interval.value.count == 2 else {
                print("⚠️ canSkip() -> custom -> interval.value.count == 2 return false")
                return false
            }
            let activeDaysCount = interval.value[0]
            let offDaysCount = interval.value[1]
            for day in checkedInDays.sorted(by: {$0.date > $1.date}) {
                if count < skipOnceIn {
                    let state: Bool = day.date.isWorkingDay(from: creationDate, active: activeDaysCount, off: offDaysCount)
                    if state {
                        if day.state == "skiped" {
                            return false
                        } else {
                            count += 1
                        }
                    }
                } else {
                    return true
                }
            }
        } else if interval.key == "transformer" {
            for day in checkedInDays.sorted(by: {$0.date > $1.date}) {
                if count < skipOnceIn {
                    let state: Bool = day.date.isWorkingDay(from: creationDate, arr: interval.value)
                    if state {
                        if day.state == "skiped" {
                            return false
                        } else {
                            count += 1
                        }
                    }
                } else {
                    return true
                }
            }
        } else {
            for day in checkedInDays.sorted(by: {$0.date > $1.date}) {
                if count < skipOnceIn {
                    if day.state == "skiped" {
                        return false
                    } else {
                        count += 1
                    }
                } else {
                    return true
                }
            }
        }
        return false
    }
    
    func skip(date: Date) {
        let today = date.convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            if checkedInDays[index].count < countPerday {
                checkedInDays[index].state = "skiped"
            }
        }
    }
    
    func hide(date: Date) {
        let today = date.convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            if checkedInDays[index].count < countPerday {
                checkedInDays[index].state = "hide"
            } else {
                checkedInDays[index].state = "checked"
            }
        }
    }
    
    func unhide(date: Date) {
        let today = date.convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            checkedInDays[index].state = "unchecked"
        }
    }
    
    func canAlreadyCheck(date: Date) -> Bool {
        let today = date.convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            if checkedInDays[index].count >= countPerday {
                return true
            }
        }
        return false
    }
    
    func checkFromUnCheck(date: Date) {
        let today = date.convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            checkedInDays[index].count = countPerday
            checkedInDays[index].state = "checked"
        }
    }
    
    func uncheckFromSkiped(date: Date) {
        let today = date.convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            if checkedInDays[index].count < countPerday {
                checkedInDays[index].state = "unchecked"
            } else {
                checkedInDays[index].state = "checked"
            }
        }
    }
    
    func addRepAndReplace(date: Date) {
        let today = date.convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            checkedInDays[index].count += 1
            if checkedInDays[index].count >= countPerday {
                checkedInDays[index].state = "checked"
            } else {
                checkedInDays[index].state = "unchecked"
            }
        }
    }
    
    func calculateScore() {
        var arr = checkedInDays.sorted(by: {$0.date > $1.date}).map{$0.state}
        let first = arr.removeFirst()
        var count = 0
        for state in arr {
            if state == "unchecked" || state == "hide" {
                if first == "checked" {
                    count += 1
                }
                score = count
                return
            } else if state == "checked" {
                count += 1
            }
        }
        if first == "checked" {
            count += 1
        }
        score = count
    }
}

@Model
final class DayStruct {
    var date: String
    var state: String
    var count: Int
    var reward: Double?
    var habit: Habit?
    
    init(day: String, habit: Habit, state: String = "unchecked", reward: Double?) {
        self.date = day
        self.state = state
        self.count = 0
        self.reward = reward
        self.habit = habit
    }
    
    func replaceStatus(with newState: String) {
        state = newState
    }
}
