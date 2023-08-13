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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.order, ascending: true)],
        animation: .default)
    private var projects: FetchedResults<Project> // to be able to select the Single actions project
    
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.id, ascending: true)],
//        animation: .default)
//    private var tags: FetchedResults<Tag> // to be able to display the tags that have been selected
    
    @FetchRequest private var tags: FetchedResults<Tag>
    
    let task: Task
    
    @EnvironmentObject var weeklyReview: WeeklyReview
    
    init(task: Task) { // filter the tag list on the ones that contain the provided task
        self.task = task
        _tags = FetchRequest(
            entity: Tag.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Tag.id, ascending: true)
            ],
            predicate: NSPredicate(format: "tasks CONTAINS %@", task)
        )
    }
    
    @State private var name = ""
    
    @State private var dateColor: Color = .primary // color in which the due date and reminder date are displayed
    
    @FocusState private var focusOnName: Bool
    
    @State private var showTaskDetails = false
    
    @State private var notificationExists = false
    
    var body: some View {
        VStack(alignment: HorizontalAlignment.leading) {
            HStack {
                
                if weeklyReview.active {
                    Image(systemName: Calendar.current.startOfDay(for: task.nextreviewdate ?? Date()) > Calendar.current.startOfDay(for: Date()) ? "figure.yoga" : "figure.mind.and.body")
                        .foregroundColor(Calendar.current.startOfDay(for: task.nextreviewdate ?? Date()) > Calendar.current.startOfDay(for: Date()) ? .green : nil)
                        .onTapGesture { // if the task has a next review date today or in the past, push it forward by 7 days. Else set it back to today
                            if Calendar.current.startOfDay(for: task.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date()) {
                                task.nextreviewdate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
                            }
                            else {
                                task.nextreviewdate = Date()
                            }
                            PersistenceController.shared.save()
                        }
                }
                
                else if(UserDefaults.standard.bool(forKey: "Checkbox")) { // else if the checkbox is activated in the settings
                    Image(systemName: task.ticked ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .frame(width: 24.0, height: 24.0)
                        .onTapGesture {
                            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                            impactMed.impactOccurred() // haptic feedback
                            completeTask(task: task)
                        }
                        .foregroundColor(task.recurring ? .blue : nil)
//                        .animation(.easeInOut(duration: 5), value: task.ticked)
//                        .padding(.top, 10)
                }
                
                Text(task.name ?? "")
                    .font(.subheadline)
                    .padding([.top, .bottom], 5)
                    .foregroundColor(task.ticked && !task.completed ? .gray // color the task if it is ticked, but not if it is already in the completed tasks view.
                                     : weeklyReview.active && (Calendar.current.startOfDay(for: task.nextreviewdate ?? Date()) > Calendar.current.startOfDay(for: Date())) ? .green // color the task green if weekly review is active, and the next review date is in the future
                                     : task.selected ? .teal // color the task teal if it is selected
                                     : task.waitingfor ? .gray : nil // color the task if it is waiting for
                    )
                    .strikethrough(task.ticked && !task.completed) // strike through the task if it is ticked, but not if it is already in the completed tasks view
               
//                if task.note != "" || task.link != "" || ( task.dateactive && task.reminderactive ) {
                    Spacer() // push the icons to the right
//                }
                
                VStack {
                    
                    // Show an icon if the task has a note:
                    if task.note != "" {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    // Show an icon if the task has a link:
                    if task.link != "" {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
//                Text("\(task.order)")
            }
            
            HStack { // Contains the date and the tags
                
                // If the task has a date, display it:
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
                        
                        if task.reminderactive { // if the task has a reminder, check if it has an active notification
                            checkNotificationExistence()
                        }
                    }
                    .onChange(of: task.date) { _ in
                        setDateColor(task: task) // color the date depending on when it is
                    }
                    
                    // Show an icon if the task has a reminder, and the notification exists on this device:
                    if task.reminderactive && notificationExists {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                
                // If the task has tags, display them:
                if task.tags != nil {
                    
                    Spacer()
                    HStack {
                        ForEach(tags) { tag in
                            Text("\(tag.name ?? "")")
                                .font(.footnote)
                        }
                    }
                }
            }
        }
        .onTapGesture { // make the whole VStack tappable for editing the task name, or selecting / deselecting the task
//            print("Tapping on task")
            if tasks.filter({$0.selected}).count > 0 { // if at least one task is already selected, tapping on another task selects it, and tapping on a selected task deselects it
                let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                impactMed.impactOccurred() // haptic feedback
                task.selected.toggle()
            }
            else { // else if no tasks are selected, tapping on a task opens the task details
                showTaskDetails = true
            }
            PersistenceController.shared.save()
        }
        .swipeActions(edge: .leading) {
            
            Button { // tick this task if it is not recurring, otherwise increment its date
                completeTask(task: task)
            } label: {
                Label("Complete", systemImage: "checkmark")
            }
            .tint(.green)
            
            // Move the task to the top or to the bottom:
            Button {
                task.order = (tasks.filter({!$0.completed}).first?.order ?? 0) - 1 // set the order of the task to the order of the first uncompleted task minus 1
                PersistenceController.shared.save() // save the item
            } label: {
                Label("Move to top", systemImage: "arrow.up")
            }
            .tint(.blue)
            
            Button {
                task.order = (tasks.filter({!$0.completed}).last?.order ?? 0) + 1 // set the order of the task to the order of the last uncompleted task plus 1
                PersistenceController.shared.save() // save the item
            } label: {
                Label("Move to bottom", systemImage: "arrow.down")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing) { // move the task to another list, or edit its details
                        
            Button { // select or unselect this task
                task.selected.toggle()
                PersistenceController.shared.save()
            } label: {
                Label("Select", systemImage: "pin.circle")
            }
            .tint(.teal)
            
            // Make the task focused:
            if !task.focus {
                Button {
                    // Put the task at the bottom of the Focused list, and put it in the Single actions project if it doesn't have a project:
                    task.focus = true
                    task.someday = false
                    task.order = (tasks.filter({!$0.completed}).last?.order ?? 0) + 1
                    //                if !task.focus {
                    //                    task.order = (tasks.filter({$0.list == 2 && !$0.completed}).first?.order ?? 0) - 1 // set the order of the task to the order of the first uncompleted task of the Next list minus 1
                    //                }
                    //                else {
                    //                    task.someday = false // move the task to the Next list
                    //                }
                    if task.project == nil && projects.filter({$0.singleactions}).count == 1 { // if the task has no project, and there is a single actions project, assign the single actions project to the task
                        task.project = projects.filter({$0.singleactions})[0]
                    }
                    task.modifieddate = Date()
                    PersistenceController.shared.save() // save the item
                } label: {
                    Label("Focus", systemImage: "scope")
                }
                .tint(.green)
            }
            
            if task.someday || task.focus || task.project == nil {
                // Move the task to the top of Next, and put it in the Single actions project if it doesn't have a project:
                Button {
                    task.focus = false
                    task.someday = false
                    task.order = (tasks.filter({!$0.completed}).first?.order ?? 0) - 1
//                    task.order = (tasks.filter({!$0.someday && !$0.completed}).first?.order ?? 0) - 1 // set the order of the task to the order of the first uncompleted task of the destination list minus 1
                    if task.project == nil && projects.filter({$0.singleactions}).count == 1 { // if the task has no project, and there is a single actions project, assign the single actions project to the task
                        task.project = projects.filter({$0.singleactions})[0]
                    }
                    task.modifieddate = Date()
                    PersistenceController.shared.save() // save the item
                } label: {
                    Label("Next", systemImage: "terminal.fill")
                }
                .tint(.blue)
            }
            
            if !task.someday {
                // Move the task to the top of Someday, and put it in the Single actions project if it doesn't have a project:
                Button {
                    task.focus = false
                    task.someday = true
                    task.order = (tasks.filter({!$0.completed}).first?.order ?? 0) - 1
                    if task.project == nil && projects.filter({$0.singleactions}).count == 1 { // if the task has no project, and there is a single actions project, assign the single actions project to the task
                        task.project = projects.filter({$0.singleactions})[0]
                    }
                    task.modifieddate = Date()
                    PersistenceController.shared.save() // save the item
                } label: {
                    Label("Someday", systemImage: "text.append")
                }
                .tint(.brown)
            }
            
//            if task.list != 0 {
                // Toggle Waiting for on the task, and put it in the Single actions project if it doesn't have a project:
                Button {
                    task.waitingfor.toggle()
                    task.modifieddate = Date()
                    if task.project == nil && projects.filter({$0.singleactions}).count == 1 { // if the task has no project, and there is a single actions project, assign the single actions project to the task
                        task.project = projects.filter({$0.singleactions})[0]
                    }
                    PersistenceController.shared.save() // save the item
                } label: {
                    Label("Waiting", systemImage: "stopwatch")
                }
                .tint(.gray)
//            }
        }
        .sheet(isPresented: $showTaskDetails) {
            TaskDetailsView(task: task, defaultFocus: false, defaultWaitingFor: false, defaultProject: nil, defaultTag: nil)
        }
    }
    
    private func completeTask(task: Task) {
        // Deselect the task if it was selected:
        task.selected = false
        
        // If the task isn't recurring, complete it after a certain time:
        if !task.recurring {
            task.ticked.toggle()
            task.modifieddate = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) { // complete or uncomplete the task after N seconds
                task.completed = task.ticked                
                PersistenceController.shared.save()
                
                // Cancel the notification if there was one:
                task.cancelNotification()
            }

//            if !task.ticked { // if I'm uncompleting a task, mark it as not complete after a short while
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) { // complete the task after N seconds if it is still ticked
//                    task.completed = false
//                }
//            }
        }
        // Else if the task is recurring, move its date forward:
        else { // else if the task is recurring, increment its date after N seconds, and remove the focus from it
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
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
                task.focus = false
                PersistenceController.shared.save()
                
                // Cancel the notification if there is a reminder, and create it again with the new date and time:
                if task.reminderactive {
                    task.cancelNotification()
                    task.createNotification()
                }
            }
        }
    }
    
    private func checkNotificationExistence() {
        let identifier = String(describing: task.id)
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                notificationExists = requests.contains { request in
                    print("Notification found, \(String(describing: request.trigger))")
                    return request.identifier == identifier
                }
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
