//
//  HealthSyncHabitsApp.swift
//  HealthSyncHabits
//
//  Created by sihtmark on 20.01.2024.
//

import SwiftUI
import SwiftData

@main
struct HealthSyncHabitsApp: App {
    
    @State private var vm = ViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainList()
        }
        .modelContainer(sharedModelContainer)
        .environment(vm)
    }
}

var sharedModelContainer: ModelContainer = {
    let schema = Schema([Habit.self, UserSettings.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error.localizedDescription)")
    }
}()
