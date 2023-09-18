//
//  ContentView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI
import CoreData
import UserNotifications
import EventKit // to be able to access reminders and calendars

final class Tab: ObservableObject {
    @Published var selection: Int = 1
}

final class WeeklyReview: ObservableObject {
    @Published var active = false
}

final class HomeActiveView: ObservableObject {
    @Published var stringName: String = "Home"
    
    func iconString(viewName: String) -> String {
        switch(viewName) {
        case "Home":
            return "house"
        case "All tasks":
            return "list.bullet"
        case "Inbox":
            return "tray"
        case "Focus":
            return "scope"
        case "Due":
            return "calendar"
        case "Next":
            return "terminal.fill"
        case "Waiting for":
            return "person.badge.clock"
        case "Deferred":
            return "calendar.badge.clock"
        case "Someday":
            return "text.append"
        case "Search":
            return "magnifyingglass"
        case "Completed":
            return "checkmark.circle"
        default:
            return "tray"
        }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task> // to be able to verify notifications and count tasks
    
    class EventKitManager: ObservableObject { // to access reminders and calendars
        var eventStore = EKEventStore()
        @Published var reminderLists: [EKCalendar] = []
        @Published var importActive = false
        @Published var selectedList: EKCalendar? = nil
        @Published var reminders: [EKReminder] = []
        
        init() {
            if EKEventStore.authorizationStatus(for: .reminder) == .authorized { // if the user has authorized the import of reminders, get the reminder list from Apple Reminders:
                getReminderCalendars()
            }
        }
        
        func requestRemindersAccess() {
            eventStore.requestAccess(to: .reminder) { success, error in
                self.eventStore = EKEventStore()
            }
        }
        
        func getReminderCalendars() {
            self.reminderLists = eventStore.calendars(for: .reminder)
        }
        
        func completeReminder(reminder: EKReminder) {
            reminder.isCompleted = true
            
            do {
                try eventStore.save(reminder, commit: true)
            } catch {
                print("Saving reminder failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    @StateObject var eventKitManager = EventKitManager() // create the object
    
    @StateObject var tab = Tab()
    
    @StateObject var homeActiveView = HomeActiveView()
    
    @StateObject var weeklyReview = WeeklyReview()
    
    @State private var showSearchView = false

    var body: some View {
        TabView(selection: $tab.selection) {
            
            HomeView()
                .tabItem {
                    Label(homeActiveView.stringName, systemImage: homeActiveView.iconString(viewName: homeActiveView.stringName))
                }
                .tag(0)
            
            NavigationStack {
                ProjectListView()
            }
            .tabItem {
                Label("Projects", systemImage: "book")
            }
            .tag(1)
            
            ListView(title: "Next")
                .tabItem {
                    Label("Next actions", systemImage: "terminal.fill")
                }
                .tag(2)
            
//            ListView(title: "All tasks")
//                .tabItem {
//                    Label("All tasks", systemImage: "play")
//                }
//                .tag(2)
            
            NavigationStack {
                TagListView()
            }
            .tabItem {
                Label("Tags", systemImage: "tag")
            }
            .tag(3)
        }
        .onAppear {
            // Import new reminders from Apple Reminders - once on startup, then every x minutes while the app is in the foreground, and whenever it returns from the background:
            
            importReminders()
            
            Timer.scheduledTimer(withTimeInterval: 1 * 60, repeats: true) { timer in
                importReminders()
            }
        }
        .environmentObject(eventKitManager) // put the reminder lists and reminders in the environment
        .environmentObject(tab) // make the tab selection available to other views
        .environmentObject(homeActiveView) // make the view selected in Home available to other views
        .environmentObject(weeklyReview) // make the weekly review activation status available to other views
        .onAppear {
            // Verify if some notifications need to be cancelled or created:
            verifyNotifications()
            
            // Verify notifications every x minutes while the app is in the foreground, and whenever it returns from the background if the time interval has passed:
            Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { timer in
                verifyNotifications()
            }
        }
        .preferredColorScheme(.light)
    }
    
    private func verifyNotifications() { // go through notifications and items and check that they match, in case something has been changed on another device
        
        // Go through all pending notifications and check if some should be cancelled - either because the task doesn't exist anymore or is completed:
        print("Going through all pending notifications to check if some should be cancelled")
        
        var foundValidItem = false
        
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
            for request in requests {
                foundValidItem = false
                
                for task in tasks {
                    if String(describing: task.id) == request.identifier {
//                        print("Found an item with notification id \(request.identifier): \(task.name ?? "")")
                        if !task.completed {
//                            print("Task isn't completed -> OK")
                            foundValidItem = true
                            break
                        }
                    }
                }
                
                // If an item with that notificationid wan't found, or the task was completed, or the timer isn't running anymore, cancel the pending notification:
                if !foundValidItem {
                    print("Canceling notification \(request.identifier) for item \(request.content.subtitle)")
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
                }
            }
        })
        
        // Go through all items that are not completed and have a reminder, and check that they have a pending notification, otherwise create it if the date is in the future:
        print("Going through all items that are not completed and have a reminder to check that they have a pending notification")
        for task in tasks.filter({ !$0.completed && $0.reminderactive}) {
//            print("Item \(item.name ?? "") has a notificationid: \(item.notificationid ?? "") ")
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
                if requests.filter({$0.identifier == String(describing: task.id)}).count == 0 { // if no pending notification is found
                    if task.date ?? Date() > Date() { // if the date is in the future, create a notification
                        print("Notification missing for \(task.name ?? ""). Creating it")
                        task.createNotification()
                    }
                    else {
//                        print("Notification missing for \(task.name ?? ""). Not creating it, as the date is in the past")
                    }
                }
                else {
//                    print("Pending notification found for \(task.name ?? ""). Doing nothing")
                }
            })
        }
    }
    
    private func importReminders() { // import new reminders from Apple Reminders
//        print("Attempting to import reminders")
        eventKitManager.importActive = UserDefaults.standard.bool(forKey: "RemindersImportActive")
        
//        print("Import active: \(eventKitManager.importActive)")
        
        if eventKitManager.importActive {
            
            let selectedListId = UserDefaults.standard.string(forKey: "RemindersSelectedList")
            if selectedListId != nil && eventKitManager.reminderLists.filter({$0.calendarIdentifier == selectedListId}).count > 0 { // if there is a list saved, find it in the array of lists fetched from Reminders, if there are any:
                eventKitManager.selectedList = eventKitManager.reminderLists.filter({$0.calendarIdentifier == selectedListId})[0]
            }
//            print("Selected list: \(eventKitManager.selectedList?.title ?? "")")
            if eventKitManager.selectedList != nil { // if the import is active in the settings, and a default list has been selected
                let predicate = eventKitManager.eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [eventKitManager.selectedList!])
                
                eventKitManager.eventStore.fetchReminders(matching: predicate) { results in
                    if let results = results {
                        DispatchQueue.main.async {
                            eventKitManager.reminders = results
//                            print("Importing \(eventKitManager.reminders.count) reminders from list \(eventKitManager.selectedList!.title)")
                            
                            for reminder in eventKitManager.reminders {
//                                print(reminder.title ?? "")
                                // Create a new item in the inbox, and save it:
                                let task = Task(context: viewContext)
                                task.id = UUID()
                                task.order = (tasks.first?.order ?? 0) - 1 // add it to the top
                                task.name = reminder.title ?? ""
                                task.dateactive = false
                                task.reminderactive = false
                                task.hideuntildate = false
                                task.waitingfor = false
                                task.someday = false
                                task.focus = false
                                task.recurring = false
                                task.recurrence = 1
                                task.recurrencetype = "days"
                                task.link = ""
                                task.nextreviewdate = Date()
                                task.modifieddate = Date()
                                
                                // Complete the task in Reminders:
                                eventKitManager.completeReminder(reminder: reminder)
                            }
                            
                            // Save the new tasks:
                            PersistenceController.shared.save()
                        }
                    }
                }
            }
        }
        
        
//        for reminder in eventKitManager.reminders {
//            print(reminder.title ?? "")
//            // Create a new item in the inbox, and save it:
//            let item = Item(context: viewContext)
//            let itemOrder: Int64
//            itemOrder = (items.first?.order ?? 0) - 1 // add it to the top
//            item.populate(name: reminder.title ?? "", list: "Inbox", order: itemOrder, project: nil, itemlabel: nil, url: "", linkname: "", dateActive: false, reminderActive: false, deferred: false, recurrenceActive: false, recurrence: 0, recurrenceType: "days", date: Date(), reminderTime: Date(), goodHabit: true, points: 0, perMinute: false, multipleOccurrences: false)
////            PersistenceController.shared.save()
//
//            // Complete the task in Reminders:
////            eventKitManager.completeReminder(reminder: reminder)
//        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
