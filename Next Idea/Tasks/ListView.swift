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
    
    @State private var showOtherTasksDueToday =  false
    
    @State private var showProjectPicker = false
    @State private var showDatePicker = false
    @State private var showSearchView = false
    
    @State private var showClearNowAlert = false
    @State private var showClearNextAlert = false
    
    
    // Define lists:
    let lists = [(Int16(0), "Inbox"), (Int16(1), "Now"), (Int16(2), "Next"), (Int16(3), "Someday")]
    
    var body: some View {
        NavigationStack {
            VStack { // Contains ZStack and Quick action buttons
                ZStack(alignment: .bottom) { // Contains task list and Add task buttons
                    
                    List {
                        // Show the tasks:
                            
                        ForEach(tasks.filter({filterResult(task: $0)})) { task in
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
                                
                                // If at least one task is selected, show the selection circle next to each task:
//                                if tasks.filter({$0.selected}).count > 0 {
//                                    Image(systemName: task.selected ? "circle.fill" : "circle")
//                                        .padding(.leading, 5)
//                                        .foregroundColor(task.selected ? .teal : nil)
//                                        .onTapGesture {
//                                            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
//                                            impactMed.impactOccurred() // haptic feedback
//
//                                            task.selected.toggle()
//                                            PersistenceController.shared.save()
//                                        }
//                                }
                            }
                        }
                        .onMove(perform: moveItem)
                        
                        
                        // Only in the Now list: show the tasks from other lists that are due today, if there are any:
                        if list == 1 && tasks.filter({!($0.list == 1) && !$0.completed && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())}).count > 0 {
                            HStack {
                                Image(systemName: showOtherTasksDueToday ? "arrowtriangle.down.fill" : "arrowtriangle.right.fill")
                                    .resizable()
                                    .frame(width: 10, height: 10)
                                Text("Other tasks due today: \(tasks.filter({!($0.list == 1) && !$0.completed && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())}).count)")
                                    .font(.callout)
                            }
                            .foregroundColor(.gray)
                                .onTapGesture {
                                    withAnimation {
                                        showOtherTasksDueToday.toggle()
                                    }
                                }
                            
                            if showOtherTasksDueToday {
                                ForEach(tasks.filter({!($0.list == 1) && !$0.completed && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())})) { task in // filter out completed tasks, and keep only tasks due today that are not in the Now list
                                    HStack {
                                        TaskView(task: task)
//                                            .padding(.leading, 10)
                                        
                                        switch(task.list) {
                                        case 0:
                                            Image(systemName: "tray")
                                        case 1:
                                            Image(systemName: "scope")
                                        case 2:
                                            Image(systemName: "terminal.fill")
                                        case 3:
                                            Image(systemName: "text.append")
                                        default:
                                            Image(systemName: "tray")
                                        }
                                    }
                                }
                            }
                        }
                        
                            
//                        // Only in the Now list: show the number of tasks due today in other lists, if there are any, and link to the list of them:
//                        if list == 1 && tasks.filter({!($0.list == 1) && !$0.completed && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())}).count > 0 {
//                            NavigationLink {
//                                DueTodayView()
//                            } label: {
//                                HStack {
//                                    Spacer()
//                                    Text("Other due and overdue tasks") // count of uncompleted tasks due today and overdue
//                                    Spacer()
//                                    Text("\(tasks.filter({!($0.list == 1) && !$0.completed && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())}).count)")
//                                }
//                                .foregroundColor(.blue)
//                            }
//                            .swipeActions {
//                                Button { // move all of the due tasks to the bottom of Now
//
//                                    for task in tasks.filter({!($0.list == 1) && !$0.completed && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())}) {
//                                        task.order = (tasks.filter({$0.list == 1 && !$0.completed}).last?.order ?? 0) + 1 // set the order of the task to the order of the last uncompleted task of the destination list plus 1
//                                        task.list = 1
//                                        task.modifieddate = Date()
//                                    }
//
//                                    PersistenceController.shared.save() // save the changes
//                                } label: {
//                                    Label("Move to Now", systemImage: "scope")
//                                }
//                                .tint(.green)
//                            }
//                        }
                        
                    }
                    .listStyle(PlainListStyle())
                    
                    // Add task buttons:
                    HStack {
                        addTaskTopButton
                        addTaskToInbox
                        addTaskBottomButton
                    }
                }
                
                QuickActionView()
                
            }
            .sheet(isPresented: $showSearchView) {
                SearchView()
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
                        
                        if list == 1 {
                            clearNow
                        }
                        else if list == 2 {
                            clearNext
                        }
                    }
                }
            }
            .navigationTitle(list == 0 ? "Inbox" : list == 1 ? "Now" : list == 2 ? "Next" : "Someday")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func filterResult(task: Task) -> Bool { // filter out completed tasks, and tasks from other lists than the provided one. If I want to show deferred tasks, or if the task is not deferred, or if the start of the day of its date is before now, display the task. If the task has no project, or its project is set up to display all tasks, or just the first task and this is the first non-completed task of the project, display the task
        if task.list == list // task is in the specified list
            && !task.completed // task is not completed
            && ( showDeferred || !task.dateactive || !task.hideuntildate || Calendar.current.startOfDay(for: task.date ?? Date()) <= Date() ) // I want to show deferred tasks, or the task doesn't have a date, or isn't hidden until that date, or the start of day of the date is in the past
            && ( task.project == nil || task.project?.displayoption == "All" || (task.project?.displayoption == "First" && (task.project?.isFirstTask(order: task.order, list: task.list) != false) ) ) { // the task has no project, or all of the project's tasks should be displayed, or only the first one should be displayed, and this is the first one. If the project is on hold, the task will therefore not be displayed
            
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
//            var startOrder = tasks.filter  ({$0.list == list && !$0.completed && ( showDeferred || !$0.dateactive || !$0.hideuntildate || Calendar.current.startOfDay(for: $0.date ?? Date()) <= Date() ) && ( $0.project == nil || $0.project?.displayoption == "All" || ($0.project?.displayoption == "First" && ($0.project?.isFirstTask(order: $0.order, list: $0.list) != false) ) ) })[itemToMove].order
            var startOrder = tasks.filter({filterResult(task: $0)})[itemToMove].order
//            print(startOrder)
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                tasks.filter({filterResult(task: $0)})[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasks.filter({filterResult(task: $0)})[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = tasks.filter({filterResult(task: $0)})[destination].order + 1
            let newOrder = tasks.filter({filterResult(task: $0)})[destination].order
            while startIndex <= endIndex {
                tasks.filter({filterResult(task: $0)})[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasks.filter({filterResult(task: $0)})[itemToMove].order = newOrder // set the moved task's order to its final value
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
//            PersistenceController.shared.save() // don't save it now, otherwise it will show up as a blank task on other devices, and the task name might get erased
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
    
    var addTaskToInbox: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
            impactMed.impactOccurred() // haptic feedback
            
            tab.selection = 0
            
            // Create a new task:
            let task = Task(context: viewContext)
            task.id = UUID()
            task.order = (tasks.last?.order ?? 0) + 1
            task.list = 0
            task.name = ""
            task.createddate = Date()
//            PersistenceController.shared.save() // don't save it now, otherwise it will show up as a blank task on other devices, and the task name might get erased
        } label: {
            Image(systemName: "tray")
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
//            PersistenceController.shared.save() // don't save it now, otherwise it will show up as a blank task on other devices, and the task name might get erased
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
    
    var clearNow: some View {
        Button {
            showClearNowAlert = true
        } label: {
            Label("", systemImage: "xmark.circle")
        }
        .alert(isPresented: $showClearNowAlert) {
            Alert(title: Text("This will move all tasks that are not due now to the Next list"), message: Text("Are you sure?"), primaryButton: .default(Text("OK")) {
                
                // Clear all tasks from Now, except the ones that are due or overdue:
                for task in tasks.reversed() { // go through the tasks in reverse order, so that they end up in the same order as they were initially
                    if(task.list == 1 && ( !task.dateactive || Calendar.current.startOfDay(for: task.date ?? Date()) > Calendar.current.startOfDay(for: Date()) )) { // if the task is in the Now list, and has no date or is due after today
                        task.list = 2 // move the task to the top of the Next list
                        task.order = (tasks.filter({$0.list == 2}).first?.order ?? 0) - 1 // set the order of the task to the order of the first task of the destination list minus 1
                    }
                }
                PersistenceController.shared.save() // save the item
                
            }, secondaryButton: .cancel())
        }
    }
    
    var clearNext: some View {
        Button {
            showClearNextAlert = true
        } label: {
            Label("", systemImage: "xmark.circle")
        }
        .alert(isPresented: $showClearNextAlert) {
            Alert(title: Text("This will move all tasks to the Someday list"), message: Text("Are you sure?"), primaryButton: .default(Text("OK")) {
                
                // Clear all tasks from Next:
                for task in tasks.reversed() { // go through the elements in reverse order, so that they end up in the same order as they were initially
                    if(task.list == 2) { // if the item is in the Next list
                        task.list = 3 // move the item to the top of the Someday list
                        task.order = (tasks.filter({$0.list == 3}).first?.order ?? 0) - 1 // set the order of the task to the order of the first task of the destination list minus 1
                    }
                }
                PersistenceController.shared.save() // save the item
                
            }, secondaryButton: .cancel())
        }
    }
}

//struct ListView_Previews: PreviewProvider {
//    static var previews: some View {
//        ListView(list: 0, showDeferred: false)
//    }
//}
