//
//  ViewModel.swift
//  HealthSyncHabits
//
//  Created by sihtmark on 27.01.2024.
//

import SwiftUI
import SwiftData

@Observable final class ViewModel {
    func getDays(for habit: Habit, changing: Date? = nil) -> [String] {
        guard let timeZone = TimeZone(identifier: "GMT") else { return [] }
        var habitCreationDate = habit.creationDate.convertToDate()
        var dates = [String]()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var endDate: Date
        if var changing {
            let newCreationDate = changing.convertToString()
            let date = calendar.startOfDay(for: habitCreationDate)
            endDate = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            
            while changing <= endDate {
                let dateStr = changing.convertToString()
                if !habit.checkedInDays.contains(where: {$0.date == dateStr}) {
                    dates.append(dateStr)
                }
                if let nextDate = calendar.date(byAdding: .day, value: 1, to: changing) {
                    changing = nextDate
                } else {
                    break
                }
            }
        } else {
            endDate = calendar.startOfDay(for: Date())
            while habitCreationDate <= endDate {
                let dateStr = habitCreationDate.convertToString()
                if !habit.checkedInDays.contains(where: {$0.date == dateStr}) {
                    dates.append(dateStr)
                }
                if let nextDate = calendar.date(byAdding: .day, value: 1, to: habitCreationDate) {
                    habitCreationDate = nextDate
                } else {
                    break
                }
            }
        }
        return dates
    }
    
    private func scoreColor(score: Int) -> Color {
        switch score {
        case 0..<7:
            return .orange
        case 7..<14:
            return .green
        case 14..<21:
            return .cyan
        case 21..<28:
            return .blue
        default:
            return .pink
        }
    }
}

extension Date {
    func convertToString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self)
    }
    
    func timeToString() -> String {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "HH-mm"
        return dateformatter.string(from: self)
    }
}

extension String {
    func dayOfWeek() -> Int? {
        let week = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let date = self.convertToDate()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.string(from: date)
        return week.firstIndex(where: {$0 == dayOfWeek})
    }
    
    func convertToDate() -> Date {
        let dateFormatter = DateFormatter()
        guard let timeZone = TimeZone(identifier: "GMT") else { return Date() }
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: self) {
            return date
        } else {
            return Date()
        }
    }
    
    func isWorkingDay(from creationDate: String, active: Int, off: Int) -> String {
        guard let timeZone = TimeZone(identifier: "GMT") else { return "unchecked"}
        let startDate = creationDate.convertToDate() // Your first day of work
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let diff = calendar.dateComponents([.day], from: startDate, to: self.convertToDate()).day!
        let mod = diff % (active + off)
        return mod < active ? "unchecked" : "skiped"
    }
    
    func isWorkingDay(from creationDate: String, arr: [Int]) -> String {
        guard let timeZone = TimeZone(identifier: "GMT") else { return "unchecked"}
        let startDate = creationDate.convertToDate() // Your first day of work
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let diff = calendar.dateComponents([.day], from: startDate, to: self.convertToDate()).day!
        let mod = diff % arr.count
        return arr[mod] == 1 ? "unchecked" : "skiped"
    }
    
    func isWorkingDay(from creationDate: String, active: Int, off: Int) -> Bool {
        guard let timeZone = TimeZone(identifier: "GMT") else { return true}
        let startDate = creationDate.convertToDate() // Your first day of work
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let diff = calendar.dateComponents([.day], from: startDate, to: self.convertToDate()).day!
        let mod = diff % (active + off)
        return mod < active
    }
    
    func isWorkingDay(from creationDate: String, arr: [Int]) -> Bool {
        guard let timeZone = TimeZone(identifier: "GMT") else { return true}
        let startDate = creationDate.convertToDate() // Your first day of work
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let diff = calendar.dateComponents([.day], from: startDate, to: self.convertToDate()).day!
        let mod = diff % arr.count
        return arr[mod] == 1 
    }
    
    func userFriendlyDate() -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inputFormatter.date(from: self) else {
            return nil
        }
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .short
        outputFormatter.timeStyle = .none
        let userFriendlyDateString = outputFormatter.string(from: date)
        return userFriendlyDateString
    }
}

extension Dictionary {
    mutating func switchKey(fromKey: Key, toKey: Key) {
        if let entry = removeValue(forKey: fromKey) {
            self[toKey] = entry
        }
    }
}
