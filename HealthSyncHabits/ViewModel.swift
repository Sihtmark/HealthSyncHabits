//
//  ViewModel.swift
//  HealthSyncHabits
//
//  Created by sihtmark on 27.01.2024.
//

import SwiftUI
import SwiftData

@Observable final class ViewModel {
    
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
    
    func getDays(for habit: Habit) -> [String] {
        guard let timeZone = TimeZone(identifier: "GMT") else { return [] }
        var currentDate = self.convertToDate()
        var dates = [String]()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let endDate = calendar.startOfDay(for: Date())
        while currentDate <= endDate {
            let dateStr = currentDate.convertToString()
            if !habit.checkedInDays.contains(where: {$0.date == dateStr}) {
                dates.append(dateStr)
            }
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        return dates
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
}
