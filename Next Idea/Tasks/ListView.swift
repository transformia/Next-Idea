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
    
    @State private var selectedProject: Project? // to have something to pass to the ProjectPickerView, even if it doesn't use it
    
    //    @Binding var selectedTab: Int // binding so that change made here impact the tab selected in ContentView
    @EnvironmentObject var tab: Tab
    @EnvironmentObject var homeActiveView: HomeActiveView // view selected in Home
    
    //    @State private var showOtherTasksDueToday =  false
    
    @State private var showProjectPicker = false
    @State private var showDatePicker = false
    @State private var showSearchView = false
    
    @State private var showClearFocusThenNextAlert = false
    
    @State private var expandInbox = true
    @State private var expandFocus = true
    @State private var expandDueOverdue = true
    @State private var expandNext = true
    @State private var expandWaiting = true
    @State private var expandDeferred = true
    @State private var expandSomeday = true
    
    var body: some View {
        NavigationStack {
            VStack { // Contains ZStack and Quick action buttons
                ZStack(alignment: .bottom) { // Contains task list and Add task buttons
                    
                    List {
                        
                        // Inbox:
                        if ( title == "Inbox" || title == "All tasks" || title == "Next" ) && tasks.filter({$0.filterTasks(filter: "Inbox")}).count > 0 { // if there are tasks without a project
                            //                            Section("Inbox") {
                            Section {
                                if(expandInbox) {
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
                            } header: {
                                HStack {
                                    Label("Inbox", systemImage: "tray")
                                    Spacer()
                                    Text("\(countTasks(filter: "Inbox"))")
                                    Image(systemName: expandInbox ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.blue)
                                        .font(.footnote)
                                }
                                .contentShape(Rectangle()) // make the whole HStack tappable
                                .onTapGesture {
                                    withAnimation {
                                        expandInbox.toggle()
                                    }
                                }
                            }                            
                        }
                        
                        // Focused, not deferred:
                        if ( title == "Focus" || title == "Next" || title == "All tasks" ) && tasks.filter({$0.filterTasks(filter: "Focus") && !$0.filterTasks(filter: "Deferred")}).count > 0 { // if there are focused tasks that are not deferred
                            Section {
                                if(expandFocus) {
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
                        
                        // Due:
                        if (title == "Due" || title == "All tasks") && tasks.filter({$0.filterTasks(filter: "Due")}).count > 0 { // if there are focused tasks
                            Section {
                                if(expandDueOverdue) {
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
                        
                        // Next actions, not deferred:
                        if (title == "Next" || title == "All tasks") && tasks.filter({$0.filterTasks(filter: "Next") && !$0.filterTasks(filter: "Deferred") && ( !($0.project?.sequential ?? false) || $0.isFirst() ) }).count > 0 {
                            Section {
                                if expandNext {
                                    // Show tasks that Next, not Deferred, and that are either not in a project, are in a non sequential project, or are the first task of their project
                                    ForEach(tasks.filter({$0.filterTasks(filter: "Next") && !$0.filterTasks(filter: "Deferred") && ( !($0.project?.sequential ?? false) || $0.isFirst() )})) { task in
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
                        
                        // Waiting for:
                        if (title == "Waiting for" || title == "All tasks") && tasks.filter({$0.filterTasks(filter: "Waiting for") && !$0.filterTasks(filter: "Deferred")}).count > 0 { // if there are focused tasks
                            Section {
                                if expandWaiting {
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
                                                
                        // Deferred:
                        if (title == "Deferred" || title == "All tasks") && tasks.filter({$0.filterTasks(filter: "Deferred")}).count > 0 { // if there are non-completed deferred tasks
                            Section {
                                if expandDeferred {
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
                        
                        // Someday:
                        if (title == "Someday" || title == "All tasks") && tasks.filter({$0.filterTasks(filter: "Someday") && !$0.filterTasks(filter: "Deferred")}).count > 0 {
                            Section {
                                if expandSomeday {
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
//                    .padding(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8)) // reduce padding of the list items
//                    .listStyle(.grouped)
//                    .listStyle(SidebarListStyle()) // so that the sections are expandable and collapsible. Could instead use PlainListStyle, but with DisclosureGroups instead of Sections...
                    .listStyle(PlainListStyle())
                    
                    // Add task buttons:
                    AddTaskButtonsView(defaultFocus: title == "Focus" ? true : false, defaultWaitingFor: title == "Waiting for" ? true : false, defaultProject: nil, defaultTag: nil)
                }
                
                QuickActionView()
                
            }
            .onAppear {
                if tab.selection != 2 {
                    homeActiveView.stringName = title // change the tab name and logo, except if I open the Next actions tab
                }
            }
//            .onAppear {
//                if title == "All tasks" {
//                    expandInbox = true
//                    expandFocus = true
//                    expandDueOverdue = false
//                    expandNext = false
//                    expandWaiting = false
//                    expandDeferred = false
//                    expandSomeday = false
//                }
//            }
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
                                    Label("", systemImage: "lightbulb.2.fill")
                                }
                                else {
                                    Label("", systemImage: "lightbulb.2")
                                }
                                Text("\(countTasksToBeReviewed())")
                            }
                        }
                        
                        if title == "All tasks" || title == "Next" {
//                            focusButton
                            expandCollapseSectionsButton
                        }
                        
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
                        
                        if title == "Next" || title == "All tasks" || title == "Focus" {
                            clearFocusThenNextButton
                        }
                        
//                        if title == "Next" || title == "All tasks" {
//                            clearNextButton
//                        }
//                        else if title == "Focus" {
//                            clearFocusButton
//                        }
                        
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
        if title != "All tasks" {
            return tasks.filter({
                $0.filterTasks(filter: title)
                && Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date())
            }).count
        }
        else { // for the All tasks view
            return tasks.filter({
                !$0.completed
                && Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date())
            }).count
        }
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
    
    
    var clearFocusThenNextButton: some View {
        Button {
            showClearFocusThenNextAlert = true
        } label: {
            Label("", systemImage: "xmark.circle")
        }
        .alert(isPresented: $showClearFocusThenNextAlert) {
            Alert(title: Text(tasks.filter({$0.focus}).count > 0 ? "This will clear the Focus list, moving all of focused tasks to the Next list" : "This will move all tasks to the Someday list"), message: Text("Are you sure?"), primaryButton: .default(Text("OK")) {
                
                if tasks.filter({$0.focus}).count > 0 {
                    // Clear all tasks from Focus:
                    var i: Int64 = 0
                    for task in tasks.reversed() { // go through the elements in reverse order, so that they end up in the same order as they were initially
                        if(task.focus) { // if the item is in the Focus list
                            task.order = (tasks.filter({!$0.focus}).first?.order ?? 0) - 1 - i // set the order of the task to the order of the first task of the destination list minus 1, minus the number of tasks that I have already moved
                            task.focus = false
                            i += 1 // increment i
                        }
                    }
                    PersistenceController.shared.save() // save the item
                }
                else {
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
                }
                
            }, secondaryButton: .cancel())
        }
//        .alert(isPresented: $showClearNextAlert) {
//            Alert(title: Text("This will move all tasks to the Someday list"), message: Text("Are you sure?"), primaryButton: .default(Text("OK")) {
//
//                // Clear all tasks from Next, and remove focus:
//                var i: Int64 = 0
//                for task in tasks.reversed() { // go through the elements in reverse order, so that they end up in the same order as they were initially
//                    if(!task.someday) { // if the item is in the Next list
//                        task.order = (tasks.filter({$0.someday}).first?.order ?? 0) - 1 - i // set the order of the task to the order of the first task of the destination list minus 1, minus the number of tasks that I have already moved
//                        task.someday = true // move the item to the top of the Someday list
//                        task.focus = false
//                        i += 1 // increment i
//                    }
//                }
//                PersistenceController.shared.save() // save the item
//
//            }, secondaryButton: .cancel())
//        }
    }
    
    /*var clearFocusButton: some View {
        Button {
            showClearFocusAlert = true
        } label: {
            Label("", systemImage: "xmark.circle")
        }
        .alert(isPresented: $showClearFocusAlert) {
            Alert(title: Text("This will clear the Focus list, moving all of focused tasks to the Next list"), message: Text("Are you sure?"), primaryButton: .default(Text("OK")) {
                
                // Clear all tasks from Focus:
                var i: Int64 = 0
                for task in tasks.reversed() { // go through the elements in reverse order, so that they end up in the same order as they were initially
                    if(task.focus) { // if the item is in the Focus list
                        task.order = (tasks.filter({!$0.focus}).first?.order ?? 0) - 1 - i // set the order of the task to the order of the first task of the destination list minus 1, minus the number of tasks that I have already moved
                        task.focus = false
                        i += 1 // increment i
                    }
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
    }*/
    
    var expandCollapseSectionsButton: some View {
        Button {
            if expandDueOverdue || expandNext || expandWaiting || expandDeferred || expandSomeday {
                expandInbox = false
                expandFocus = true
                expandDueOverdue = false
                expandNext = false
                expandWaiting = false
                expandDeferred = false
                expandSomeday = false
            }
            else {
                expandInbox = true
                expandFocus = true
                expandDueOverdue = true
                expandNext = true
                expandWaiting = true
                expandDeferred = true
                expandSomeday = true
            }
        } label: {
            Label("", systemImage: expandDueOverdue || expandNext || expandWaiting || expandDeferred || expandSomeday ? "list.bullet" : "list.bullet.indent")
        }
    }
    
//    var focusButton: some View {
//        Button {
//            showOnlyFocus.toggle()
//        } label: {
//            Label("", systemImage: "scope")
//        }
//    }
}

//struct ListView_Previews: PreviewProvider {
//    static var previews: some View {
//        ListView(list: 0, showDeferred: false)
//    }
//}
