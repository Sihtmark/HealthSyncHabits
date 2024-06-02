//
//  Item.swift
//  HealthSyncHabits
//
//  Created by sihtmark on 20.01.2024.
//

import Foundation
import SwiftData

@Model
final class Habit {
    let id = UUID().uuidString
    var name: String
    var creationDate: Date
    var isArchived: Bool
    var countPerday: Int // сколько раз надо выполнить привычку за день в идеале
    var minCount: Int // минимальное кол-во раз за день для того чтобы засчитать привычку как выполненную
    var score: Int // сколько дней подряд выполнялась привычка без пропусков
    var checkedInDays = [Day]()
    
    init(name: String, creationDate: Date, minCount: Int, count: Int) {
        self.name = name
        self.creationDate = creationDate
        self.isArchived = false
        self.countPerday = count
        self.minCount = minCount
        self.score = 0
    }
    
    init() {
        self.name = ""
        self.creationDate = Date()
        self.isArchived = false
        self.countPerday = 1
        self.minCount = 1
        self.score = 0
    }
    
    init(name: String, creationDate: Date, minCount: Int, count: Int, checkedInDays: [Day]) {
        self.name = name
        self.creationDate = creationDate
        self.isArchived = false
        self.countPerday = count
        self.minCount = minCount
        self.score = 0
        self.checkedInDays = checkedInDays
    }
}

@Model
final class Day {
    let id = UUID().uuidString
    var date: Date
    var state: DayType
    var count: Int
    
    init(date: Date, state: DayType, count: Int) {
        self.date = date
        self.state = state
        self.count = count
    }
}


enum DayType: Codable {
    case unchecked
    case skiped
    case failed
    case checked
}
