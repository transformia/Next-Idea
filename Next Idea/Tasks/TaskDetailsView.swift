//
//  TaskDetailsView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-04.
//

import SwiftUI

struct TaskDetailsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task> // to be able to add a task to the top or bottom of the list
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.order, ascending: true)],
        animation: .default)
    private var projects: FetchedResults<Project> // to be able to select the Single actions project
    
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.id, ascending: true)],
//        animation: .default)
//    private var tags: FetchedResults<Tag> // to be able to display the tags that have been selected
    
    @FetchRequest private var tags: FetchedResults<Tag>
    
    let task: Task?
    
    var defaultFocus: Bool
    var defaultWaitingFor: Bool
    var defaultProject: Project?
    var defaultTag: Tag?
    
    init(task: Task?, defaultFocus: Bool, defaultWaitingFor: Bool, defaultProject: Project?, defaultTag: Tag?) { // filter the tag list on the ones that contain the provided task
        self.task = task
        _tags = FetchRequest(
            entity: Tag.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Tag.id, ascending: true)
            ],
            predicate: NSPredicate(format: "tasks CONTAINS %@", task ?? Task())
        )
        
        self.defaultFocus = defaultFocus
        self.defaultWaitingFor = defaultWaitingFor
        self.defaultProject = defaultProject
        self.defaultTag = defaultTag
    }
    
    
    
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    @State private var runOnAppear = true // to prevent the onAppear from running once more when I exit the project of tag picker (or when I switch apps?)
    
    @State private var name = ""
    @State private var note = ""
//    @State private var list: Int16 = 0
    @State private var focus = false
    @State private var singleAction = false
    
    @State private var date = Date()
    @State private var dateActive = false
    @State private var reminderActive = false
    @State private var hideUntilDate = false
    @State private var waitingFor = false
    @State private var someday = false
    @State private var recurring = false
    @State private var recurrence: Int16 = 1
    @State private var recurrenceType = "days"
    @State private var nextReviewDate = Date()
    
    @State private var link = ""
    
    @State private var selectedProject: Project?
    @State private var selectedTags: [Tag?] = []
    
    @FocusState private var focusName: Bool
    @FocusState private var focusRecurrence: Bool
    
    @State private var showDeleteAlert = false
    
    // Define lists:
    let lists = [(Int16(0), "Inbox"), (Int16(2), "Next"), (Int16(3), "Someday")]
    
    var body: some View {
        NavigationStack {
            Form {
                Group {
                    TextField("", text: $name, axis: .vertical)
                        .focused($focusName)
                        .onAppear {
                            if runOnAppear && task != nil { // if this is not a new task, load its attributes
                                name = task?.name ?? ""
                                note = task?.note ?? ""
                                dateActive = task?.dateactive == true
                                reminderActive = task?.reminderactive == true
                                date = task?.date ?? Date()
                                hideUntilDate = task?.hideuntildate == true
                                waitingFor = task?.waitingfor == true
                                someday = task?.someday == true
//                                list = task?.list ?? 0
                                focus = task?.focus == true
                                recurring = task?.recurring == true
                                if task?.recurrence != 0 { // so that it doesn't get set to 0 instead of 1 to begin with
                                    recurrence = task?.recurrence ?? 1
                                }
                                recurrenceType = task?.recurrencetype ?? "days"
                                link = task?.link ?? ""
                                nextReviewDate = task?.nextreviewdate ?? Date()
                                selectedProject = task?.project
                                selectedTags = task?.tags?.allObjects as! [Tag]
                                
                                runOnAppear = false // prevent the onAppear from running again 
                            }
                            else if runOnAppear && task == nil { // else if this is a new task, set the default values
                                
                                // First check that there is at least one project, otherwise create the single actions project:
                                if projects.count == 0 { // if there are no projects, created the single action project
                                    let singleActionsProject = Project(context: viewContext)
                                    singleActionsProject.id = UUID()
                                    singleActionsProject.order = -99999
                                    singleActionsProject.name = "Single actions"
                                    singleActionsProject.note = "For tasks that require only one action to complete"
                                    singleActionsProject.icon = "list.bullet"
                                    singleActionsProject.color = "blue"
                                    singleActionsProject.singleactions = true // to protect it from deletion, and make sure it stays on the top of the list
                                    singleActionsProject.createddate = Date()
                                    PersistenceController.shared.save()
                                }
                                
                                focus = defaultFocus
                                waitingFor = defaultWaitingFor
                                if defaultProject != nil {
                                    selectedProject = defaultProject
                                }
                                if defaultTag != nil {
                                    selectedTags = [defaultTag]
                                }
                                
                                focusName = true // focus on the name of the task                                
                                
                                runOnAppear = false // prevent the onAppear from running again, so that the focus doesn't keep returning to the task name
                            }
                        }
                        .onChange(of: name) { _ in
                            // If I press enter:
                            if name.contains("\n") { // if a newline is found
                                print("New line found. Closing the keyboard")
                                name = name.replacingOccurrences(of: "\n", with: "") // replace it with nothing
                                focusName = false // close the keyboard
                            }
                        }
                    
                    HStack {
                        
                        TextField("Notes", text: $note, axis: .vertical)
                            .font(.footnote)
                        
                        if task != nil && note != task?.note ?? "" { // if this is not a new task, and the note has changed, show a button to save it
                            Button {
                                task?.note = note
                                PersistenceController.shared.save()
                            } label: {
                                Text("Save")
                            }
                        }
                    }
                    
//                    Picker("List", selection: $list) {
//                        ForEach(lists, id: \.self.0) {
//                            Text($0.1)
//                                .tag($0.0)
//                        }
//                    }
//                    .onChange(of: list) { _ in
//                        if list == 3 {
//                            focus = false // deactivate focus if I set the list to Someday
//                        }
//                    }
                    
                    Toggle("Focus", isOn: $focus)
                        .onChange(of: focus) { _ in
                            if focus {
                                someday = false // if I focus on a Someday task, move it to Next
                            }
                        }
                    
                    
                    if task == nil { // if this is a new task
                        
                        HStack {
                            Button() {
                                saveTask(toTop: true)
                            } label: {
                                Label("Add to top", systemImage: "arrow.up.circle.fill")
                            }
                            
                            Button() {
                                saveTask(toTop: false)
                            } label: {
                                Label("Add to bottom", systemImage: "arrow.down.circle.fill")
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    else if taskHasChanged() { // if the task is not new, and has been modified, show a save changes button
                        
                        Button() {
                            saveTask(toTop: true)
                        } label: {
                            Label("Save changes", systemImage: "externaldrive.fill")
                        }
                    }
                }
                
                
                Group {
                    
                    if selectedProject == nil { // if I haven't selected a project, allow me to set it to the Single action project
                        Toggle("Single action", isOn: $singleAction)
                            .onChange(of: singleAction) { _ in
                                if singleAction && projects.filter({$0.singleactions}).count == 1 { // if I activate Single action, set the project to the single action project, if it exists
                                    selectedProject = projects.filter({$0.singleactions})[0] // assign the single action project to the task
                                }
                                else {
                                    selectedProject = nil
                                }
                            }
                    }
                
                    NavigationLink {
                        ProjectPickerView(selectedProject: $selectedProject, tasks: [])
                        //                        ProjectPickerView(tasks: [task!], save: false)
                    } label: {
                        if selectedProject == nil {
                            Text("Project")
                        }
                        else {
                            HStack {
                                Text(selectedProject?.name ?? "")
                                
                                Spacer()
                                
                                Image(systemName: selectedProject?.icon ?? "book.fill")
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(Color(selectedProject?.color ?? "black"))
                                    .padding(.leading, 3)
                            }
//                            .onTapGesture {
//                                selectedProject = nil // unselect the project
//                            }
                        }
                    }
                    
                    
                    NavigationLink {
                        TagsPickerView(selectedTags: $selectedTags, tasks: [])
                    } label: {
                        VStack {
//                            if task == nil || task?.tags?.count == 0 {
                            if selectedTags.count == 0 {
                                Text("Tags")
                            }
                            else {
                                HStack {
                                    ForEach(selectedTags as! [Tag]) { tag in
                                        Text(tag.name ?? "")
                                    }
                                }
                            }
                        }
                    }
                    
                    Toggle("Waiting for", isOn: $waitingFor)
                    
                    Toggle("Someday", isOn: $someday)
                        .onChange(of: someday) { _ in
                            if someday {
                                focus = false // if I move a task to someday, remove focus from it
                            }
                        }
                    
                }
                
                HStack {
                    Toggle("Date", isOn: $dateActive)
                        .onChange(of: dateActive) { _ in // if I deactivate the date, deactivate the reminder too
                            if !dateActive {
                                reminderActive = false
                            }
                            else {
                                date = Date() // when I activate the date, default to today, to avoid that it shows a date in the past
                            }
                        }
                    Toggle("Reminder", isOn: $reminderActive)
                        .onChange(of: reminderActive) { _ in // if I activate the reminder, activate the date too
                            if reminderActive {
                                dateActive = true
                            }
                            else {
                                task?.cancelNotification()
                            }
                        }
                }
                if dateActive {
                    
                    DatePicker("", selection: $date, displayedComponents: reminderActive ? [.date, .hourAndMinute] : .date)
                    
                    Toggle("Recurring", isOn: $recurring)
                    
                    if recurring {
                        HStack {
                            Text("every")
                            
                            TextField("", value: $recurrence, formatter: NumberFormatter())
                                .focused($focusRecurrence)
                                .frame(width: 22)
                                .keyboardType(.numberPad)
                                .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                                    if let textField = obj.object as? UITextField {
                                        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                                    }
                                } // select all contents of a TextField when I tap on it -> valid for all TextFields, not just this one! But only after this has been displayed once
                            if(focusRecurrence) { // if the numpad is shown, show a button to dismiss it
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                                    .onTapGesture {
                                        let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                                        impactMed.impactOccurred() // haptic feedback
                                        focusRecurrence = false
                                    }
                            }
                            
                            Picker("", selection: $recurrenceType) {
                                Text("days")
                                    .tag("days")
                                Text("weeks")
                                    .tag("weeks")
                                Text("months")
                                    .tag("months")
                                Text("years")
                                    .tag("years")
                            }
                        }
                    }
                    
                    Toggle("Hide until date", isOn: $hideUntilDate)
                }
                
                HStack {
                    
                    TextField("Link", text: $link)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                    
                    if link != "" {
                        Link(destination: URL(string: link)!) {
                            Image(systemName: "link")
//                                .font(.title)
                        }
                    }
                    
                }
                
                if task != nil { // if this is not a new task
                    
                    HStack {
                        Text("Next review date")
                        DatePicker("", selection: $nextReviewDate, displayedComponents: .date)
                    }
                    
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete task", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showDeleteAlert) {
                        Alert(
                            title: Text("Are you sure you want to delete this task?"),
                            message: Text("This cannot be undone"),
                            primaryButton: .destructive(Text("Delete")) {
                                withAnimation {
                                    viewContext.delete(task!)
                                    PersistenceController.shared.save() // save the changes
                                    dismiss()
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button {
                            dismiss() // dismiss the sheet
                        } label: {
                            Text("Cancel")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveTask(toTop: true)
                    } label: {
                        Text("Save")
                    }
                }
            }
        }
        .interactiveDismissDisabled(taskHasChanged()) // prevent accidental dismissal of the sheet if any value has been modified. I'm only disabling dismiss based on the date if task.date is not nil, otherwise it will always get stuck on new tasks
    }
    
    private func taskHasChanged() -> Bool {
        if task?.name != name ||
            task?.note != note ||
//            task?.list != list ||
            task?.focus != focus ||
            task?.project != selectedProject ||
            task?.tags?.allObjects as! [Tag] != selectedTags ||
            (task?.date != date && task?.date != nil) ||
            task?.dateactive != dateActive ||
            task?.reminderactive != reminderActive ||
            task?.hideuntildate != hideUntilDate ||
            task?.waitingfor != waitingFor ||
            task?.recurring != recurring ||
            task?.recurrence != recurrence ||
            task?.recurrencetype != recurrenceType ||
            task?.link != link ||
            task?.nextreviewdate != nextReviewDate
        {
            return true
        }
        else {
            return false
        }
    }
    
    private func saveTask(toTop: Bool) {
        if task == nil { // if this is a new task, create it and set its attributes
            let task = Task(context: viewContext)
            task.id = UUID()
            task.order = toTop ? (tasks.first?.order ?? 0) - 1 : (tasks.last?.order ?? 0) + 1
            task.name = name
            task.note = note
            task.dateactive = dateActive
            task.reminderactive = reminderActive
            
            // If the date has been modified, cancel the notification if there is one, and create one if there is a reminder time
            if task.date != date {
                task.date = date
                task.cancelNotification()
                if reminderActive {
                    task.createNotification()
                }
            }
            task.hideuntildate = hideUntilDate
            task.waitingfor = waitingFor
            task.someday = someday
//            task.list = list
            task.project = selectedProject // so that the project is cleared if I've cleared it
//            task.tags = NSSet(array: selectedTags.compactMap { $0 as AnyObject })
//            task.tags = selectedTags
            for tag in selectedTags {
                tag?.addToTasks(task)
            }
            task.focus = focus
            task.recurring = recurring
            task.recurrence = recurrence
            task.recurrencetype = recurrenceType
            task.link = link
            task.nextreviewdate = nextReviewDate
            
            task.modifieddate = Date()
        }
        
        else { // else if this is an existing task, update its attributes
            task?.name = name
            task?.note = note
            task?.dateactive = dateActive
            task?.reminderactive = reminderActive
            
            // If the date has been modified, cancel the notification if there is one, and create one if there is a reminder time
            if task?.date != date {
                task?.date = date
                task?.cancelNotification()
                if reminderActive {
                    task?.createNotification()
                }
            }
            task?.hideuntildate = hideUntilDate
            task?.waitingfor = waitingFor
            task?.someday = someday
//            task?.list = list
            task?.project = selectedProject
            task?.tags = NSSet(array: selectedTags.compactMap { $0 as AnyObject })
//            for tag in selectedTags {
//                tag?.addToTasks(task ?? Task())
//            }
            if task?.focus != focus { // if the focus has changed, move the task to the top of the Next list or the bottom of the Focused list, and save the change to the focus
                task?.order = !focus ? (tasks.first?.order ?? 0) - 1 : (tasks.last?.order ?? 0) + 1
                task?.focus = focus
            }
            task?.recurring = recurring
            task?.recurrence = recurrence
            task?.recurrencetype = recurrenceType
            task?.link = link
            task?.nextreviewdate = nextReviewDate
            
            task?.modifieddate = Date()
        }
        
        PersistenceController.shared.save()
        dismiss() // dismiss the sheet
    }
}

//struct TaskDetailsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TaskDetailsView(task: Task())
//    }
//}
