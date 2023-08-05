//
//  ListView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct ListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task>
    
    @EnvironmentObject var weeklyReview: WeeklyReview
    
//    let list: Int16 // list to display
    
    let title: String // title of the view
    
    @State var showOnlyFocus = false // determines whether other sections than Focused are shown or not
    
//    @State var showInbox: Bool
//    @State var showFocus: Bool
//    @State var showDue: Bool
//    @State var showWaitingfor: Bool
//    @State var showNext: Bool
//    @State var showSomeday: Bool
//    @State var showReview: Bool
//    @State var showCompleted: Bool
    
    @State private var selectedProject: Project? // to have something to pass to the ProjectPickerView, even if it doesn't use it
    
    //    @Binding var selectedTab: Int // binding so that change made here impact the tab selected in ContentView
    @EnvironmentObject var tab: Tab
    
    //    @State private var showOtherTasksDueToday =  false
    
    @State private var showProjectPicker = false
    @State private var showDatePicker = false
    @State private var showSearchView = false
    
    @State private var showClearNextAlert = false
    
    var body: some View {
        NavigationStack {
            VStack { // Contains ZStack and Quick action buttons
                ZStack(alignment: .bottom) { // Contains task list and Add task buttons
                    
                    List {
                        
                        // Inbox:
                        if ( !showOnlyFocus && ( title == "Inbox" || title == "All tasks" ) ) && tasks.filter({$0.filterTasks(filter: "Inbox")}).count > 0 { // if there are tasks without a project
                            Section("Inbox") {
                                ForEach(tasks.filter({$0.filterTasks(filter: "Inbox")})) { task in
                                    NavigationLink {
                                        ProjectPickerView(selectedProject: $selectedProject, tasks: [task])
//                                        ProjectPickerView(tasks: [task], save: true)
                                    } label: {
                                        HStack {
                                            TaskView(task: task)
                                        }
                                    }
                                }
                                .onMove(perform: { indices, destination in
                                    moveItem(at: indices, destination: destination, filter: { task in
                                        return task.filterTasks(filter: "Inbox")
                                    })
                                })
                            }
                        }
                        
                        // Focused, not deferred:
                        if ( title == "Focus" || title == "Next" || title == "All tasks" ) && tasks.filter({$0.filterTasks(filter: "Focus") && !$0.filterTasks(filter: "Deferred")}).count > 0 { // if there are focused tasks that are not deferred
                            Section("Focus") {
                                ForEach(tasks.filter({$0.filterTasks(filter: "Focus") && !$0.filterTasks(filter: "Deferred")})) { task in
                                    NavigationLink {
                                        ProjectTaskView(project: task.project ?? Project())
                                    } label: {
                                        HStack {
                                            TaskView(task: task)
                                            
                                            Image(systemName: task.project?.icon ?? "book.fill")
                                                .resizable()
                                                .frame(width: 18, height: 18)
                                                .foregroundColor(Color(task.project?.color ?? "black"))
                                                .padding(.leading, 3)
                                        }
                                    }
                                }
                                .onMove(perform: { indices, destination in
                                    moveItem(at: indices, destination: destination, filter: { task in
                                        return task.filterTasks(filter: "Focus") && !task.filterTasks(filter: "Deferred")
                                    })
                                })
                            }
                        }
                        
                        // Due:
                        if ( !showOnlyFocus && ( title == "Due" || title == "All tasks" ) ) && tasks.filter({$0.filterTasks(filter: "Due")}).count > 0 { // if there are focused tasks
                            Section("Due and overdue") {
                                ForEach(tasks.filter({$0.filterTasks(filter: "Due")})) { task in
                                    NavigationLink {
                                        if task.project == nil {
                                            ProjectPickerView(selectedProject: $selectedProject, tasks: [task])
                                        }
                                        else {
                                            ProjectTaskView(project: task.project ?? Project())
                                        }
                                    } label: {
                                        HStack {
                                            TaskView(task: task)
                                            
                                            Image(systemName: task.project?.icon ?? "book.fill")
                                                .resizable()
                                                .frame(width: 18, height: 18)
                                                .foregroundColor(Color(task.project?.color ?? "black"))
                                                .padding(.leading, 3)
                                        }
                                    }
                                }
                                .onMove(perform: { indices, destination in
                                    moveItem(at: indices, destination: destination, filter: { task in
                                        return task.filterTasks(filter: "Due")
                                    })
                                })
//                                .onMove(perform: moveItemFocus)
                            }
                        }
                        
                        // Next actions, not deferred:
                        if ( !showOnlyFocus && ( title == "Next" || title == "All tasks" ) ) && tasks.filter({$0.filterTasks(filter: "Next") && !$0.filterTasks(filter: "Deferred")}).count > 0 {
                            Section("Next") {
                                ForEach(tasks.filter({$0.filterTasks(filter: "Next") && !$0.filterTasks(filter: "Deferred")})) { task in
                                    NavigationLink {
                                        ProjectTaskView(project: task.project ?? Project())
                                    } label: {
                                        HStack {
                                            TaskView(task: task)
                                            
                                            Image(systemName: task.project?.icon ?? "book.fill")
                                                .resizable()
                                                .frame(width: 18, height: 18)
                                                .foregroundColor(Color(task.project?.color ?? "black"))
                                                .padding(.leading, 3)
                                        }
                                    }
                                }
                                .onMove(perform: { indices, destination in
                                    moveItem(at: indices, destination: destination, filter: { task in
                                        return task.filterTasks(filter: "Next") && !task.filterTasks(filter: "Deferred")
                                    })
                                })
                            }
                        }
                        
                        // Waiting for:
                        if ( !showOnlyFocus && ( title == "Waiting for" || title == "All tasks" ) ) && tasks.filter({$0.filterTasks(filter: "Waiting for") && !$0.filterTasks(filter: "Deferred")}).count > 0 { // if there are focused tasks
                            Section("Waiting for") {
                                ForEach(tasks.filter({$0.filterTasks(filter: "Waiting for") && !$0.filterTasks(filter: "Deferred")})) { task in
                                    NavigationLink {
                                        ProjectTaskView(project: task.project ?? Project())
                                    } label: {
                                        HStack {
                                            TaskView(task: task)
                                            
                                            Image(systemName: task.project?.icon ?? "book.fill")
                                                .resizable()
                                                .frame(width: 18, height: 18)
                                                .foregroundColor(Color(task.project?.color ?? "black"))
                                                .padding(.leading, 3)
                                        }
                                    }
                                }
                                .onMove(perform: { indices, destination in
                                    moveItem(at: indices, destination: destination, filter: { task in
                                        return task.filterTasks(filter: "Waiting for") && !task.filterTasks(filter: "Deferred")
                                    })
                                })
//                                .onMove(perform: moveItemFocus)
                            }
                        }
                                                
                        // Deferred:
                        if ( !showOnlyFocus && ( title == "Deferred" || title == "All tasks" ) ) && tasks.filter({$0.filterTasks(filter: "Deferred")}).count > 0 { // if there are non-completed deferred tasks
                            Section("Deferred") {
                                ForEach(tasks.filter({$0.filterTasks(filter: "Deferred")})) { task in
                                    NavigationLink {
                                        ProjectTaskView(project: task.project ?? Project())
                                    } label: {
                                        HStack {
                                            TaskView(task: task)
                                            
                                            Image(systemName: task.project?.icon ?? "book.fill")
                                                .resizable()
                                                .frame(width: 18, height: 18)
                                                .foregroundColor(Color(task.project?.color ?? "black"))
                                                .padding(.leading, 3)
                                        }
                                    }
                                }
                                .onMove(perform: { indices, destination in
                                    moveItem(at: indices, destination: destination, filter: { task in
                                        return task.filterTasks(filter: "Deferred")
                                    })
                                })
                            }
                        }
                        
                        // Someday:
                        if ( !showOnlyFocus && ( title == "Someday" || title == "All tasks" ) ) && tasks.filter({$0.filterTasks(filter: "Someday") && !$0.filterTasks(filter: "Deferred")}).count > 0 {
                            Section("Someday") {
                                ForEach(tasks.filter({$0.filterTasks(filter: "Someday") && !$0.filterTasks(filter: "Deferred")})) { task in
                                    NavigationLink {
                                        ProjectTaskView(project: task.project ?? Project())
                                    } label: {
                                        HStack {
                                            TaskView(task: task)
                                            
                                            Image(systemName: task.project?.icon ?? "book.fill")
                                                .resizable()
                                                .frame(width: 18, height: 18)
                                                .foregroundColor(Color(task.project?.color ?? "black"))
                                                .padding(.leading, 3)
                                        }
                                    }
                                }
                                .onMove(perform: { indices, destination in
                                    moveItem(at: indices, destination: destination, filter: { task in
                                        return task.filterTasks(filter: "Someday") && !task.filterTasks(filter: "Deferred")
                                    })
                                })
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8)) // reduce padding of the list items
                    .listStyle(SidebarListStyle()) // so that the sections are expandable and collapsible. Could instead use PlainListStyle, but with DisclosureGroups instead of Sections...
//                    .listStyle(PlainListStyle())
                    
                    // Add task buttons:
                    AddTaskButtonsView(defaultFocus: title == "Focus" ? true : false, defaultWaitingFor: title == "Waiting for" ? true : false, defaultProject: nil, defaultTag: nil)
                }
                
                QuickActionView()
                
            }
            .sheet(isPresented: $showSearchView) {
                SearchView()
            }
            .toolbar {
                
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        
                        Button {
                            weeklyReview.active.toggle()
                        } label: {
                            if weeklyReview.active {
                                Label("", systemImage: "figure.yoga")
                            }
                            else {
                                Label("", systemImage: "figure.mind.and.body")
                            }
                        }
                        
                        focusButton
                        
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if tasks.filter({$0.selected}).count > 0 {
                            Button {
                                deselectAllTasks()
                            } label: {
                                Label("", systemImage: "pip.remove")
                            }
                        }
                        
                        if title == "Next" || title == "All tasks" {
                            clearNextButton
                        }
                        
                        Button {
                            showSearchView.toggle()
                        } label: {
                            Label("", systemImage: "magnifyingglass")
                        }
                        
                        EditButton()
                    }
                }
            }
            .navigationTitle(title)
//            .navigationTitle(list == 0 ? "Inbox" : list == 2 ? "Next" : "Someday")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    
    private func deselectAllTasks() {
        for task in tasks {
            if task.selected {
                task.selected = false
            }
        }
        PersistenceController.shared.save()
    }
    
    private func moveItem(at sets: IndexSet, destination: Int, filter: (Task) -> Bool) {
        let itemToMove = sets.first!
        let itemsForMove = tasks.filter { filter($0) }
        
        // If the item is moving down:
        if itemToMove < destination {
//            print(itemToMove)
//            print(destination)
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
//            print(startIndex)
//            print(endIndex)
            var startOrder = itemsForMove[itemToMove].order
//            print(startOrder)
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                itemsForMove[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            itemsForMove[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = itemsForMove[destination].order + 1
            let newOrder = itemsForMove[destination].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                itemsForMove[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            itemsForMove[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
    
    var clearNextButton: some View {
        Button {
            showClearNextAlert = true
        } label: {
            Label("", systemImage: "xmark.circle")
        }
        .alert(isPresented: $showClearNextAlert) {
            Alert(title: Text("This will move all tasks to the Someday list"), message: Text("Are you sure?"), primaryButton: .default(Text("OK")) {
                
                // Clear all tasks from Next, and remove focus:
                var i: Int64 = 0
                for task in tasks.reversed() { // go through the elements in reverse order, so that they end up in the same order as they were initially
                    if(!task.someday) { // if the item is in the Next list
                        task.order = (tasks.filter({$0.someday}).first?.order ?? 0) - 1 - i // set the order of the task to the order of the first task of the destination list minus 1, minus the number of tasks that I have already moved
                        task.someday = true // move the item to the top of the Someday list
                        task.focus = false
                        i += 1 // increment i
                    }
                }
                PersistenceController.shared.save() // save the item
                
            }, secondaryButton: .cancel())
        }
    }
    
    var focusButton: some View {
        Button {
            showOnlyFocus.toggle()
        } label: {
            Label("", systemImage: "scope")
        }
    }
}

//struct ListView_Previews: PreviewProvider {
//    static var previews: some View {
//        ListView(list: 0, showDeferred: false)
//    }
//}
