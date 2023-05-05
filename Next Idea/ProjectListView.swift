//
//  ProjectListView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct ProjectListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.order, ascending: true)],
        animation: .default)
    private var projects: FetchedResults<Project>
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            List {
                ForEach(projects.filter({!$0.completed})) { project in
                    NavigationLink {
                        ProjectTaskView(project: project)
                    } label: {
                        ProjectView(project: project)
                    }
                }
                .onMove(perform: moveItem)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        EditButton()
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            
            HStack {
                addProjectButton
            }
        }
    }
    
    private func moveItem(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        
        // If the item is moving down:
        if itemToMove < destination {
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = projects.filter({!$0.completed})[itemToMove].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                projects.filter({!$0.completed})[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            projects.filter({!$0.completed})[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = projects.filter({!$0.completed})[destination].order + 1
            let newOrder = projects.filter({!$0.completed})[destination].order
            while startIndex <= endIndex {
                projects.filter({!$0.completed})[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            projects.filter({!$0.completed})[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
    
    var addProjectButton: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
            impactMed.impactOccurred() // haptic feedback
            // Create a new project at the top:
            let project = Project(context: viewContext)
            project.id = UUID()
            project.order = (projects.first?.order ?? 0) - 1
            project.name = ""
            project.createddate = Date()
            PersistenceController.shared.save()
        } label: {
            Image(systemName: "plus")
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

struct ProjectListView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectListView()
    }
}
