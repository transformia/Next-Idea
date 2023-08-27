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
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default) // tasks sorted by order
    private var allTasks: FetchedResults<Task>
    
    @FetchRequest private var filteredTasks: FetchedResults<Task>
    
    @EnvironmentObject var tab: Tab
    @EnvironmentObject var weeklyReview: WeeklyReview
    
    let project: Project
    
    init(project: Project) { // filter the task list on the ones linked to the provided project
        self.project = project
        _filteredTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [
//                NSSortDescriptor(keyPath: \Task.list, ascending: true),
                NSSortDescriptor(keyPath: \Task.order, ascending: true) // tasks sorted by order
            ],
            predicate: NSPredicate(format: "project == %@", project)
        )
    }
    
    @State private var showSearchView = false
    @State private var showClearNextAlert = false
    @State private var showReviewAllAlert = false
    
    @State private var showOnlyFocus = false
    
    @State private var expandFocus = true
    @State private var expandDueOverdue = false
    @State private var expandNext = false
    @State private var expandWaiting = false
    @State private var expandDeferred = false
    @State private var expandSomeday = false
    
    var body: some View {
        VStack { // Contains project name, ZStack and Quick action buttons
            Text(project.name ?? "")
                .font(.headline)
                .padding()
                .padding(.top, 10)
            
            ZStack(alignment: .bottom) { // Contains task list and Add task buttons
                
                
                List {
                    
                    // Focused, not deferred:
                    if filteredTasks.filter({$0.filterTasks(filter: "Focus") && !$0.filterTasks(filter: "Deferred")}).count > 0 { // if there are non-completed focused tasks in the project
                        Section {
                            if(expandFocus) {
                                ForEach(filteredTasks.filter({$0.filterTasks(filter: "Focus") && !$0.filterTasks(filter: "Deferred")})) { task in
                                    HStack {
                                        TaskView(task: task)
                                    }
                                }
                                .onMove(perform: { indices, destination in
                                    moveItem(at: indices, destination: destination, filter: { task in
                                        return task.project == project && task.filterTasks(filter: "Focus") && !task.filterTasks(filter: "Deferred")
                                    })
                                })
                            }
                        } header: {
                            HStack {
                                Label("Focus", systemImage: "scope")
//                                        .font(.headline)
                                Spacer()
                                Text("\(countTasks(filter: "Focus"))")
                                Image(systemName: expandFocus ? "chevron.down" : "chevron.right")
                                    .foregroundColor(.blue)
                                    .font(.footnote)
                            }
                            .contentShape(Rectangle()) // make the whole HStack tappable
                            .onTapGesture {
                                withAnimation {
                                    expandFocus.toggle()
                                }
                            }
                        }
                    }
                    
                    // Due tasks:
                    if !showOnlyFocus && filteredTasks.filter({$0.filterTasks(filter: "Due")}).count > 0 { // if I'm not showing only focused tasks, and there are non-completed due or overdue tasks that are not focused
                        Section {
                            if(expandDueOverdue) {
                                ForEach(filteredTasks.filter({$0.filterTasks(filter: "Due")})) { task in
                                    HStack {
                                        TaskView(task: task)
                                    }
                                }
                                .onMove(perform: { indices, destination in
                                    moveItem(at: indices, destination: destination, filter: { task in
                                        return task.project == project && task.filterTasks(filter: "Due") && !task.filterTasks(filter: "Deferred")
                                    })
                                })
                            }
                        } header: {
                            HStack {
                                Label("Due and overdue", systemImage: "calendar")
//                                        .font(.headline)
                                Spacer()
                                Text("\(countDueOverdueTasks())")
                                Image(systemName: expandDueOverdue ? "chevron.down" : "chevron.right")
                                    .foregroundColor(.blue)
                                    .font(.footnote)
                            }
                            .contentShape(Rectangle()) // make the whole HStack tappable
                            .onTapGesture {
                                withAnimation {
                                    expandDueOverdue.toggle()
                                }
                            }
                        }
                    }
                    
                    if !showOnlyFocus {
                        
                        // Show non focused Next tasks:
                        if filteredTasks.filter({$0.filterTasks(filter: "Next") && !$0.filterTasks(filter: "Deferred")}).count > 0 {
                            Section {
                                if expandNext {
                                    ForEach(filteredTasks.filter({$0.filterTasks(filter: "Next") && !$0.filterTasks(filter: "Deferred")})) { task in
                                        HStack {
                                            TaskView(task: task)
                                        }
                                    }
                                    .onMove(perform: { indices, destination in
                                        moveItem(at: indices, destination: destination, filter: { task in
                                            return task.project == project && task.filterTasks(filter: "Next") && !task.filterTasks(filter: "Deferred")
                                        })
                                    })
                                }
                            } header: {
                                HStack {
                                    Label("Next", systemImage: "terminal.fill")
                                    //                                        .font(.headline)
                                    Spacer()
                                    Text("\(countTasks(filter: "Next"))")
                                    Image(systemName: expandNext ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.blue)
                                        .font(.footnote)
                                }
                                .contentShape(Rectangle()) // make the whole HStack tappable
                                .onTapGesture {
                                    withAnimation {
                                        expandNext.toggle()
                                    }
                                }
                            }
                        }
                        
                        // Show waiting for tasks:
                        if filteredTasks.filter({$0.filterTasks(filter: "Waiting for") && !$0.filterTasks(filter: "Deferred")}).count > 0 {
                            Section {
                                if expandWaiting {
                                    ForEach(filteredTasks.filter({$0.filterTasks(filter: "Waiting for") && !$0.filterTasks(filter: "Deferred")})) { task in
                                        HStack {
                                            TaskView(task: task)
                                        }
                                    }
                                    .onMove(perform: { indices, destination in
                                        moveItem(at: indices, destination: destination, filter: { task in
                                            return task.project == project && task.filterTasks(filter: "Waiting for") && !task.filterTasks(filter: "Deferred")
                                        })
                                    })
                                }
                            } header: {
                                HStack {
                                    Label("Waiting for", systemImage: "person.badge.clock")
                                    //                                        .font(.headline)
                                    Spacer()
                                    Text("\(countTasks(filter: "Waiting for"))")
                                    Image(systemName: expandWaiting ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.blue)
                                        .font(.footnote)
                                }
                                .contentShape(Rectangle()) // make the whole HStack tappable
                                .onTapGesture {
                                    withAnimation {
                                        expandWaiting.toggle()
                                    }
                                }
                            }
                        }
                        
                        // Show deferred tasks:
                        if filteredTasks.filter({$0.filterTasks(filter: "Deferred")}).count > 0 {
                            Section {
                                if expandDeferred {
                                    ForEach(filteredTasks.filter({$0.filterTasks(filter: "Deferred")})) { task in
                                        HStack {
                                            TaskView(task: task)
                                        }
                                    }
                                    .onMove(perform: { indices, destination in
                                        moveItem(at: indices, destination: destination, filter: { task in
                                            return task.project == project && task.filterTasks(filter: "Deferred")
                                        })
                                    })
                                }
                            } header: {
                                HStack {
                                    Label("Deferred", systemImage: "calendar.badge.clock")
                                    //                                        .font(.headline)
                                    Spacer()
                                    Text("\(countTasks(filter: "Deferred"))")
                                    Image(systemName: expandDeferred ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.blue)
                                        .font(.footnote)
                                }
                                .contentShape(Rectangle()) // make the whole HStack tappable
                                .onTapGesture {
                                    withAnimation {
                                        expandDeferred.toggle()
                                    }
                                }
                            }
                        }
                        
                        // Show Someday tasks:
                        if filteredTasks.filter({$0.filterTasks(filter: "Someday") && !$0.filterTasks(filter: "Deferred")}).count > 0 {
                            Section {
                                if expandSomeday {
                                    ForEach(filteredTasks.filter({$0.filterTasks(filter: "Someday") && !$0.filterTasks(filter: "Deferred")})) { task in
                                        HStack {
                                            TaskView(task: task)
                                            
                                        }
                                    }
                                    .onMove(perform: { indices, destination in
                                        moveItem(at: indices, destination: destination, filter: { task in
                                            return task.project == project && task.filterTasks(filter: "Someday") && !task.filterTasks(filter: "Deferred")
                                        })
                                    })
                                }
                            } header: {
                                HStack {
                                    Label("Someday", systemImage: "text.append")
//                                        .font(.headline)
                                    Spacer()
                                    Text("\(countTasks(filter: "Someday"))")
                                    Image(systemName: expandSomeday ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.blue)
                                        .font(.footnote)
                                }
                                .contentShape(Rectangle()) // make the whole HStack tappable
                                .onTapGesture {
                                    withAnimation {
                                        expandSomeday.toggle()
                                    }
                                }
                            }
                        }
                    }
                }
//                .padding(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8)) // reduce padding of the list items
//                .listStyle(SidebarListStyle()) // so that the sections are expandable and collapsible. Could instead use PlainListStyle, but with DisclosureGroups instead of Sections...
                .listStyle(PlainListStyle())
                
                // Add task buttons:
                AddTaskButtonsView(defaultFocus: false, defaultWaitingFor: false, defaultProject: project, defaultTag: nil) // add the task to the "Next" list
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
                        HStack {
                            if weeklyReview.active {
                                Label("", systemImage: "figure.yoga")
                            }
                            else {
                                Label("", systemImage: "figure.mind.and.body")
                            }
                            Text("\(countTasksToBeReviewed())")
                        }
                    }
                    
                    focusButton
                    
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if filteredTasks.filter({$0.selected}).count > 0 {
                        Button {
                            deselectAllTasks()
                        } label: {
                            Label("", systemImage: "pip.remove")
                        }
                    }
                    
                    if weeklyReview.active {
                        reviewAllButton
                    }
                    
                    clearNextButton
                    
                    Button {
                        showSearchView.toggle()
                    } label: {
                        Label("", systemImage: "magnifyingglass")
                    }
                }
            }
            
        }
    }
    
    private func moveItem(at sets: IndexSet, destination: Int, filter: (Task) -> Bool) {
        let itemToMove = sets.first!
        let itemsForMove = filteredTasks.filter { filter($0) }
        
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
    
    private func countTasks(filter: String) -> Int {
        if filter != "" {
            return (project.tasks?.allObjects as! [Task]).filter({
                $0.filterTasks(filter: filter)
                && ( !weeklyReview.active || Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date()) ) // review mode is active, or the task has a next review date before the end of today
            }).count
        }
        else {
            return (project.tasks?.allObjects as! [Task]).filter({
                !$0.completed
                && ( !weeklyReview.active || Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date()) ) // review mode is active, or the task has a next review date before the end of today
            }).count
        }
    }
    
    private func countDueOverdueTasks() -> Int {
        return (project.tasks?.allObjects as! [Task]).filter({
            !$0.completed
            && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())
            && ( !weeklyReview.active || Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date()) ) // review mode is active, or the task has a next review date before the end of today
        }).count
    }
    
    private func countWaitingForTasks() -> Int {
        return (project.tasks?.allObjects as! [Task]).filter({
            !$0.completed
            && $0.waitingfor
            && ( !weeklyReview.active || Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date()) ) // review mode is active, or the task has a next review date before the end of today
        }).count
    }
    
    private func countTasksToBeReviewed() -> Int {
        return (project.tasks?.allObjects as! [Task]).filter({!$0.completed && Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date())}).count
    }
    
    var reviewAllButton: some View {
        Button {
            showReviewAllAlert = true
        } label: {
            Label("", systemImage: "figure.mind.and.body")
        }
        .alert(isPresented: $showReviewAllAlert) {
            Alert(title: Text("This will mark all of this project's tasks as reviewed"), message: Text("Are you sure?"), primaryButton: .default(Text("OK")) {
                
                // Mark all tasks as reviewed:
                for task in filteredTasks.filter({!$0.completed}) {
                    task.nextreviewdate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
                }
                PersistenceController.shared.save() // save the item
                
            }, secondaryButton: .cancel())
        }
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
                    if !task.someday { // if the item is in the Next list
                        task.order = (filteredTasks.filter({!$0.completed && $0.someday}).first?.order ?? 0) - 1 - i // set the order of the task to the order of the first task of the destination list minus 1, minus the number of tasks that I have already moved
                        task.someday = true // move the item to the Someday list
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
