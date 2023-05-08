//
//  Next_IdeaApp.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

@main
struct Next_IdeaApp: App {
    let persistenceController = PersistenceController.shared
    
    // Things that should run when the app launches:
    init() {
        getNotificationPermissions()
//        createNotificationCategories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    private func getNotificationPermissions() { // check for notification permissions, and request them if necessary
        
        let current = UNUserNotificationCenter.current()
        
        current.getNotificationSettings(completionHandler: { permission in
            switch permission.authorizationStatus  {
            case .authorized:
                print("User has already granted permission for notifications")
            case .denied:
                print("User has denied permission for notifications")
            case .notDetermined:
                print("Notification permissions haven't been requested yet")
                // Request permissions for notifications:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        print("Notification permissions have been granted")
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                }
            case .provisional:
                // @available(iOS 12.0, *)
                print("The application is authorized to post non-interruptive user notifications")
            case .ephemeral:
                // @available(iOS 14.0, *)
                print("The application is temporarily authorized to post notifications. Only available to app clips")
            @unknown default:
                print("Unknown status on notifications")
            }
        })
    }
    
    private func createNotificationCategories() { // create the notification category and its actions
//        print("Creating notification categories")
        // Define the notification actions:
//        let complete = UNNotificationAction(identifier: "COMPLETE_ACTION", title: "Done", options: [])
        let open = UNNotificationAction(identifier: "OPEN_ACTION", title: "Open", options: [.foreground])
        
        let category = UNNotificationCategory(identifier: "TASK", actions: [open] , intentIdentifiers: []) // define the notification category, containing 2 actions
        UNUserNotificationCenter.current().setNotificationCategories([category]) // register the notification categories
    }
}
