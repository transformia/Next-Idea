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
    
    @State private var selectMultipleTasks = false
    @State private var selectedTasks: [Task] = []
    @State private var showProjectPicker = false
    @State private var showDatePicker = false
    @State private var showDateTimePicker = false
    @State private var showListPicker = false
    
    @State private var date = Date()
    @State private var selectedList: Int16 = 0
    
    // Define lists:
    let lists = [(Int16(0), "Inbox"), (Int16(1), "Now"), (Int16(2), "Next"), (Int16(3), "Someday")]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                
                List {
                    ForEach(tasks.filter({$0.list == list && !$0.completed && ( showDeferred || !$0.dateactive || !$0.hideuntildate || Calendar.current.startOfDay(for: $0.date ?? Date()) <= Date()) })) { task in // filter out completed tasks, and tasks from other lists than the provided one. If I want to show deferred tasks, or if the task is not deferred, or if the start of the day of its date is before now, display the task
                        HStack {
                            if selectMultipleTasks {
                                Image(systemName: selectedTasks.contains(task) ? "circle.fill" : "circle")
                                    .onTapGesture {
                                        if selectedTasks.contains(task) {
                                            selectedTasks = selectedTasks.filter({$0 != task})
                                        }
                                        else {
                                            selectedTasks.append(task)
                                        }
                                    }
                            }
                            TaskView(task: task)
                        }
                    }
                    .onMove(perform: moveItem)
                }
                
                if tasks.filter({$0.list == list && !$0.completed && $0.ticked}).count > 0 { // if there are ticked tasks displayed, show a button to hide them
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
                
                // Date picker:
                if showDatePicker {
                    HStack {
                        
                        Spacer()
                        Spacer()
                        
                        Button { // remove the date and reminder
                            for task in selectedTasks {
                                task.dateactive = false
                                task.reminderactive = false
//                                task.date = Date()
                                task.modifieddate = Date()
                                PersistenceController.shared.save()
                            }
                            showDatePicker = false
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.red)
                                .frame(width: 20, height: 20)
                        }
                        
                        Spacer()
                        
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .frame(width: 120)
                        
                        Spacer()
                        
                        Button { // save the date
                            for task in selectedTasks {
                                task.dateactive = true
                                task.reminderactive = false
                                task.date = date
                                task.modifieddate = Date()
                                PersistenceController.shared.save()
                            }
                            showDatePicker = false
                        } label: {
                            Image(systemName: "checkmark")
                                .frame(width: 20, height: 20)
                        }
                        
                        Spacer()
                        Spacer()
                    }
                    .padding(.bottom, 120)
                }
                
                // Date time picker:
                else if showDateTimePicker {
                    HStack {
                        
                        Spacer()
                        Spacer()
                        
                        Button { // remove the date and reminder
                            for task in selectedTasks {
                                task.dateactive = false
                                task.reminderactive = false
//                                task.date = Date()
                                task.modifieddate = Date()
                                PersistenceController.shared.save()
                            }
                            showDateTimePicker = false
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.red)
                                .frame(width: 20, height: 20)
                        }
                        
                        Spacer()
                        
                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .frame(width: 200)
                        
                        Spacer()
                        
                        Button {
                            for task in selectedTasks {
                                task.dateactive = true
                                task.reminderactive = true
                                task.date = date
                                task.modifieddate = Date()
                                PersistenceController.shared.save()
                            }
                            showDateTimePicker = false
                        } label: {
                            Image(systemName: "checkmark")
                                .frame(width: 20, height: 20)
                        }
                        
                        Spacer()
                        Spacer()
                    }
                    .padding(.bottom, 120)
                    
                }
                
                else if selectMultipleTasks && selectedTasks.count > 0 { // show icons to move the tasks to other lists if the multiple selection is active and at least one task is selected
                    HStack {
                        
//                        Spacer()
                        
                        Button {
                            for task in selectedTasks {
                                task.list = 0
                                task.modifieddate = Date()
                                PersistenceController.shared.save()
                            }
                            showListPicker = false
                            selectMultipleTasks = false
                            selectedTasks = [] // clear the array of selected tasks
                        } label: {
                            Image(systemName: "tray")
                                .resizable()
                                .frame(width: 26, height: 26)
                                .foregroundColor(.white)
                                .padding(10)
                        }
                        
//                        Spacer()
                        
                        Button {
                            for task in selectedTasks {
                                task.list = 1
                                task.modifieddate = Date()
                                PersistenceController.shared.save()
                            }
                            showListPicker = false
                            selectMultipleTasks = false
                            selectedTasks = [] // clear the array of selected tasks
                        } label: {
                            Image(systemName: "scope")
                                .resizable()
                                .frame(width: 26, height: 26)
                                .foregroundColor(.white)
                                .padding(10)
                        }
                        
//                        Spacer()
                        
                        Button {
                            for task in selectedTasks {
                                task.list = 2
                                task.modifieddate = Date()
                                PersistenceController.shared.save()
                            }
                            showListPicker = false
                            selectMultipleTasks = false
                            selectedTasks = [] // clear the array of selected tasks
                        } label: {
                            Image(systemName: "terminal.fill")
                                .resizable()
                                .frame(width: 26, height: 26)
                                .foregroundColor(.white)
                                .padding(10)
                        }
                        
//                        Spacer()
                        
                        Button {
                            for task in selectedTasks {
                                task.list = 3
                                task.modifieddate = Date()
                                PersistenceController.shared.save()
                            }
                            showListPicker = false
                            selectMultipleTasks = false
                            selectedTasks = [] // clear the array of selected tasks
                        } label: {
                            Image(systemName: "text.append")
                                .resizable()
                                .frame(width: 26, height: 26)
                                .foregroundColor(.white)
                                .padding(10)
                        }
                        
//                        Spacer()
                        
//                        Picker("List", selection: $selectedList) {
//                            ForEach(lists, id: \.self.0) {
//                                Text($0.1)
//                                    .tag($0.0)
//                            }
//                        }
//                        .onAppear {
//                            selectedList = list
//                        }
//                        Button {
//                            for task in selectedTasks {
//                                task.list = selectedList
//                                task.modifieddate = Date()
//                                PersistenceController.shared.save()
//                            }
//                            showListPicker = false
//                            selectMultipleTasks = false
//                            selectedTasks = [] // clear the array of selected tasks
//                        } label: {
//                            Image(systemName: "checkmark")
//                        }
                    }
                    .padding(.bottom, 120)
                }
                
                // Multiple selection actions:
                if selectMultipleTasks && selectedTasks.count > 0 {
                    HStack {
                        
                        Button {
                            showDatePicker.toggle()
                            showDateTimePicker = false
                            showListPicker = false
                        } label: {
                            Image(systemName: "calendar")
                                .resizable()
                                .frame(width: 26, height: 26)
                                .foregroundColor(.white)
                                .padding(10)
                        }
                        
                        
                        Button {
                            showDateTimePicker.toggle()
                            showDatePicker = false
                            showListPicker = false
                        } label: {
                            Image(systemName: "calendar.badge.clock")
                                .resizable()
                                .frame(width: 26, height: 26)
                                .foregroundColor(.white)
                                .padding(10)
                        }
                        
                        
//                        Button {
//                            showListPicker.toggle()
//                            showDatePicker = false
//                            showDateTimePicker = false
//                        } label: {
//                            Image(systemName: "list.bullet")
//                                .resizable()
//                                .frame(width: 26, height: 26)
//                                .foregroundColor(.white)
//                                .padding(10)
//                        }
                        
                        Button {
                            showProjectPicker = true
                            showListPicker = false
                            showDatePicker = false
                            showDateTimePicker = false
                        } label: {
                            Image(systemName: "book.fill")
                                .resizable()
                                .frame(width: 26, height: 26)
                                .foregroundColor(.white)
                                .padding(10)
                        }
                        .sheet(isPresented: $showProjectPicker) {
                            ProjectPicker(tasks: selectedTasks)
                        }
                    }
                    .padding(.bottom, 60)
                }
                
                // Add task buttons:
                HStack {
                    addTaskTopButton
                    addTaskBottomButton
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button {
                            selectMultipleTasks.toggle()
                            if !selectMultipleTasks {
                                selectedTasks = [] // clear the array of selected tasks
                            }
                        } label: {
                            Label("", systemImage: selectMultipleTasks ? "filemenu.and.selection" : "filemenu.and.cursorarrow")
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
    
    private func moveItem(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        
        // If the item is moving down:
        if itemToMove < destination {
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = tasks.filter({$0.list == list && !$0.completed})[itemToMove].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                tasks.filter({$0.list == list && !$0.completed})[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasks.filter({$0.list == list && !$0.completed})[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = tasks.filter({$0.list == list && !$0.completed})[destination].order + 1
            let newOrder = tasks.filter({$0.list == list && !$0.completed})[destination].order
            while startIndex <= endIndex {
                tasks.filter({$0.list == list && !$0.completed})[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasks.filter({$0.list == list && !$0.completed})[itemToMove].order = newOrder // set the moved task's order to its final value
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
