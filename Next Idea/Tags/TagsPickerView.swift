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
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.id, ascending: true)],
        animation: .default)
    private var tags: FetchedResults<Tag>
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    @State private var searchText = ""
    
    @FocusState private var focused: Bool
    
    let tasks: [Task]
    
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
                        if tasks != [] { // if I have called this view with at least one tag
                            let tag = Tag(context: viewContext)
                            tag.id = UUID()
                            tag.name = searchText
                            for task in tasks {
                                tag.addToTasks(task) // note: the function addToTasks was created automatically by Core Data
                                print("Adding tag \(tag.name ?? "") to task \(task.name ?? "")")
                            }
                            PersistenceController.shared.save()
                        }
                    }
            }
            
            List {
                ForEach(tags) { tag in
                    if(tag.name?.range(of: searchText, options: .caseInsensitive) != nil || searchText == "")  { // if the tag name contains the value of the search text, or the search text is blank
                        HStack {
                            if tasks != [] { // if I have called this view with at least one tag
                                Image(systemName: tasks[0].hasTag(tag: tag) ? "checkmark.square.fill" : "square")
                                    .onTapGesture {
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
                            }
                            
                            Text(tag.name ?? "")
                            
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct TagsPickerView_Previews: PreviewProvider {
    static var previews: some View {
        TagsPickerView(tasks: [])
    }
}
