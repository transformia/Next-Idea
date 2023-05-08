//
//  DatePickerView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-07.
//

import SwiftUI

struct DatePickerView: View {
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    let tasks: [Task]
    
    @State private var dateActive = true
    @State private var reminderActive = false
    @State private var date = Date()
    @State private var hideUntilDate = false
    @State private var recurring = false
    @State private var recurrence: Int16 = 1
    @State private var recurrenceType = "days"
    
    @FocusState private var focusRecurrence: Bool
    
    var body: some View {
        NavigationStack {
            Form {
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
                
                
                /*
                 //            if showDatePicker || showDateTimePicker {
                 Toggle("Hide until date", isOn: $hideUntilDate)
                 .frame(width: 200, height: 40)
                 .padding(.bottom, 170)
                 //            }
                 
                 Button { // remove the date and reminder, and cancel the notification
                 for task in tasks.filter({$0.selected}) {
                 task.dateactive = false
                 task.reminderactive = false
                 task.modifieddate = Date()
                 
                 task.cancelNotification() // cancel the notification if there is one
                 
                 PersistenceController.shared.save()
                 }
                 dismiss()
                 } label: {
                 Image(systemName: "xmark")
                 .foregroundColor(.red)
                 .frame(width: 20, height: 20)
                 }
                 
                 DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                 .frame(width: 200)
                 
                 Button {  // save the date and time, cancel the reminder if there is one and create a new one, and save the hide toggle value
                 for task in tasks.filter({$0.selected}) {
                 task.dateactive = true
                 task.reminderactive = true
                 task.date = date
                 task.hideuntildate = hideUntilDate
                 task.modifieddate = Date()
                 
                 task.cancelNotification()
                 task.createNotification()
                 
                 PersistenceController.shared.save()
                 }
                 dismiss()
                 } label: {
                 Image(systemName: "checkmark")
                 .frame(width: 20, height: 20)
                 }
                 
                 */
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
                        for task in tasks {
                            task.dateactive = dateActive
                            task.reminderactive = reminderActive
                            
                            // If the date has been modified, save it, cancel the notification if there is one, and create one if there is a reminder time
                            if task.date != date {
                                if dateActive {
                                    task.date = date
                                }
                                else {
                                    task.date = nil
                                }
                                task.cancelNotification()
                                if reminderActive {
                                    task.createNotification()
                                }
                            }
                            task.hideuntildate = hideUntilDate
                            task.recurring = recurring
                            task.recurrence = recurrence
                            task.recurrencetype = recurrenceType
                            
                            task.modifieddate = Date()
                        }
                        PersistenceController.shared.save()
                        dismiss() // dismiss the sheet
                    } label: {
                        Text("Save")
                    }
                }
            }
        }
    }
}

struct DatePickerView_Previews: PreviewProvider {
    static var previews: some View {
        DatePickerView(tasks: [])
    }
}
