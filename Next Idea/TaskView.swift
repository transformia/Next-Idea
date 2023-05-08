//
//  TaskView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct TaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task> // to be able to change the order of the task
    
    let task: Task
    
    @State private var name = ""
    
    @State private var dateColor: Color = .primary // color in which the due date and reminder date are displayed
    
    @FocusState private var focused: Bool
    
    @State private var showTaskDetails = false
    
    var body: some View {
        VStack(alignment: HorizontalAlignment.leading) {
            HStack {
                TextField("", text: $name, axis: .vertical)
                    .focused($focused)
                    .foregroundColor(task.ticked && !task.completed ? .gray : task.selected ? .teal : task.waitingfor ? .gray : nil) // color the task if it is ticked, but not if it is already in the completed tasks view. color the task teal if it is selected
                    .strikethrough(task.ticked && !task.completed) // strike through the task if it is ticked, but not if it is already in the completed tasks view
                    .onAppear {
                        name = task.name ?? ""
                        if name == "" {
                            focused = true // focus on the task when it is created
                        }
                    }
                    .onChange(of: name) { _ in
                        task.name = name // save the changes
                        PersistenceController.shared.save()
                        
                        // If I press enter:
                        if name.contains("\n") { // if a newline is found
                            name = name.replacingOccurrences(of: "\n", with: "") // replace it with nothing
                            focused = false // close the keyboard
                            task.name = name // save the changes
                            PersistenceController.shared.save()
                        }
                    }
                
                if focused || task.selected { // if I'm editing the task name, or have selected it, show a button to open the task details
                    Label("Task details", systemImage: "info.circle")
                        .labelStyle(.iconOnly)
                        .foregroundColor(.cyan)
                        .onTapGesture {
                            focused = false
                            showTaskDetails = true
                        }
                }
                
//                Text("\(task.order)")
            }
            
            if task.dateactive {
                HStack {
                    duedatetimeText
                        .padding(.trailing, -5) // so the space isn't too large between the due date and the recurrence
                    if(task.recurring) {
                        if task.recurrence == 1 {
                            switch(task.recurrencetype) {
                            case "days":
                                Text("- daily")
                                    .foregroundColor(dateColor)
                                    .font(.footnote)
                            case "weeks":
                                Text("- weekly")
                                    .foregroundColor(dateColor)
                                    .font(.footnote)
                            case "months":
                                Text("- monthly")
                                    .foregroundColor(dateColor)
                                    .font(.footnote)
                            case "years":
                                Text("- yearly")
                                    .foregroundColor(dateColor)
                                    .font(.footnote)
                            default:
                                Text("")
                            }
                        }
                        else {
                            Text("- every \(task.recurrence) ")
                                .foregroundColor(dateColor)
                                .font(.footnote)
                            + Text(task.recurrencetype ?? "days")
                                .foregroundColor(dateColor)
                                .font(.footnote)
                        }
                    }
                }
                .onAppear {
                    setDateColor(task: task) // color the date depending on when it is
                }
                .onChange(of: task.date) { _ in
                    setDateColor(task: task) // color the date depending on when it is
                }
            }
        }
        .onTapGesture { // make the whole VStack tappable for editing the task name
            focused = true
        }
        .swipeActions(edge: .leading) {
            
            Button { // tick this task if it is not recurring, otherwise increment its date
                if !task.recurring {
                    task.ticked.toggle()
                    if !task.ticked { // if I'm uncompleting a task, mark it as not complete after a short while
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) { // complete the task after N seconds if it is still ticked
                            task.completed = false
                        }
                    }
                }
                else { // else if the task is recurring, increment its date
                    switch(task.recurrencetype) {
                    case "days":
                        task.date = Calendar.current.date(byAdding: .day, value: Int(task.recurrence), to: task.date ?? Date())
                    case "weeks":
                        task.date = Calendar.current.date(byAdding: .day, value: 7 * Int(task.recurrence), to: task.date ?? Date())
                    case "months":
                        task.date = Calendar.current.date(byAdding: .month, value: Int(task.recurrence), to: task.date ?? Date())
                    case "years":
                        task.date = Calendar.current.date(byAdding: .year, value: Int(task.recurrence), to: task.date ?? Date())
                    default:
                        print("Invalid recurrence")
                    }
                }
            } label: {
                Label("Complete", systemImage: "checkmark")
            }
            .tint(.green)
            
            // Move the task to the top or to the bottom:
            
            Button {
                task.order = (tasks.filter({$0.list == task.list && !$0.completed}).first?.order ?? 0) - 1 // set the order of the task to the order of the first uncompleted task of the destination list minus 1
                PersistenceController.shared.save() // save the item
            } label: {
                Label("Move to top", systemImage: "arrow.up")
            }
            .tint(.blue)
            
            Button {
                task.order = (tasks.filter({$0.list == task.list && !$0.completed}).last?.order ?? 0) + 1 // set the order of the task to the order of the last uncompleted task of the destination list plus 1
                PersistenceController.shared.save() // save the item
            } label: {
                Label("Move to bottom", systemImage: "arrow.down")
            }
            .tint(.orange)
            
            
        }
        .swipeActions(edge: .trailing) { // move the task to another list, or edit its details
            
            Button { // select this task
                task.selected.toggle()
            } label: {
                Label("Select", systemImage: "pin.circle")
            }
            .tint(.teal)
            
//            // Edit the task details:
//            Button {
//                showTaskDetails = true
//            } label: {
//                Label("Details", systemImage: "info.circle")
//            }
//            .tint(.cyan)
            
            if task.list != 1 {
                // Move the task to Now:
                Button {
                    task.order = (tasks.filter({$0.list == 1 && !$0.completed}).first?.order ?? 0) - 1 // set the order of the task to the order of the first uncompleted task of the destination list minus 1
                    task.list = 1
                    task.modifieddate = Date()
                    PersistenceController.shared.save() // save the item
                } label: {
                    Label("Now", systemImage: "scope")
                }
                .tint(.green)
            }
            
            if task.list != 2 {
                // Move the task to Next:
                Button {
                    task.order = (tasks.filter({$0.list == 2 && !$0.completed}).first?.order ?? 0) - 1 // set the order of the task to the order of the first uncompleted task of the destination list minus 1
                    task.list = 2
                    task.modifieddate = Date()
                    PersistenceController.shared.save() // save the item
                } label: {
                    Label("Next", systemImage: "terminal.fill")
                }
                .tint(.blue)
            }
            
            if task.list != 3 {
                // Move the task to Someday:
                Button {
                    task.order = (tasks.filter({$0.list == 3 && !$0.completed}).first?.order ?? 0) - 1 // set the order of the task to the order of the first uncompleted task of the destination list minus 1
                    task.list = 3
                    task.modifieddate = Date()
                    PersistenceController.shared.save() // save the item
                } label: {
                    Label("Someday", systemImage: "text.append")
                }
                .tint(.brown)
            }
            
            if task.list != 0 {
                // Toggle Waiting for on the task:
                Button {
                    task.waitingfor.toggle()
                    task.modifieddate = Date()
                    PersistenceController.shared.save() // save the item
                } label: {
                    Label("Waiting", systemImage: "stopwatch")
                }
                .tint(.gray)
            }
        }
        .sheet(isPresented: $showTaskDetails) {
            TaskDetailsView(task: task)
        }
    }
    
    var duedatetimeText: some View {
        if(Calendar.current.startOfDay(for: task.date ?? Date()) == Calendar.current.startOfDay(for: Date())) { // if the due date is today
            if(task.reminderactive) { // if there is a reminder, return the due date and time
                return Text("Today ")
                    .foregroundColor(dateColor)
                    .font(.footnote)
                
                + Text(task.date ?? Date(), formatter: timeFormatter)
                    .foregroundColor(dateColor)
                    .font(.footnote)
            } else { // else if there is just a due date, return just the due date
                return Text("Today")
                    .foregroundColor(dateColor)
                    .font(.footnote)
            }
        }
        
        else if(Calendar.current.startOfDay(for: task.date ?? Date()) == Calendar.current.startOfDay(for:Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())) { // else if the due date is tomorrow
            
            if(task.reminderactive) { // if there is a reminder, return the due date and time
                return Text("Tomorrow ")
                    .foregroundColor(dateColor)
                    .font(.footnote)
                
                + Text(task.date ?? Date(), formatter: timeFormatter)
                    .foregroundColor(dateColor)
                    .font(.footnote)
            } else { // else if there is just a due date, return just the due date
                return Text("Tomorrow")
                    .foregroundColor(dateColor)
                    .font(.footnote)
            }
        }
        
        else { // else if the due date is not today nor tomorrow
            
            if(task.reminderactive) { // if there is a reminder, return the due date and time
                return Text(task.date ?? Date(), formatter: dateTimeFormatter)
                    .foregroundColor(dateColor)
                    .font(.footnote)
            }
            else { // else if there is just a due date, return just the due date
                return Text(task.date ?? Date(), formatter: dateFormatter)
                    .foregroundColor(dateColor)
                    .font(.footnote)
            }
        }
    }
    
    private func setDateColor(task: Task) { // determine which color the due date and reminder should have
        if(task.dateactive) {
            if(task.reminderactive) {
                dateColor = task.date ?? Date() >= Date() ? .green : .red // green for due in the future or today, red for due in the past
            }
            else {
                dateColor = Calendar.current.startOfDay(for: task.date ?? Date()) >= Date() ? .green : .red  // green for due in the future or today, red for due in the past
            }
            if(Calendar.current.startOfDay(for: task.date ?? Date()) == Calendar.current.startOfDay(for: Date())) { // if the task is due today / has a reminder today, change the color to blue
                dateColor = .blue
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
//        formatter.dateStyle = .medium
        return formatter
    }()
    
    private let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d HH:mm"
//        formatter.dateStyle = .medium
//        formatter.timeStyle = .short
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

struct TaskView_Previews: PreviewProvider {
    static var previews: some View {
        TaskView(task: Task())
    }
}
