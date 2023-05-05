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
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default) // tasks sorted by order, then by list
    private var tasks: FetchedResults<Task>
    
    let project: Project
    
    var body: some View {
        VStack {
            Text(project.name ?? "")
                .font(.headline)
            List {
                ForEach(tasks.filter({$0.project == project && !$0.completed})) { task in // filter out completed tasks, and filter on the provided project
                    TaskView(task: task)
                }
            }
        }
    }
}

struct ProjectTaskView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectTaskView(project: Project())
    }
}
