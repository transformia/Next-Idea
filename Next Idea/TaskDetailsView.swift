//
//  TaskDetailsView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-04.
//

import SwiftUI

struct TaskDetailsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let task: Task
    
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
    
    @State private var selectedProject: Project?
    
    @FocusState private var focused: Bool
    @FocusState private var focusRecurrence: Bool
    
    @State private var showDeleteAlert = false
    
    // Define lists:
    let lists = [(Int16(0), "Inbox"), (Int16(1), "Now"), (Int16(2), "Next"), (Int16(3), "Someday")]
    
    var body: some View {
        NavigationView {
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
                        recurrence = task.recurrence
                        recurrenceType = task.recurrencetype ?? "days"
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
                    ProjectPicker(tasks: [task])
                } label: {
                    if selectedProject == nil {
                        Text("Project")
                    }
                    else {
                        Text("\(task.project?.name ?? "")")
                    }
                }
                
                Toggle("Waiting for", isOn: $waitingFor)
                
                HStack {
                    Toggle("Date", isOn: $dateActive)
                    Toggle("Reminder", isOn: $reminderActive)
                        .disabled(!dateActive)
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
                        task.date = date
                        task.hideuntildate = hideUntilDate
                        task.waitingfor = waitingFor
                        task.list = list
                        task.recurring = recurring
                        task.recurrence = recurrence
                        task.recurrencetype = recurrenceType
                        task.modifieddate = Date()
                        PersistenceController.shared.save()
                        dismiss() // dismiss the sheet
                    } label: {
                        Text("Save")
                    }
                }
            }
        }
        .interactiveDismissDisabled(task.name != name || task.note != note || task.dateactive != dateActive || task.reminderactive != reminderActive || task.date != date || task.hideuntildate != hideUntilDate || task.waitingfor != waitingFor || task.list != list || task.recurring != recurring || task.recurrence != recurrence || task.recurrencetype != recurrenceType) // prevent accidental dismissal of the sheet if any value has been modified (except the project, because that is modified in the project picker, but not saved -> could be an issue)
    }
}

//struct TaskDetailsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TaskDetailsView(task: Task())
//    }
//}
