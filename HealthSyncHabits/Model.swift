//
//  Item.swift
//  HealthSyncHabits
//
//  Created by sihtmark on 20.01.2024.
//

import SwiftUI
import SwiftData

@Model
final class Habit {
    @Attribute(.unique) var name: String
    var creationDate: String
    var isArchived: Bool
    var countPerday: Int
    var score: Int
    var interval: [String: [Int]]
    @Relationship(deleteRule: .cascade, inverse: \DayStruct.habit) var checkedInDays = [DayStruct]()
    
    // Создание новой привычки
    init(name: String, creationDate: String, count: Int, interval: [String: [Int]]) {
        self.name = name
        self.creationDate = creationDate
        self.isArchived = false
        self.countPerday = count
        self.score = 0
        self.interval = interval
    }
    
    init() {
        self.name = ""
        self.creationDate = Date().convertToString()
        self.isArchived = false
        self.countPerday = 1
        self.score = 0
        self.interval = ["daily": []]
    }
    
    // для превью
    init(name: String, creationDate: String, count: Int, interval: [String: [Int]], checkedInDays: [DayStruct]) {
        self.name = name
        self.creationDate = creationDate
        self.isArchived = false
        self.countPerday = count
        self.score = 0
        self.interval = interval
        self.checkedInDays = checkedInDays
    }
    
    func todayScore() -> String {
        let today = Date().convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            return "\(checkedInDays[index].count) / \(countPerday)"
        }
        return "0"
    }
    
    func todayScoreColor() -> Color {
        let today = Date().convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            let currentCount = checkedInDays[index].count
            if currentCount < countPerday {
                return .yellow
            } else if currentCount >= countPerday {
                return .green
            }
        }
        return .red
    }
    
    func addRep() {
        let today = Date().convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            checkedInDays[index].count += 1
            if checkedInDays[index].count >= countPerday {
                checkedInDays[index].state = "checked"
            }
        }
    }
    
    func removeRep() {
        let today = Date().convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}), checkedInDays[index].count > 0 {
            checkedInDays[index].count -= 1
            if checkedInDays[index].count < countPerday {
                checkedInDays[index].state = "unchecked"
            }
        }
    }
    
    func skip() {
        let today = Date().convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            checkedInDays[index].count = 0
            checkedInDays[index].state = "skiped"
        }
    }
    
    func fail() {
        let today = Date().convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            checkedInDays[index].count = 0
            checkedInDays[index].state = "failed"
        }
    }
    
    func canAlreadyCheck() -> Bool {
        let today = Date().convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            if checkedInDays[index].count >= countPerday {
                return true
            }
        }
        return false
    }
    
    func checkFromUnCheck() {
        let today = Date().convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            checkedInDays[index].state = "checked"
        }
    }
    
    func uncheckFromSkiped() {
        let today = Date().convertToString()
        if let index = checkedInDays.firstIndex(where: {$0.date == today}) {
            checkedInDays[index].state = "unchecked"
        }
    }
    
    func AddRepAndReplace() {
        let today = Date().convertToString()
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
        arr.removeFirst()
        var count = 0
        for state in arr {
            if state == "unchecked" {
                score = count
                return
            } else if state == "checked" {
                count += 1
            }
        }
        score = count
    }
}

@Model
final class DayStruct {
    var date: String
    var state: String
    var count: Int
    var habit: Habit?
    
    init(habit: Habit) {
        self.date = Date().convertToString()
        self.state = "unchecked"
        self.count = 0
        self.habit = habit
    }
    
    init(day: String, habit: Habit) {
        self.date = day
        self.state = "unchecked"
        self.count = 0
        self.habit = habit
    }
    
    func replaceStatus(with newState: String) {
        state = newState
    }
}

struct Setings {
    var day: String
    var beginingTime: String
}
