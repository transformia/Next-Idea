//
//  ProjectView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct ProjectView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task> // to be able to count the tasks in each project
    
    let project: Project
    
//    @State private var name = ""
    
    @State private var showProjectDetails = false
    
    @FocusState private var focused: Bool
    
    var body: some View {
        HStack {
//            TextField("", text: $name, axis: .vertical)
//                .focused($focused)
            Text(project.name ?? "")
            Spacer()
            Text("\(countTasks(project: project))")
            Image(systemName: project.icon ?? "book.fill")
                .resizable()
                .frame(width: 18, height: 18)
                .foregroundColor(Color(project.color ?? "black"))
//                .onAppear {
//                    name = project.name ?? ""
//                    if name == "" {
//                        focused = true // focus on the project when it is created
//                    }
//                }
//                .onChange(of: name) { _ in
//                    project.name = name // save the changes
//                    PersistenceController.shared.save()
//
//                    // If I press enter:
//                    if name.contains("\n") { // if a newline is found
//                        name = name.replacingOccurrences(of: "\n", with: "") // replace it with nothing
//                        focused = false // close the keyboard
//                        project.name = name // save the changes
//                        PersistenceController.shared.save()
//                    }
//                }
            
//            if focused {
//                Label("Project details", systemImage: "info.circle")
//                    .labelStyle(.iconOnly)
//                    .foregroundColor(.cyan)
//                    .onTapGesture {
//                        focused = false
//                        showProjectDetails = true
//                    }
//            }
        }
        .swipeActions(edge: .trailing) {
            // Edit the project details:
            Button {
                showProjectDetails = true
            } label: {
                Label("Details", systemImage: "info.circle")
            }
            .tint(.cyan)
        }
        .sheet(isPresented: $showProjectDetails) {
            ProjectDetailsView(project: project)
        }
    }
    
    private func countTasks(project: Project) -> Int {
        return tasks.filter({$0.project == project && !$0.completed}).count
    }
}

struct ProjectView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectView(project: Project())
    }
}
