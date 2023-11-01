//
//  HomeView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI



struct HomeView: View {
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task> // to be able to count the tasks in each tile
    
    @EnvironmentObject var weeklyReview: WeeklyReview
    
    @State private var showSettingsView = false
    @State private var showSearchView = false
    
    @EnvironmentObject var homeActiveView: HomeActiveView // view selected in Home
    
    var body: some View {
        NavigationStack {
            List {
                
                Group {
                    
                    NavigationLink {
                        ListView(title: "All tasks")
                    } label: {
                        HStack {
                            Label("All tasks", systemImage: homeActiveView.iconString(viewName: "All tasks"))
                            Spacer()
                            Text("\(countTasks(filter: ""))")
                        }
                    }
                    
                    NavigationLink {
                        ListView(title: "Inbox")
                    } label: {
                        HStack {
                            Label("Inbox", systemImage: homeActiveView.iconString(viewName: "Inbox"))
                            Spacer()
                            Text("\(countTasks(filter: "Inbox"))")
                        }
                    }
                    
                    NavigationLink {
                        ListView(title: "Focus")
                    } label: {
                        HStack {
                            Label("Focus", systemImage: homeActiveView.iconString(viewName: "Focus"))
                            Spacer()
                            Text("\(countTasks(filter: "Focus"))")
                        }
                    }
                    
                    NavigationLink {
                        ListView(title: "Due")
//                        DueTodayView()
                    } label: {
                        HStack {
                            Label("Due and overdue", systemImage: homeActiveView.iconString(viewName: "Due"))
                            Spacer()
                            Text("\(countDueOverdueTasks())")
                        }
                    }
                    
                }
                
                Group {
                    
                    NavigationLink {
                        ListView(title: "Next")
                    } label: {
                        HStack {
                            Label("Next actions", systemImage: homeActiveView.iconString(viewName: "Next"))
                            Spacer()
                            Text("\(countTasks(filter: "Next"))")
                        }
                    }
                    
                    NavigationLink {
                        ListView(title: "Waiting for")
//                        WaitingForView()
                    } label: {
                        HStack {
                            Label("Waiting for", systemImage: homeActiveView.iconString(viewName: "Waiting for"))
                            Spacer()
                            Text("\(countTasks(filter: "Waiting for"))")
                        }
                    }
                    
                    NavigationLink {
                        ListView(title: "Deferred")
                    } label: {
                        HStack {
                            Label("Deferred", systemImage: homeActiveView.iconString(viewName: "Deferred"))
                            Spacer()
                            Text("\(countTasks(filter: "Deferred"))")
                        }
                    }
                    
                    NavigationLink {
                        ListView(title: "Someday")
                    } label: {
                        HStack {
                            Label("Someday", systemImage: homeActiveView.iconString(viewName: "Someday"))
                            Spacer()
                            Text("\(countTasks(filter: "Someday"))")
                        }
                    }
                    
                    NavigationLink {
                        SearchView()
                    } label: {
                        Label("Search", systemImage: homeActiveView.iconString(viewName: "Search"))
                    }
                    
                    NavigationLink {
                        CompletedView()
                    } label: {
                        Label("Completed tasks", systemImage: homeActiveView.iconString(viewName: "Completed"))
                    }
                    
                }
                
            }
            .onAppear {
                homeActiveView.stringName = "Home" // change the tab name and logo
            }
            .listStyle(PlainListStyle())
            .toolbar {
                
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button {
                            showSettingsView = true
                        } label: {
                            Label("", systemImage: "gear")
                        }
                        
                        Button {
                            weeklyReview.active.toggle()
                        } label: {
                            HStack {
                                if weeklyReview.active {
                                    Label("", systemImage: "lightbulb.2.fill")
                                }
                                else {
                                    Label("", systemImage: "lightbulb.2")
                                }
                                Text("\(countTasksToBeReviewed())")
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        
//                        Text("Hash: \(calcHashKey())")
                        
                        Button {
                            showSearchView.toggle()
                        } label: {
                            Label("", systemImage: "magnifyingglass")
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            
            
            // Add task buttons:
            AddTaskButtonsView(defaultFocus: false, defaultWaitingFor: false, defaultProject: nil, defaultTag: nil)
            
            
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
        }
        .sheet(isPresented: $showSearchView) {
            SearchView()
        }
    }
    
    private func countTasks(filter: String) -> Int {
        if filter != "" {
            return tasks.filter({
                $0.filterTasks(filter: filter)
                && ( !weeklyReview.active || Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date()) ) // review mode is active, or the task has a next review date before the end of today
            }).count
        }
        else {
            return tasks.filter({
                !$0.completed
                && ( !weeklyReview.active || Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date()) ) // review mode is active, or the task has a next review date before the end of today
            }).count
        }
    }
    
    private func countTasksToBeReviewed() -> Int {
        return tasks.filter({!$0.completed && Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date())}).count
    }
    
    private func countDueOverdueTasks() -> Int {
        return tasks.filter({
            !$0.completed
            && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())
            && ( !weeklyReview.active || Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date()) ) // review mode is active, or the task has a next review date before the end of today
        }).count
    }
    
    private func countWaitingForTasks() -> Int {
        return tasks.filter({
            !$0.completed
            && $0.waitingfor
            && ( !weeklyReview.active || Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date()) ) // review mode is active, or the task has a next review date before the end of today
        }).count
    }
    
    private func calcHashKey() -> Int {
        var hashKey = 0
        for task in tasks.filter({!$0.completed}) {
            hashKey += task.name?.count ?? 0
        }
        return hashKey
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
