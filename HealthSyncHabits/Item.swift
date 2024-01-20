//
//  Item.swift
//  HealthSyncHabits
//
//  Created by sihtmark on 20.01.2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
