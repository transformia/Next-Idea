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
    
    @State private var showProjectPicker = false
    @State private var showDatePicker = false
    
    // Define lists:
    let lists = [(Int16(0), "Inbox"), (Int16(1), "Now"), (Int16(2), "Next"), (Int16(3), "Someday")]
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack(alignment: .bottom) {
                    
                    List {
                        
                        // Only in the Now list: show the number of tasks due today in other lists, if there are any, and link to the list of them:
                        if list == 1 && tasks.filter({!($0.list == 1) && !$0.completed && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())}).count > 0 {
                            NavigationLink {
                                DueTodayView()
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Other due and overdue tasks") // count of uncompleted tasks due today and overdue
                                    Spacer()
                                    Text("\(tasks.filter({!($0.list == 1) && !$0.completed && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())}).count)")
                                }
                                .foregroundColor(.blue)
                            }
                            .swipeActions {
                                Button { // move all of the due tasks to the bottom of Now
                                    
                                    for task in tasks.filter({!($0.list == 1) && !$0.completed && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())}) {
                                        task.order = (tasks.filter({$0.list == 1 && !$0.completed}).last?.order ?? 0) + 1 // set the order of the task to the order of the last uncompleted task of the destination list plus 1
                                        task.list = 1
                                        task.modifieddate = Date()
                                    }
                                    
                                    PersistenceController.shared.save() // save the changes
                                } label: {
                                    Label("Move to Now", systemImage: "scope")
                                }
                                .tint(.green)
                            }
                        }
                        
                        // Show the tasks:
                        
                        // NOTE: IF I MODIFY THIS FILTER, I HAVE TO MODIFY IT IN MOVEITEM TOO! Otherwise dragging tasks will not work anymore
                        ForEach(tasks.filter  ({$0.list == list && !$0.completed && ( showDeferred || !$0.dateactive || !$0.hideuntildate || Calendar.current.startOfDay(for: $0.date ?? Date()) <= Date() ) && ( $0.project == nil || $0.project?.displayoption == "All" || ($0.project?.displayoption == "First" && ($0.project?.isFirstTask(order: $0.order, list: $0.list) != false) ) ) })  ) { task in // filter out completed tasks, and tasks from other lists than the provided one. If I want to show deferred tasks, or if the task is not deferred, or if the start of the day of its date is before now, display the task. If the task has no project, or its project is set up to display all tasks, or just the first task and this is the first non-completed task of the project, display the task
                            HStack {
                                if tasks.filter({$0.selected}).count > 0 {
                                    //                                    Image(systemName: task.selected ? "pin.fill" : "pin.slash.fill")
                                    Image(systemName: task.selected ? "circle.fill" : "circle")
                                        .foregroundColor(task.selected ? .teal : nil)
                                        .onTapGesture {
                                            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                                            impactMed.impactOccurred() // haptic feedback
                                            
                                            task.selected.toggle()
                                        }
                                }
                                
                                if task.project == nil { // if the task has no project, just show the task
                                    TaskView(task: task)
                                }
                                
                                else { // else if the task has a project, show the task as a navigation link to the project tasks
                                    NavigationLink {
                                        ProjectTaskView(project: task.project ?? Project())
                                    } label: {
                                        TaskView(task:task)
                                        Image(systemName: "book.fill")
                                            .resizable()
                                            .frame(width: 12, height: 12)
                                    }
                                }
                            }
                        }
                        .onMove(perform: moveItem)
                    }
                    
                    if tasks.filter({$0.list == list && !$0.completed && $0.ticked}).count > 0 { // if there are ticked tasks displayed, show a button to mark them as complete, and therefore hide them
                        Button {
                            for task in tasks {
                                if task.ticked {
                                    task.completed = true
                                }
                            }
                            PersistenceController.shared.save()
                        } label: {
                            Text("Clear completed tasks")
                        }
                        .padding(.bottom, 60)
                    }
                    
                    // Add task buttons:
                    HStack {
                        addTaskTopButton
                        addTaskBottomButton
                    }
                }
                
                
                // Second element of the VStack: Quick action buttons:
                
                if tasks.filter({$0.selected}).count > 0 { // show icons to move the tasks to other lists if at least one task is selected
                    VStack {
                        HStack {
                            
                            // Quick actions to move tasks to other lists:
                            Button {
                                for task in tasks.filter({$0.selected}) {
                                    task.list = 0
                                    task.modifieddate = Date()
                                }
                                PersistenceController.shared.save()
                                deselectAllTasks()
                            } label: {
                                Image(systemName: "tray")
                                    .resizable()
                                    .frame(width: 26, height: 26)
                                    .foregroundColor(.white)
                                    .padding(10)
                            }
                            
                            Button {
                                for task in tasks.filter({$0.selected}) {
                                    task.list = 1
                                    task.modifieddate = Date()
                                }
                                PersistenceController.shared.save()
                                deselectAllTasks()
                            } label: {
                                Image(systemName: "scope")
                                    .resizable()
                                    .frame(width: 26, height: 26)
                                    .foregroundColor(.white)
                                    .padding(10)
                            }
                            
                            Button {
                                for task in tasks.filter({$0.selected}) {
                                    task.list = 2
                                    task.modifieddate = Date()
                                }
                                PersistenceController.shared.save()
                                deselectAllTasks()
                            } label: {
                                Image(systemName: "terminal.fill")
                                    .resizable()
                                    .frame(width: 26, height: 26)
                                    .foregroundColor(.white)
                                    .padding(10)
                            }
                            
                            Button {
                                for task in tasks.filter({$0.selected}) {
                                    task.list = 3
                                    task.modifieddate = Date()
                                }
                                PersistenceController.shared.save()
                                deselectAllTasks()
                            } label: {
                                Image(systemName: "text.append")
                                    .resizable()
                                    .frame(width: 26, height: 26)
                                    .foregroundColor(.white)
                                    .padding(10)
                            }
                        }
//                        .padding(.bottom, 120)
                        
                        // Quick actions to change date and project:
                        HStack {
                            
                            // Show date picker:
                            Button {
                                showDatePicker = true
                            } label: {
                                Image(systemName: "calendar")
                                    .resizable()
                                    .frame(width: 26, height: 26)
                                    .foregroundColor(.white)
                                    .padding(10)
                            }
                            
                            Button {
                                showProjectPicker = true
                            } label: {
                                Image(systemName: "book.fill")
                                    .resizable()
                                    .frame(width: 26, height: 26)
                                    .foregroundColor(.white)
                                    .padding(10)
                            }
                            .sheet(isPresented: $showProjectPicker) {
                                ProjectPickerView(tasks: tasks.filter({$0.selected}))
                            }
                            .sheet(isPresented: $showDatePicker) {
                                DatePickerView(tasks: tasks.filter({$0.selected}))
                                    .presentationDetents([.height(500)])
                            }
                        }
//                        .padding(.bottom, 60)
                    }
//                    .frame(height: 100)
                    .background(.black)
                }
                
                
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        if tasks.filter({$0.selected}).count > 0 {
                            Button {
                                deselectAllTasks()
                            } label: {
                                Label("", systemImage: "pip.remove")
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
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
                        
                        EditButton()
                    }
                }
            }
            .navigationTitle(list == 0 ? "Inbox" : list == 1 ? "Now" : list == 2 ? "Next" : "Someday")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func deselectAllTasks() {
        for task in tasks {
            if task.selected {
                task.selected = false
            }
        }
    }
    
    private func moveItem(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        
        // If the item is moving down:
        if itemToMove < destination {
//            print(itemToMove)
//            print(destination)
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
//            print(startIndex)
//            print(endIndex)
            var startOrder = tasks.filter  ({$0.list == list && !$0.completed && ( showDeferred || !$0.dateactive || !$0.hideuntildate || Calendar.current.startOfDay(for: $0.date ?? Date()) <= Date() ) && ( $0.project == nil || $0.project?.displayoption == "All" || ($0.project?.displayoption == "First" && ($0.project?.isFirstTask(order: $0.order, list: $0.list) != false) ) ) })[itemToMove].order
//            print(startOrder)
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                tasks.filter  ({$0.list == list && !$0.completed && ( showDeferred || !$0.dateactive || !$0.hideuntildate || Calendar.current.startOfDay(for: $0.date ?? Date()) <= Date() ) && ( $0.project == nil || $0.project?.displayoption == "All" || ($0.project?.displayoption == "First" && ($0.project?.isFirstTask(order: $0.order, list: $0.list) != false) ) ) })[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasks.filter  ({$0.list == list && !$0.completed && ( showDeferred || !$0.dateactive || !$0.hideuntildate || Calendar.current.startOfDay(for: $0.date ?? Date()) <= Date() ) && ( $0.project == nil || $0.project?.displayoption == "All" || ($0.project?.displayoption == "First" && ($0.project?.isFirstTask(order: $0.order, list: $0.list) != false) ) ) })[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = tasks.filter  ({$0.list == list && !$0.completed && ( showDeferred || !$0.dateactive || !$0.hideuntildate || Calendar.current.startOfDay(for: $0.date ?? Date()) <= Date() ) && ( $0.project == nil || $0.project?.displayoption == "All" || ($0.project?.displayoption == "First" && ($0.project?.isFirstTask(order: $0.order, list: $0.list) != false) ) ) })[destination].order + 1
            let newOrder = tasks.filter  ({$0.list == list && !$0.completed && ( showDeferred || !$0.dateactive || !$0.hideuntildate || Calendar.current.startOfDay(for: $0.date ?? Date()) <= Date() ) && ( $0.project == nil || $0.project?.displayoption == "All" || ($0.project?.displayoption == "First" && ($0.project?.isFirstTask(order: $0.order, list: $0.list) != false) ) ) })[destination].order
            while startIndex <= endIndex {
                tasks.filter  ({$0.list == list && !$0.completed && ( showDeferred || !$0.dateactive || !$0.hideuntildate || Calendar.current.startOfDay(for: $0.date ?? Date()) <= Date() ) && ( $0.project == nil || $0.project?.displayoption == "All" || ($0.project?.displayoption == "First" && ($0.project?.isFirstTask(order: $0.order, list: $0.list) != false) ) ) })[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasks.filter  ({$0.list == list && !$0.completed && ( showDeferred || !$0.dateactive || !$0.hideuntildate || Calendar.current.startOfDay(for: $0.date ?? Date()) <= Date() ) && ( $0.project == nil || $0.project?.displayoption == "All" || ($0.project?.displayoption == "First" && ($0.project?.isFirstTask(order: $0.order, list: $0.list) != false) ) ) })[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
    
    var addTaskTopButton: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
            impactMed.impactOccurred() // haptic feedback
            // Create a new task:
            let task = Task(context: viewContext)
            task.id = UUID()
            task.order = (tasks.first?.order ?? 0) - 1
            task.list = list
            task.name = ""
            task.createddate = Date()
            PersistenceController.shared.save()
        } label: {
            Image(systemName: "arrow.up")
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(.white)
                .padding(10)
                .background(.green)
                .clipShape(Circle())
        }
        .padding(.bottom, 8)
    }
    
    var addTaskBottomButton: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
            impactMed.impactOccurred() // haptic feedback
            // Create a new task:
            let task = Task(context: viewContext)
            task.id = UUID()
            task.order = (tasks.last?.order ?? 0) + 1
            task.list = list
            task.name = ""
            task.createddate = Date()
            PersistenceController.shared.save()
        } label: {
            Image(systemName: "arrow.down")
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(.white)
                .padding(10)
                .background(.green)
                .clipShape(Circle())
        }
        .padding(.bottom, 8)
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(list: 0, showDeferred: false)
    }
}
