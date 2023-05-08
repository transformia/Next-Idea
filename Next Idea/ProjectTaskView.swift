//
//  ProjectTaskView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct ProjectTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.list, ascending: true), NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default) // tasks sorted by order, then by list
    private var tasks: FetchedResults<Task>
    
    let project: Project
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Text(project.name ?? "")
                    .font(.headline)
                List {
                    ForEach(tasks.filter({$0.project == project && !$0.completed})) { task in // filter out completed tasks, and filter on the provided project
                        HStack {
                            
                            TaskView(task: task)
                            
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
            }
            
            // Add task buttons:
            HStack {
                addTaskTopButton
                addTaskBottomButton
            }
        }
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
