//
//  QuickActionView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-08.
//

import SwiftUI

struct QuickActionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task>
    
    @State private var showProjectPicker = false
    @State private var showDatePicker = false
    
    var body: some View {
        
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
    
    private func deselectAllTasks() {
        for task in tasks {
            if task.selected {
                task.selected = false
            }
        }
        PersistenceController.shared.save()
    }
}

struct QuickActionView_Previews: PreviewProvider {
    static var previews: some View {
        QuickActionView()
    }
}