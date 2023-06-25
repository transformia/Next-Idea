//
//  ProjectTaskView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct ProjectTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.list, ascending: true), NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default) // tasks sorted by order, then by list
    private var allTasks: FetchedResults<Task>
    
    @FetchRequest private var filteredTasks: FetchedResults<Task>
    
    @EnvironmentObject var tab: Tab
//    @FetchRequest var tasks: FetchedResults<Task>
    
    let project: Project
    
    init(project: Project) { // filter the task list on the ones linked to the provided project
        self.project = project
        _filteredTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Task.list, ascending: true),
                NSSortDescriptor(keyPath: \Task.order, ascending: true) // tasks sorted by order, then by list
            ],
            predicate: NSPredicate(format: "project == %@", project)
        )
    }
    
    @State private var showSearchView = false
    @State private var showClearNextAlert = false
    
    @State private var showOnlyFocus = false
    
    var body: some View {
        VStack { // Contains project name, ZStack and Quick action buttons
            Text(project.name ?? "")
                .font(.headline)
            
            ZStack(alignment: .bottom) { // Contains task list and Add task buttons
                
                
                List {
                    
                    // Show focused tasks:
                    if filteredTasks.filter({!$0.completed && $0.focus}).count > 0 { // if there are non-completed focused tasks in the project
                        Section("Focus") {
                            ForEach(filteredTasks.filter({!$0.completed && $0.focus})) { task in
                                HStack {
                                    TaskView(task: task)
                                    
                                    Spacer()
                                    
                                    // Show the list's icon:
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
                                }
                            }
                            .onMove(perform: moveItemFocus)
                        }
                    }
                    
                    if !showOnlyFocus && filteredTasks.filter({!$0.completed && !$0.focus && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())}).count > 0 { // if I'm not showing only focused tasks, and there are non-completed due or overdue tasks that are not focused
                        Section("Due and overdue") {
                            ForEach(filteredTasks.filter({!$0.completed && !$0.focus && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())})) { task in // filter out completed tasks, and keep only tasks due today or overdue, and not focused
                                HStack {
                                    TaskView(task: task)
//                                            .padding(.leading, 10)
                                    
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
                                }
                            }
                            .onMove(perform: moveItemDue)
                        }
                    }
                    
                    if !showOnlyFocus { // if I'm not showing only focused tasks
                        // Show non focused Next tasks:
                        Section("Next") {
                            ForEach(filteredTasks.filter({!$0.completed && $0.list == 2 && !$0.focus})) { task in
                                HStack {
                                    TaskView(task: task)
                                    
                                    Spacer()
                                    
                                    // Show the list's icon:
                                    Image(systemName: "terminal.fill")
                                }
                            }
                            .onMove(perform: moveItemNext)
                        }
                        
                        // Show Someday tasks:
                        Section("Someday") {
                            ForEach(filteredTasks.filter({!$0.completed && $0.list == 3 && !$0.focus})) { task in
                                HStack {
                                    TaskView(task: task)
                                    
                                    Spacer()
                                    
                                    // Show the list's icon:
                                    Image(systemName: "text.append")
                                    
                                }
                            }
                            .onMove(perform: moveItemSomeday)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                // Add task buttons:
                AddTaskButtonsView(list: 2, project: project, tag: nil, focus: showOnlyFocus) // add the task to the "Next" list
            }
            
            QuickActionView()
            
        }
        .sheet(isPresented: $showSearchView) {
            SearchView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if filteredTasks.filter({$0.selected}).count > 0 {
                        Button {
                            deselectAllTasks()
                        } label: {
                            Label("", systemImage: "pip.remove")
                        }
                    }
                    
                    Button {
                        showSearchView.toggle()
                    } label: {
                        Label("", systemImage: "magnifyingglass")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    clearNextButton
                    focusButton
                }
            }
        }
    }
    
    private func moveItemFocus(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        let tasksForMove = filteredTasks.filter({!$0.completed && $0.focus})
        
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
        let tasksForMove = filteredTasks.filter({!$0.completed && !$0.focus && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())})
        
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
    
    
    private func moveItemNext(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        let tasksForMove = filteredTasks.filter({!$0.completed && $0.list == 2 && !$0.focus})
        
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
    
    private func moveItemSomeday(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        let tasksForMove = filteredTasks.filter({!$0.completed && $0.list == 3})
        
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
            Alert(title: Text("This will move all of this project's tasks to the Someday list"), message: Text("Are you sure?"), primaryButton: .default(Text("OK")) {
                
                // Clear all tasks from Next:
                var i: Int64 = 0
                for task in filteredTasks.filter({!$0.completed}).reversed() { // go through the elements in reverse order, so that they end up in the same order as they were initially
                    if(task.list == 2) { // if the item is in the Next list
                        task.order = (filteredTasks.filter({!$0.completed && $0.list == 3}).first?.order ?? 0) - 1 - i // set the order of the task to the order of the first task of the destination list minus 1, minus the number of tasks that I have already moved
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
        
    private func deselectAllTasks() {
        for task in allTasks {
            if task.selected {
                task.selected = false
            }
        }
        PersistenceController.shared.save()
    }
}

struct ProjectTaskView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectTaskView(project: Project())
    }
}
