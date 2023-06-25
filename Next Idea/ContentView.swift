//
//  ContentView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI
import CoreData
import UserNotifications

final class Tab: ObservableObject {
    @Published var selection: Int = 2
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task> // to be able to verify notifications and count tasks
    
    @StateObject var tab = Tab()
    
    @State private var showSearchView = false

    var body: some View {
        TabView(selection: $tab.selection) {
            
            ListView(list: 0, showDeferred: false)
                .tabItem {
                    Label("Inbox", systemImage: "tray")
                }
                .tag(0)
            
            NavigationStack {
                ProjectListView()
            }
            .tabItem {
                Label("Projects", systemImage: "book")
            }
            .tag(1)
            
            ListView(list: 2, showDeferred: false)
                .tabItem {
                    Label("Next", systemImage: "terminal.fill")
                }
                .tag(2)
            
            ListView(list: 3, showDeferred: false)
                .tabItem {
                    Label("Someday", systemImage: "text.append")
                }
                .tag(3)
            
            NavigationStack {
                TagListView()
            }
            .tabItem {
                Label("Tags", systemImage: "tag")
            }
            .tag(4)
            
        }
            
//            NavigationLink {
//                ListView(list: 1, showDeferred: false)
//            } label: {
//                HStack {
//                    Text("Now")
//                    Spacer()
//                    Text("\(countTasks(list: 1))")
//                }
//            }
            
//            ListView(list: 1, showDeferred: false)
//                .tabItem {
//                    Label("Now", systemImage: "scope")
//                }
//                .tag(2)
            
            
//            FocusView()
//                .tabItem {
//                    Label("Focus", systemImage: "scope")
//                }
            
//            NavigationStack {
//                List {
                    
//                    NavigationLink {
//                        ListView(list: 0, showDeferred: false)
//                    } label: {
//                        HStack {
//                            Text("Inbox")
//                            Spacer()
//                            Text("\(countTasks(list: 0))")
//                        }
//                    }
                    
//                    NavigationLink {
//                        ListView(list: 1, showDeferred: false)
//                    } label: {
//                        HStack {
//                            Text("Now")
//                            Spacer()
//                            Text("\(countTasks(list: 1))")
//                        }
//                    }
                    
//
//                    NavigationLink {
//                        ListView(list: 2, showDeferred: false)
//                    } label: {
//                        HStack {
//                            Text("Next")
//                            Spacer()
//                            Text("\(countTasks(list: 2))")
//                        }
//                    }
//
//                    NavigationLink {
//                        ListView(list: 3, showDeferred: false)
//                    } label: {
//                        HStack {
//                            Text("Someday")
//                            Spacer()
//                            Text("\(countTasks(list: 3))")
//                        }
//                    }
//
//                    NavigationLink {
//                        WaitingForView()
//                    } label: {
//                        HStack {
//                            Text("Waiting for")
//                            Spacer()
//                            Text("\(countTasks(list: 4))")
//                        }
//                    }
//                }
//                .navigationTitle("Tasks")
//                .navigationBarTitleDisplayMode(.inline)
//                .sheet(isPresented: $showSearchView) {
//                    SearchView()
//                }
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        Button {
//                            showSearchView.toggle()
//                        } label: {
//                            Label("", systemImage: "magnifyingglass")
//                        }
//                    }
//                }
//            }
//            .tabItem {
//                Label("Tasks", systemImage: "play.fill")
//            }
//            .tag(3)
            
            
//            NavigationStack {
//                TagListView()
//            }
//                .tabItem {
//                    Label("Tags", systemImage: "tag")
//                }
//                .tag(4)
            
//            SearchView()
//                .tabItem {
//                    Label("Search", systemImage: "magnifyingglass")
//                }
//                .tag(5)
            
//            HomeView()
//                .tabItem {
//                    Label("Home", systemImage: "house")
//                }
//                .tag(4)
//        }
        
        /*
        TabView(selection: $tab.selection) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(9)
            
            ListView(list: 0, showDeferred: false)
                .tabItem {
                    Label("Inbox", systemImage: "tray")
                }
                .tag(0)
            
            ListView(list: 1, showDeferred: false)
                .tabItem {
                    Label("Now", systemImage: "scope")
                }
                .tag(1)
            
            ListView(list: 2, showDeferred: false)
                .tabItem {
                    Label("Next", systemImage: "terminal.fill")
                }
                .tag(2)
            
            ListView(list: 3, showDeferred: false)
                .tabItem {
                    Label("Someday", systemImage: "text.append")
                }
                .tag(3)
        }
        */
        
        .environmentObject(tab) // make the tab selection available to other views
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
    
    private func countTasks(list: Int) -> Int {
        if list != 4 { // if the list passed is not a 4, which is the Waiting for tasks, count the number of tasks in the list
            return tasks.filter({$0.list == list && !$0.completed}).count
        }
        else { // count the number of tasks that are in Waiting for state
            return tasks.filter({$0.waitingfor && !$0.completed}).count
        }
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
