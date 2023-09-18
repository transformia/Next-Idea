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
    
    @State private var searchText = ""
    
    @FocusState private var focused: Bool
    
    @Binding var selectedProject: Project? // for returning the selected project to the TaskDetailsView
    let tasks: [Task] // for updating one or several tasks using a quick action, or using the navigation link on a task without a project
    
//    let save: Bool // determines whether the change should be saved right away or not. It should be saved when doing a quick action, but not when editing a task in TaskDetailsView
    
    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
                .disableAutocorrection(true)
                .padding(20)
                .focused($focused)
                .onAppear {
                    focused = true
                }
            
            // If I have entered a search text, and there is no match, show a button to create a new project:
            if projects.filter({$0.name?.range(of: searchText, options: .caseInsensitive) != nil}).count == 0 && searchText != "" {
                Label("Create project: \(searchText)", systemImage: "book")
                    .onTapGesture {
//                        if tasks != [] { // if I have called this view with at least one task
                        let project = Project(context: viewContext)
                        project.id = UUID()
                        project.name = searchText
                        project.order = (projects.last?.order ?? 0) + 1
                        project.singleactions = false
                        
                        if tasks != [] { // if I have called this view with at least one task, update the tasks, deselect all tasks, and save
                            for task in tasks {
                                project.addToTasks(task) // note: the function addToTasks was created automatically by Core Data
                                print("Adding project \(project.name ?? "") to task \(task.name ?? "")")
                            }
                            deselectAllTasks()
                            PersistenceController.shared.save()
                        }
                        else { // else if I have called this from the TaskDetailsView, update the selected project so that I can save it in TaskDetailsView
                            selectedProject = project
//                            print("Selected project \(selectedProject?.name ?? "")")
                        }
                        
//                            for task in tasks {
//                                project.addToTasks(task) // note: the function addToTasks was created automatically by Core Data
//                                print("Adding project \(project.name ?? "") to task \(task.name ?? "")")
//                            }
//                            if save {
//                                PersistenceController.shared.save()
//                            }
//                        }
                    }
            }
            
            // If the project name contains the value of the search text, or the search text is blank, display the project:
            List {
                ForEach(projects.filter({!$0.completed})) { project in
                    if(project.name?.range(of: searchText, options: .caseInsensitive) != nil || searchText == "")  {
                        HStack {
                            Text(project.name ?? "")
                            
                            Spacer()
                            
                            Image(systemName: project.icon ?? "book.fill")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundColor(Color(project.color ?? "black"))
                                .padding(.leading, 3)
                        }
                            .onTapGesture {
                                if tasks != [] { // if I have called this view with at least one task, update the tasks, deselect all tasks, and save
                                    for task in tasks {
                                        project.addToTasks(task) // note: the function addToTasks was created automatically by Core Data
                                        print("Adding project \(project.name ?? "") to task \(task.name ?? "")")
                                    }
                                    deselectAllTasks()
                                    PersistenceController.shared.save()
                                }
                                else { // else if I have called this from the TaskDetailsView, update the selected project so that I can save it in
                                    selectedProject = project
                                }
//                                print("Selected project \(selectedProject?.name ?? "")")
//                                for task in tasks {
//                                    project.addToTasks(task)
//                                    task.modifieddate = Date()
//                                }
//                                if save {
//                                    PersistenceController.shared.save()
//                                }
                                dismiss()
                            }
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8)) // reduce padding of the list items
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

//struct ProjectPickerView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProjectPickerView(tasks: [], save: false)
//    }
//}
