//
//  ProjectPickerView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct ProjectPickerView: View {
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
//                ProjectView(project: project)
                Text(project.name ?? "")
                    .onTapGesture {
                        for task in tasks {
//                            print("Linking task \(task.name ?? "") to project \(project.name ?? "")")
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

struct ProjectPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectPickerView(tasks: [])
    }
}
