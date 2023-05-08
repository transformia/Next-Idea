//
//  ProjectView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct ProjectView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let project: Project
    
//    @State private var name = ""
    
    @State private var showProjectDetails = false
    
    @FocusState private var focused: Bool
    
    var body: some View {
        HStack {
//            TextField("", text: $name, axis: .vertical)
//                .focused($focused)
            Text(project.name ?? "")
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
}

struct ProjectView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectView(project: Project())
    }
}
