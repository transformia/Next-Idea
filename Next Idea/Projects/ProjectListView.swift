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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task> // to be able to count the tasks to be reviewed
    
    @EnvironmentObject var weeklyReview: WeeklyReview
    
    @State private var showProjectDetailsView = false
    @State private var showSettingsView = false
    @State private var showSearchView = false
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            List {
                
                // The single actions project:
                ForEach(projects.filter({$0.singleactions})) { project in
                    NavigationLink {
                        ProjectTaskView(project: project)
                    } label: {
                        ProjectView(project: project)
                    }
                }
                
                // The other projects:
                ForEach(projects.filter({!$0.singleactions && !$0.completed})) { project in
                    NavigationLink {
                        ProjectTaskView(project: project)
                    } label: {
                        ProjectView(project: project)
                    }
                }
                .onMove(perform: moveItem)
                
                if projects.filter({$0.completed}).count > 0 {
                    Section("Completed projects") {
                        ForEach(projects.filter({$0.completed})) { project in
                            ProjectView(project: project)
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8)) // reduce padding of the list items
            .listStyle(SidebarListStyle()) // so that the sections are expandable and collapsible. Could instead use PlainListStyle, but with DisclosureGroups instead of Sections...
//            .listStyle(PlainListStyle())
            .toolbar {
                
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button {
                            showSettingsView = true
                        } label: {
                            Label("", systemImage: "gear")
                        }
                        
                        Button {
                            weeklyReview.active.toggle()
                        } label: {
                            HStack {
                                if weeklyReview.active {
                                    Label("", systemImage: "figure.yoga")
                                }
                                else {
                                    Label("", systemImage: "figure.mind.and.body")
                                }
                                Text("\(countTasksToBeReviewed())")
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        
                        addProjectButton
                        
                        Button {
                            showSearchView.toggle()
                        } label: {
                            Label("", systemImage: "magnifyingglass")
                        }
                        
                        EditButton()
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            
            AddTaskButtonsView(defaultFocus: false, defaultWaitingFor: false, defaultProject: nil, defaultTag: nil)
//            HStack {
//                addProjectButton
//            }
        }
        .sheet(isPresented: $showProjectDetailsView) {
            ProjectDetailsView(project: nil)
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
        }
        .sheet(isPresented: $showSearchView) {
            SearchView()
        }
    }
    
    private func moveItem(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        
        // If the item is moving down:
        if itemToMove < destination {
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = projects.filter({!$0.singleactions && !$0.completed})[itemToMove].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                projects.filter({!$0.singleactions && !$0.completed})[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            projects.filter({!$0.singleactions && !$0.completed})[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = projects.filter({!$0.singleactions && !$0.completed})[destination].order + 1
            let newOrder = projects.filter({!$0.singleactions && !$0.completed})[destination].order
            while startIndex <= endIndex {
                projects.filter({!$0.singleactions && !$0.completed})[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            projects.filter({!$0.singleactions && !$0.completed})[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
    
    private func countTasksToBeReviewed() -> Int {
        return tasks.filter({!$0.completed && Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date())}).count
    }
    
    var addProjectButton: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
            impactMed.impactOccurred() // haptic feedback
            // Open the project details view:
            showProjectDetailsView = true
//            // Create a new project at the top:
//            let project = Project(context: viewContext)
//            project.id = UUID()
//            project.order = (projects.first?.order ?? 0) - 1
//            project.name = ""
//            project.displayoption = "All"
//            project.createddate = Date()
//            PersistenceController.shared.save()
        } label: {
            Image(systemName: "plus")
//            Image(systemName: "plus")
//                .resizable()
//                .frame(width: 20, height: 20)
//                .foregroundColor(.white)
//                .padding(10)
//                .background(.blue)
//                .clipShape(Circle())
        }
//        .padding(.bottom, 8)
    }
}

struct ProjectListView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectListView()
    }
}
