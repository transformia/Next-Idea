//
//  TagsPickerView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-08.
//

import SwiftUI

struct TagsPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.order, ascending: true)],
        animation: .default)
    private var tags: FetchedResults<Tag>
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    @State private var searchText = ""
    
    @FocusState private var focused: Bool
    
    @Binding var selectedTags: [Tag?] // for returning the selected tags to the TaskDetailsView
    
    let tasks: [Task] // for updating one or several tasks using a quick action
    
    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
                .disableAutocorrection(true)
                .padding(20)
                .focused($focused)
                .onAppear {
                    focused = true
                }
            
            if tags.filter({$0.name?.range(of: searchText, options: .caseInsensitive) != nil}).count == 0 && searchText != "" { // if I have entered a search text, and there is no match, show a button to create a new tag
                Label("Create tag: \(searchText)", systemImage: "tag")
                    .onTapGesture {
//                        if tasks != [] { // if I have called this view with at least one task
                        let tag = Tag(context: viewContext)
                        tag.id = UUID()
                        tag.name = searchText
                        tag.order = (tags.last?.order ?? 0) + 1
                        
                        if tasks != [] { // if I have called this view with at least one task, update the tasks and save, and deselect all tasks
                            for task in tasks {
                                tag.addToTasks(task) // note: the function addToTasks was created automatically by Core Data
                                print("Adding tag \(tag.name ?? "") to task \(task.name ?? "")")
                            }
                            deselectAllTasks()
                            PersistenceController.shared.save()
                            
                        }
                        else { // else if I have called this from the TaskDetailsView, update the selected tags so that I can save them in TaskDetailsView
                            selectedTags.append(tag)
                        }
                            
                            /*for task in tasks {
                                tag.addToTasks(task) // note: the function addToTasks was created automatically by Core Data
                                print("Adding tag \(tag.name ?? "") to task \(task.name ?? "")")
                            }*/
//                            PersistenceController.shared.save()
//                        }
                    }
            }
            
            List {
                ForEach(tags) { tag in
                    if(tag.name?.range(of: searchText, options: .caseInsensitive) != nil || searchText == "")  { // if the tag name contains the value of the search text, or the search text is blank
                        HStack {
                            if tasks != [] { // if I have called this view with at least one task, show a checkmark which is ticked if the first selected task has that tag
                                Image(systemName: tasks[0].hasTag(tag: tag) ? "checkmark.square.fill" : "square")
                            }
                            else { // else if I have called this from the TaskDetailsView, look in the selectedTags array instead
                                Image(systemName: selectedTags.firstIndex(of: tag) != nil ? "checkmark.square.fill" : "square")
                            }
                            
                            Text(tag.name ?? "")
                        }
                        .onTapGesture {
                            if tasks != [] { // if I have called this view with at least one task, update the tasks and save
                                for task in tasks {
                                    if task.hasTag(tag: tag) { // if the task already has this tag, remove it
                                        tag.removeFromTasks(task) // note: the function addToTasks was created automatically by Core Data
                                    }
                                    else { // else add the tag to the task
                                        tag.addToTasks(task) // note: the function addToTasks was created automatically by Core Data
                                        print("Adding tag \(tag.name ?? "") to task \(task.name ?? "")")
                                    }
                                }
                                PersistenceController.shared.save()
                            }
                            else { // else if I have called this from the TaskDetailsView, update the selected tags so that I can save them in TaskDetailsView
                                if let index = selectedTags.firstIndex(of: tag) { // if the tag is already selected, remove it
                                    selectedTags.remove(at: index)
                                }
                                else { // else add the tag to the task
                                    selectedTags.append(tag)
//                                    print("Adding tag \(tag.name ?? "") to task \(task.name ?? "")")
                                }
                            }
//                            for task in tasks {
//                                if task.hasTag(tag: tag) { // if the task already has this tag, remove it
//                                    tag.removeFromTasks(task) // note: the function addToTasks was created automatically by Core Data
//                                }
//                                else { // else add the tag to the task
//                                    tag.addToTasks(task) // note: the function addToTasks was created automatically by Core Data
//                                    print("Adding tag \(tag.name ?? "") to task \(task.name ?? "")")
//                                }
//                            }
//                            PersistenceController.shared.save()
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8)) // reduce padding of the list items
//            .listStyle(PlainListStyle())
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

//struct TagsPickerView_Previews: PreviewProvider {
//    static var previews: some View {
//        TagsPickerView(tasks: [])
//    }
//}
