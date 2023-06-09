//
//  TaskDetailsView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-04.
//

import SwiftUI

struct TaskDetailsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.id, ascending: true)],
//        animation: .default)
//    private var tags: FetchedResults<Tag> // to be able to display the tags that have been selected
    
    @FetchRequest private var tags: FetchedResults<Tag>
    
    let task: Task
    
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
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    @State private var name = ""
    @State private var note = ""
    @State private var list: Int16 = 0
    @State private var date = Date()
    
    @State private var dateActive = false
    @State private var reminderActive = false
    @State private var hideUntilDate = false
    @State private var waitingFor = false
    @State private var recurring = false
    @State private var recurrence: Int16 = 1
    @State private var recurrenceType = "days"
    
    @State private var link = ""
    
    @State private var selectedProject: Project?
    
    @FocusState private var focused: Bool
    @FocusState private var focusRecurrence: Bool
    
    @State private var showDeleteAlert = false
    
    // Define lists:
    let lists = [(Int16(0), "Inbox"), (Int16(1), "Now"), (Int16(2), "Next"), (Int16(3), "Someday")]
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("", text: $name, axis: .vertical)
                    .focused($focused)
                    .onAppear {
                        name = task.name ?? ""
                        note = task.note ?? ""
                        dateActive = task.dateactive
                        reminderActive = task.reminderactive
                        date = task.date ?? Date()
                        hideUntilDate = task.hideuntildate
                        waitingFor = task.waitingfor
                        list = task.list
                        recurring = task.recurring
                        if task.recurrence != 0 { // so that it doesn't get set to 0 instead of 1 to begin with
                            recurrence = task.recurrence
                        }
                        recurrenceType = task.recurrencetype ?? "days"
                        link = task.link ?? ""
                        selectedProject = task.project
                    }
                    .onChange(of: name) { _ in
                        // If I press enter:
                        if name.contains("\n") { // if a newline is found
                            name = name.replacingOccurrences(of: "\n", with: "") // replace it with nothing
                            focused = false // close the keyboard
                        }
                    }
                
                TextField("Notes", text: $note, axis: .vertical)
                    .font(.footnote)
                
                Picker("List", selection: $list) {
                    ForEach(lists, id: \.self.0) {
                        Text($0.1)
                            .tag($0.0)
                    }
                }
                
                NavigationLink {
                    ProjectPickerView(tasks: [task])
                } label: {
                    if selectedProject == nil {
                        Text("Project")
                    }
                    else {
                        Text("\(task.project?.name ?? "")")
                    }
                }
                
                NavigationLink {
                    TagsPickerView(tasks: [task])
                } label: {
                    VStack {
                        if task.tags?.count == 0 {
                            Text("Tags")
                        }
                        else {
                            HStack {
                                ForEach(tags) { tag in
                                    Text(tag.name ?? "")
                                }
                            }
                        }
                    }
                }
                
                Toggle("Waiting for", isOn: $waitingFor)
                
                HStack {
                    Toggle("Date", isOn: $dateActive)
                        .onChange(of: dateActive) { _ in // if I deactivate the date, deactivate the reminder too
                            if !dateActive {
                                reminderActive = false
                            }
                        }
                    Toggle("Reminder", isOn: $reminderActive)
                        .onChange(of: reminderActive) { _ in // if I activate the reminder, activate the date too
                            if reminderActive {
                                dateActive = true
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
                
                TextField("Link", text: $link)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                
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
                                viewContext.delete(task)
                                PersistenceController.shared.save() // save the changes
                                dismiss()
                            }
                        },
                        secondaryButton: .cancel()
                    )
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
                        task.list = list
                        task.recurring = recurring
                        task.recurrence = recurrence
                        task.recurrencetype = recurrenceType
                        task.link = link
                        
                        task.modifieddate = Date()
                        PersistenceController.shared.save()
                        dismiss() // dismiss the sheet
                    } label: {
                        Text("Save")
                    }
                }
            }
        }
        .interactiveDismissDisabled(task.name != name || task.note != note || task.dateactive != dateActive || task.reminderactive != reminderActive || (task.date != date && task.date != nil) || task.hideuntildate != hideUntilDate || task.waitingfor != waitingFor || task.list != list || task.recurring != recurring || task.recurrence != recurrence || task.recurrencetype != recurrenceType) // prevent accidental dismissal of the sheet if any value has been modified (except the project, because that is modified in the project picker, but not saved -> could be an issue). I'm only disabling dismiss based on the date if task.date is not nil, otherwise it will always get stuck on new tasks
    }
}

//struct TaskDetailsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TaskDetailsView(task: Task())
//    }
//}
