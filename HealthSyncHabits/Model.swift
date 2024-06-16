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
    let id = UUID().uuidString
    var name: String
    var creationDate: String
    var isArchived: Bool
    var countPerday: Int // сколько раз надо выполнить привычку за день в идеале
    var minCount: Int // минимальное кол-во раз за день для того чтобы засчитать привычку как выполненную
    var score: Int // сколько дней подряд выполнялась привычка без пропусков
    @Relationship(deleteRule: .cascade, inverse: \DayStruct.habit)
    var checkedInDays = [DayStruct]()
    
    // Создание новой привычки
    init(name: String, creationDate: String, minCount: Int, count: Int) {
        self.name = name
        self.creationDate = creationDate
        self.isArchived = false
        self.countPerday = count
        self.minCount = minCount
        self.score = 0
    }
    
    init() {
        self.name = ""
        self.creationDate = Date().convertToString()
        self.isArchived = false
        self.countPerday = 1
        self.minCount = 1
        self.score = 0
    }
    
    // для превью
    init(name: String, creationDate: String, minCount: Int, count: Int, checkedInDays: [DayStruct]) {
        self.name = name
        self.creationDate = creationDate
        self.isArchived = false
        self.countPerday = count
        self.minCount = minCount
        self.score = 0
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
            if currentCount < minCount {
                return .red
            } else if currentCount >= minCount && currentCount < countPerday {
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
            if checkedInDays[index].count < minCount {
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
            if checkedInDays[index].count >= minCount {
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
        let arr = checkedInDays.sorted(by: {$0.date > $1.date}).map{$0.state}
        var count = 0
        for state in arr {
            if state == "unchecked" {
                score = count
                return
            } else if state == "checked" {
                count += 1
            }
        }
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
}

struct Setings {
    var day: String
    var beginingTime: String
}
