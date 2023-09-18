//
//  Next_IdeaApp.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

@main

/*class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set up your Core Data stack here
        
        // Set the delegate for handling notifications
        UNUserNotificationCenter.current().delegate = self
        
        // Register for remote notifications here
        
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "CompleteAction" {
            // Handle the "Complete Task" action
            if let taskId = response.notification.request.content.userInfo["taskID"] as? UUID {
                completeTask(withID: taskId)
            }
        }
        
        completionHandler()
    }
    
    func completeTask(withID taskId: UUID) {
        // Obtain your managed object context from your Core Data stack
        let context = persistentContainer.viewContext
        
        // Fetch the task with the given ID
        if let task = try? context.fetch(Task.fetchRequest(withID: taskId)).first as? Task {
            // Set the task's 'completed' attribute to true
            task.completed = true
            
            // Save the changes to Core Data
            do {
                try context.save()
            } catch {
                // Handle the error appropriately
                print("Error saving to Core Data: \(error.localizedDescription)")
            }
        }
    }
}*/


struct Next_IdeaApp: App {
    let persistenceController = PersistenceController.shared
    
    // Things that should run when the app launches:
    init() {
        getNotificationPermissions()
        createNotificationCategories()
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
        
        let completeAction = UNNotificationAction(
            identifier: "CompleteAction",
            title: "Complete Task",
            options: [.foreground]
        )
        
        let category = UNNotificationCategory(
            identifier: "TASK",
            actions: [completeAction],
            intentIdentifiers: [],
            options: []
        ) // define the notification category
        
        UNUserNotificationCenter.current().setNotificationCategories([category]) // register the notification categories
    }
}
