//
//  bsuirApp.swift
//  bsuir
//
//  Created by macbook on 13.02.26.
//

import SwiftUI
import CoreData

@main
struct bsuirApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
