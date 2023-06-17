//
//  ProjectTaskView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct ProjectTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \Task.list, ascending: true), NSSortDescriptor(keyPath: \Task.order, ascending: true)],
//        animation: .default) // tasks sorted by order, then by list
//    private var tasks: FetchedResults<Task>
    
    @FetchRequest private var tasks: FetchedResults<Task>
    
    @EnvironmentObject var tab: Tab
//    @FetchRequest var tasks: FetchedResults<Task>
    
    let project: Project
    
    init(project: Project) { // filter the task list on the ones linked to the provided project
        self.project = project
        _tasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Task.list, ascending: true),
                NSSortDescriptor(keyPath: \Task.order, ascending: true) // tasks sorted by order, then by list
            ],
            predicate: NSPredicate(format: "project == %@", project)
        )
    }
    
    @State private var showSearchView = false
    
    var body: some View {
        VStack { // Contains project name, ZStack and Quick action buttons
            Text(project.name ?? "")
                .font(.headline)
            
            ZStack(alignment: .bottom) { // Contains task list and Add task buttons
                
                
                List {
                    ForEach(tasks.filter({!$0.completed})) { task in
                        HStack {
                            TaskView(task: task)
                            
                            Spacer()
                            
                            // Show the list's icon:
                            switch(task.list) {
                            case 0:
                                Image(systemName: "tray")
                            case 1:
                                Image(systemName: "scope")
                            case 2:
                                Image(systemName: "terminal.fill")
                            case 3:
                                Image(systemName: "text.append")
                            default:
                                Image(systemName: "tray")
                            }
                            
                            // If at least one task is selected, show the selection circle next to each task:
//                            if tasks.filter({$0.selected}).count > 0 {
//                                Image(systemName: task.selected ? "circle.fill" : "circle")
//                                    .foregroundColor(task.selected ? .teal : nil)
//                                    .onTapGesture {
//                                        let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
//                                        impactMed.impactOccurred() // haptic feedback
//
//                                        task.selected.toggle()
//                                        PersistenceController.shared.save()
//                                    }
//                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                
//                if tasks.filter({!$0.completed && $0.ticked}).count > 0 { // if there are ticked tasks displayed, show a button to mark them as complete, and therefore hide them
//                    Button {
//                        for task in tasks {
//                            if task.ticked {
//                                task.completed = true
//                            }
//                        }
//                        PersistenceController.shared.save()
//                    } label: {
//                        Text("Clear completed tasks")
//                    }
//                    .padding(.bottom, 60)
//                }
                
                // Add task buttons:
                AddTaskButtonsView(list: 2, project: project, tag: nil) // add the task to the "Next" list
            }
            
            QuickActionView()
            
        }
        .sheet(isPresented: $showSearchView) {
            SearchView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if tasks.filter({$0.selected}).count > 0 {
                        Button {
                            deselectAllTasks()
                        } label: {
                            Label("", systemImage: "pip.remove")
                        }
                    }
                    
                    Button {
                        showSearchView.toggle()
                    } label: {
                        Label("", systemImage: "magnifyingglass")
                    }
                }
            }
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

struct ProjectTaskView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectTaskView(project: Project())
    }
}
