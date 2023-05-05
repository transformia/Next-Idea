//
//  ProjectPicker.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct ProjectPicker: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.order, ascending: true)],
        animation: .default)
    private var projects: FetchedResults<Project>
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    let tasks: [Task]
    
    var body: some View {
        List {
            ForEach(projects.filter({!$0.completed})) { project in
                ProjectView(project: project)
                    .onTapGesture {
//                        print("Selecting project \(project.name ?? "") for task \(task.name ?? "")")
                        for task in tasks {
                            task.project = project
                            task.modifieddate = Date()
                            PersistenceController.shared.save()
                        }
                        dismiss()
                    }
            }
        }
    }
}

struct ProjectPicker_Previews: PreviewProvider {
    static var previews: some View {
        ProjectPicker(tasks: [])
    }
}
