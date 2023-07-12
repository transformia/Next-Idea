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
    
    let list: Int16 // list to display
    
    @State var showDeferred: Bool // determines whether deferred items are shown or not. Can be set when calling the function
    
//    @Binding var selectedTab: Int // binding so that change made here impact the tab selected in ContentView
    @EnvironmentObject var tab: Tab
    
//    @State private var showOtherTasksDueToday =  false
    
    @State private var showProjectPicker = false
    @State private var showDatePicker = false
    @State private var showSearchView = false
    @State private var showWaitingForView = false
    
    @State private var showClearNextAlert = false
    
    @State private var showOnlyFocus = false
    
    
    // Define lists:
    let lists = [(Int16(0), "Inbox"), (Int16(1), "Now"), (Int16(2), "Next"), (Int16(3), "Someday")]
    
    var body: some View {
        NavigationStack {
            VStack { // Contains ZStack and Quick action buttons
                ZStack(alignment: .bottom) { // Contains task list and Add task buttons
                    
                    List {
                        
                        // In the Next list: show focused tasks:
                        if list == 2 && tasks.filter({($0.list == 2) && !$0.completed && $0.focus}).count > 0 { // if there are non-completed focused tasks in the Next list
                            Section("Focus") {
                                ForEach(tasks.filter({filterResult(task: $0, focus: true)})) { task in
                                    NavigationLink {
                                        if task.project != nil {
                                            ProjectTaskView(project: task.project ?? Project())
                                        }
                                        else {
                                            ProjectPickerView(tasks: [task], save: true)
                                        }
                                    } label: {
                                        HStack {
                                            
                                            TaskView(task: task)
                                            
                                            if task.project != nil {
                                                Image(systemName: task.project?.icon ?? "book.fill")
                                                    .resizable()
                                                    .frame(width: 18, height: 18)
                                                    .foregroundColor(Color(task.project?.color ?? "black"))
                                                    .padding(.leading, 3)
                                            }
                                        }
                                    }
                                    
                                    /* This causes the TaskDetailsView to close when I select a project, because the task disappears and appears again. It's annoying, and I lose any other changes that I've made
                                    HStack {
                                        if task.project == nil { // if the task has no project, just show the task
                                            TaskView(task: task)
                                        }
                                        
                                        else { // else if the task has a project, show the task as a navigation link to the project tasks
                                            NavigationLink {
                                                ProjectTaskView(project: task.project ?? Project())
                                            } label: {
                                                HStack {
                                                    TaskView(task:task)
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "book.fill")
                                                        .resizable()
                                                        .frame(width: 12, height: 12)
                                                }
                                            }
                                        }
                                    }
                                    */
                                }
                                .onMove(perform: moveItemFocus)
                            }
                        }
                        
                        if !showOnlyFocus && list == 2 && tasks.filter({!$0.completed && !$0.focus && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())}).count > 0 { // if I'm not showing only focused tasks, and there are non-completed due or overdue tasks that are not focused
                            Section("Due and overdue") {
                                ForEach(tasks.filter({!$0.completed && !$0.focus && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())})) { task in // filter out completed tasks, and keep only tasks due today or overdue, and not focused
                                    HStack {
                                        NavigationLink {
                                            if task.project != nil {
                                                ProjectTaskView(project: task.project ?? Project())
                                            }
                                            else {
                                                ProjectPickerView(tasks: [task], save: true)
                                            }
                                        } label: {
                                            HStack {
                                                
                                                TaskView(task: task)
                                                
                                                if task.project != nil {
                                                    Image(systemName: task.project?.icon ?? "book.fill")
                                                        .resizable()
                                                        .frame(width: 18, height: 18)
                                                        .foregroundColor(Color(task.project?.color ?? "black"))
                                                        .padding(.leading, 3)
                                                }
                                            }
                                        }
                                        
                                        switch(task.list) {
                                        case 0:
                                            Image(systemName: "tray")
                                        case 2:
                                            Image(systemName: "terminal.fill")
                                        case 3:
                                            Image(systemName: "text.append")
                                        default:
                                            Image(systemName: "tray")
                                        }
                                        
//                                        if task.project != nil { // if the task has a project
//                                            Spacer()
//
//                                            Image(systemName: "book")
//                                        }
                                    }
                                }
                                .onMove(perform: moveItemDue)
                            }
                        }
                        
                        if !showOnlyFocus { // if I'm not showing only focused tasks
                                Section("Tasks") {
                                // Show the tasks:
                                    ForEach(tasks.filter({filterResult(task: $0, focus: false) && !$0.focus})) { task in
                                        NavigationLink {
                                            if task.project != nil {
                                                ProjectTaskView(project: task.project ?? Project())
                                            }
                                            else {
                                                ProjectPickerView(tasks: [task], save: true)
                                            }
                                        } label: {
                                            HStack {
                                                
                                                TaskView(task: task)
                                                
                                                if task.project != nil {
                                                    Image(systemName: task.project?.icon ?? "book.fill")
                                                        .resizable()
                                                        .frame(width: 18, height: 18)
                                                        .foregroundColor(Color(task.project?.color ?? "black"))
                                                        .padding(.leading, 3)
                                                }
                                            }
                                        }
                                    /*
                                    HStack {
                                        if task.project == nil { // if the task has no project, just show the task
                                            TaskView(task: task)
                                        }
                                        
                                        else { // else if the task has a project, show the task as a navigation link to the project tasks
                                            NavigationLink {
                                                ProjectTaskView(project: task.project ?? Project())
                                            } label: {
                                                HStack {
                                                    TaskView(task:task)
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "book.fill")
                                                        .resizable()
                                                        .frame(width: 12, height: 12)
                                                }
                                            }
                                        }
                                    }
                                    */
                                }
                                .onMove(perform: moveItem)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    
                    // Add task buttons:
                    AddTaskButtonsView(list: list, project: nil, tag: nil, focus: showOnlyFocus)
                }
                
                QuickActionView()
                
            }
            .sheet(isPresented: $showSearchView) {
                SearchView()
            }
            .sheet(isPresented: $showWaitingForView) {
                WaitingForView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if tasks.filter({$0.selected}).count > 0 {
                            Button {
                                deselectAllTasks()
                            } label: {
                                Label("", systemImage: "pip.remove")
                            }
                        }
                        
                        Button {
                            showWaitingForView.toggle()
                        } label: {
                            Label("", systemImage: "stopwatch")
                        }
                        
                        Button {
                            showSearchView.toggle()
                        } label: {
                            Label("", systemImage: "magnifyingglass")
                        }
                        
                        EditButton()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        
                        Button {
                            withAnimation {
                                showDeferred.toggle()
                            }
                        } label: {
                            switch(showDeferred) {
                            case false:
                                Label("", systemImage: "eye.slash")
                            case true:
                                Label("", systemImage: "eye")
                            }
                        }
                        if list == 2 {
                            clearNextButton
                            focusButton
                        }
                    }
                }
            }
            .navigationTitle(list == 0 ? "Inbox" : list == 1 ? "Now" : list == 2 ? "Next" : "Someday")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func filterResult(task: Task, focus: Bool) -> Bool { // filter out completed tasks, and tasks from other lists than the provided one. If I want to show deferred tasks, or if the task is not deferred, or if the start of the day of its date is before now, display the task
        if task.list == list // task is in the specified list
            && task.focus == focus // task matches the provided focus filter
            && !task.completed // task is not completed
            && ( showDeferred || !task.dateactive || !task.hideuntildate || Calendar.current.startOfDay(for: task.date ?? Date()) <= Date() ) // I want to show deferred tasks, or the task doesn't have a date, or isn't hidden until that date, or the start of day of the date is in the past
        //            && ( task.project == nil || task.project?.displayoption == "All" || (task.project?.displayoption == "First" && (task.project?.isFirstTask(order: task.order, list: task.list) != false) ) ) { // the task has no project, or all of the project's tasks should be displayed, or only the first one should be displayed, and this is the first one. If the project is on hold, the task will therefore not be displayed
        {
            return true
        }
        
        else {
            return false
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
    
    private func moveItemFocus(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        let tasksForMove = tasks.filter({filterResult(task: $0, focus: true)})
        
        // If the item is moving down:
        if itemToMove < destination {
//            print(itemToMove)
//            print(destination)
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
//            print(startIndex)
//            print(endIndex)
            var startOrder = tasksForMove[itemToMove].order
//            print(startOrder)
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                tasksForMove[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasksForMove[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = tasksForMove[destination].order + 1
            let newOrder = tasksForMove[destination].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                tasksForMove[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasksForMove[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
    
    private func moveItemDue(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        let tasksForMove = tasks.filter({!$0.completed && !$0.focus && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())})
        
        // If the item is moving down:
        if itemToMove < destination {
//            print(itemToMove)
//            print(destination)
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
//            print(startIndex)
//            print(endIndex)
            var startOrder = tasksForMove[itemToMove].order
//            print(startOrder)
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                tasksForMove[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasksForMove[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = tasksForMove[destination].order + 1
            let newOrder = tasksForMove[destination].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                tasksForMove[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasksForMove[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
    
    private func moveItem(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        let tasksForMove = tasks.filter({filterResult(task: $0, focus: false)})
        
        // If the item is moving down:
        if itemToMove < destination {
//            print(itemToMove)
//            print(destination)
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
//            print(startIndex)
//            print(endIndex)
            var startOrder = tasksForMove[itemToMove].order
//            print(startOrder)
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                tasksForMove[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasksForMove[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = tasksForMove[destination].order + 1
            let newOrder = tasksForMove[destination].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                tasksForMove[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasksForMove[itemToMove].order = newOrder // set the moved task's order to its final value
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
                    if(task.list == 2) { // if the item is in the Next list
                        task.order = (tasks.filter({$0.list == 3}).first?.order ?? 0) - 1 - i // set the order of the task to the order of the first task of the destination list minus 1, minus the number of tasks that I have already moved
                        task.list = 3 // move the item to the top of the Someday list
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
