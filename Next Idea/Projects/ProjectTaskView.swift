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
    
//    @ObservedObjectvar selectedProject: Project
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
    
    var body: some View {
        VStack { // Contains project name, ZStack and Quick action buttons
            Text(project.name ?? "")
                .font(.headline)
            
            ZStack(alignment: .bottom) { // Contains task list, Clear completed tasks button, and Add task buttons
                
                
                List {
//                    ForEach(tasks.filter({$0.project == project && !$0.completed})) { task in // filter out completed tasks, and filter on the provided project
                    ForEach(tasks.filter({!$0.completed})) { task in
                        HStack {
                            
                            if tasks.filter({$0.selected}).count > 0 {
                                Image(systemName: task.selected ? "circle.fill" : "circle")
                                    .foregroundColor(task.selected ? .teal : nil)
                                    .onTapGesture {
                                        let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
                                        impactMed.impactOccurred() // haptic feedback
                                        
                                        task.selected.toggle()
                                        PersistenceController.shared.save()
                                    }
                            }
                            
                            TaskView(task: task)
                            
                            Spacer()
                            
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
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
//                if tasks.filter({$0.project == project && !$0.completed && $0.ticked}).count > 0 { // if there are ticked tasks displayed, show a button to mark them as complete, and therefore hide them
                if tasks.filter({!$0.completed && $0.ticked}).count > 0 { // if there are ticked tasks displayed, show a button to mark them as complete, and therefore hide them
                    Button {
                        for task in tasks {
                            if task.ticked {
                                task.completed = true
                            }
                        }
                        PersistenceController.shared.save()
                    } label: {
                        Text("Clear completed tasks")
                    }
                    .padding(.bottom, 60)
                }
                
                // Add task buttons:
                HStack {
                    addTaskTopButton
                    addTaskBottomButton
                }
            }
            
            QuickActionView()
            
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
    
    var addTaskTopButton: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
            impactMed.impactOccurred() // haptic feedback
            // Create a new task:
            let task = Task(context: viewContext)
            task.id = UUID()
            task.order = (tasks.filter({$0.list == 2}).first?.order ?? 0) - 1 // set the order to the order of the first item in the default list, minus one
            task.list = 2 // Next list by default
            task.name = ""
            task.project = project
            task.createddate = Date()
            PersistenceController.shared.save()
        } label: {
            Image(systemName: "arrow.up")
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(.white)
                .padding(10)
                .background(.green)
                .clipShape(Circle())
        }
        .padding(.bottom, 8)
    }
    
    var addTaskBottomButton: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
            impactMed.impactOccurred() // haptic feedback
            // Create a new task:
            let task = Task(context: viewContext)
            task.id = UUID()
            task.order = (tasks.filter({$0.list == 2}).last?.order ?? 0) + 1  // set the order to the order of the last item in the default list, plus one
            task.list = 2 // Next list by default
            task.name = ""
            task.project = project
            task.createddate = Date()
            PersistenceController.shared.save()
        } label: {
            Image(systemName: "arrow.down")
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(.white)
                .padding(10)
                .background(.green)
                .clipShape(Circle())
        }
        .padding(.bottom, 8)
    }
}

struct ProjectTaskView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectTaskView(project: Project())
    }
}
