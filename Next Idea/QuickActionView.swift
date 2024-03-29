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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.order, ascending: true)],
        animation: .default)
    private var projects: FetchedResults<Project> // to be able to set the project to the Single actions project
    
    @State private var showProjectPicker = false
    @State private var showTagPicker = false
    @State private var showDatePicker = false
    
    @State private var selectedProject: Project? // so that I can pass a project to the ProjectPickerView
    @State private var selectedTags: [Tag?] = [] // so that I can pass tags to the TagPickerView
    
    var body: some View {
        
        if tasks.filter({$0.selected}).count > 0 { // show icons to move the tasks to other lists if at least one task is selected
            VStack {
                HStack {
                    Button { // Puts the task at the bottom of the Focused list, removes someday, and puts it in the Single actions project if it doesn't have a project:
                        let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                        impactMed.impactOccurred() // haptic feedback
                        for task in tasks.filter({$0.selected}) {
                            task.focus = true
                            task.someday = false
                            task.order = (tasks.filter({!$0.completed}).last?.order ?? 0) + 1
                            if task.project == nil && projects.filter({$0.singleactions}).count == 1 { // if the task has no project, and there is a single actions project, assign the single actions project to the task
                                task.project = projects.filter({$0.singleactions})[0]
                            }
                            task.modifieddate = Date()
                        }
                        PersistenceController.shared.save()
                        deselectAllTasks()
                    } label: {
                        Image(systemName: "scope")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.black)
                            .padding(10)
                    }
                    
                    Button { // Moves the task to the top of Next, and puts it in the Single actions project if it doesn't have a project:
                        let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                        impactMed.impactOccurred() // haptic feedback
                        for task in tasks.filter({$0.selected}) {
                            task.focus = false
                            task.someday = false
                            task.order = (tasks.filter({!$0.completed}).first?.order ?? 0) - 1
                            if task.project == nil && projects.filter({$0.singleactions}).count == 1 { // if the task has no project, and there is a single actions project, assign the single actions project to the task
                                task.project = projects.filter({$0.singleactions})[0]
                            }
                            task.modifieddate = Date()
                        }
                        PersistenceController.shared.save()
                        deselectAllTasks()
                    } label: {
                        Image(systemName: "terminal.fill")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.black)
                            .padding(10)
                    }
                    
                    Button { // Moves the task to the top of Someday, removes focus, and puts it in the Single actions project if it doesn't have a project:
                        let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                        impactMed.impactOccurred() // haptic feedback
                        for task in tasks.filter({$0.selected}) {
                            task.someday = true
                            task.order = (tasks.filter({!$0.completed}).first?.order ?? 0) - 1
                            if task.project == nil && projects.filter({$0.singleactions}).count == 1 { // if the task has no project, and there is a single actions project, assign the single actions project to the task
                                task.project = projects.filter({$0.singleactions})[0]
                            }
                            task.focus = false
                            task.modifieddate = Date()
                        }
                        PersistenceController.shared.save()
                        deselectAllTasks()
                    } label: {
                        Image(systemName: "text.append")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.black)
                            .padding(10)
                    }
                    
                    Button { // sets to waiting for
                        let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                        impactMed.impactOccurred() // haptic feedback
                        for task in tasks.filter({$0.selected}) {
                            task.waitingfor = true
                            task.modifieddate = Date()
                        }
                        PersistenceController.shared.save()
                        deselectAllTasks()
                    } label: {
                        Image(systemName: "stopwatch")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.black)
                            .padding(10)
                    }
                    
                }
//                        .padding(.bottom, 120)
                
                // Quick actions to change date project and tag:
                HStack {
                    
                    // Show date picker:
                    Button {
                        let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                        impactMed.impactOccurred() // haptic feedback
                        showDatePicker = true
                    } label: {
                        Image(systemName: "calendar")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.black)
                            .padding(10)
                    }
                    
                    Button {
                        let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                        impactMed.impactOccurred() // haptic feedback
                        if projects.filter({$0.singleactions}).count == 1 { // if there is a Single actions project
                            for task in tasks.filter({$0.selected}) {
                                task.project = projects.filter({$0.singleactions})[0]
                                task.modifieddate = Date()
                            }
                            PersistenceController.shared.save()
                        }
                        deselectAllTasks()
                    } label: {
                        Image(systemName: "1.circle.fill")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.black)
                            .padding(10)
                    }
                    
                    Button {
                        let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                        impactMed.impactOccurred() // haptic feedback
                        showProjectPicker = true
                    } label: {
                        Image(systemName: "book.fill")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.black)
                            .padding(10)
                    }
                    
                    Button {
                        let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                        impactMed.impactOccurred() // haptic feedback
                        showTagPicker = true
                    } label: {
                        Image(systemName: "tag")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.black)
                            .padding(10)
                    }
                    .sheet(isPresented: $showTagPicker) {
                        TagsPickerView(selectedTags: $selectedTags, tasks: tasks.filter({$0.selected}))
                    }
                    .sheet(isPresented: $showProjectPicker) {
                        ProjectPickerView(selectedProject: $selectedProject, tasks: tasks.filter({$0.selected}))
                    }
                    .sheet(isPresented: $showDatePicker) {
                        DatePickerView(tasks: tasks.filter({$0.selected}))
                            .presentationDetents([.height(500)])
                    }
                    
                    Button {
                        let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                        impactMed.impactOccurred() // haptic feedback
                        deselectAllTasks()
                    } label: {
                        Image(systemName: "pip.remove")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.black)
                            .padding(10)
                    }
                }
//                        .padding(.bottom, 60)
            }
            .frame(height: 100)
//            .background(.secondary)
            .offset(y: -10)
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
