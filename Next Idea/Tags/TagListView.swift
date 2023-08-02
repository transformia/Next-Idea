//
//  TagListView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-17.
//

import SwiftUI

struct TagListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.order, ascending: true)],
        animation: .default)
    private var tags: FetchedResults<Tag>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task> // to be able to count the tasks in each tag
    
    @EnvironmentObject var weeklyReview: WeeklyReview
    
    @State private var showSettingsView = false
    @State private var showSearchView = false
    
    var body: some View {
        List {
            ForEach(tags) { tag in
                NavigationLink {
                    TagTaskView(tag: tag)
                } label: {
                    HStack {
                        Text(tag.name ?? "")
                        Spacer()
                        Text("\(countTasks(tag: tag))")
                    }
                }
            }
            .onDelete(perform: deleteItem)
            .onMove(perform: moveItem)
        }
        .padding(EdgeInsets(top: 0, leading: -12, bottom: 0, trailing: -12)) // reduce padding of the list items
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
        }
        .sheet(isPresented: $showSearchView) {
            SearchView()
        }
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
                        if weeklyReview.active {
                            Label("", systemImage: "figure.yoga")
                        }
                        else {
                            Label("", systemImage: "figure.mind.and.body")
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        showSearchView.toggle()
                    } label: {
                        Label("", systemImage: "magnifyingglass")
                    }
                    
                    EditButton()
                }
            }
        }
    }
    
    private func countTasks(tag: Tag) -> Int {
        return tasks.filter({$0.tags?.contains(tag) ?? false && !$0.completed}).count
    }
    
    private func moveItem(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        let itemsForMove = tags
        
        // If the item is moving down:
        if itemToMove < destination {
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = itemsForMove[itemToMove].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                itemsForMove[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            itemsForMove[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = itemsForMove[destination].order + 1
            let newOrder = itemsForMove[destination].order
            while startIndex <= endIndex {
                itemsForMove[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            itemsForMove[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
    
    private func deleteItem(at offsets: IndexSet) {
           for index in offsets {
               let tag = tags[index]
               // Perform the deletion of the tag here using Core Data
               viewContext.delete(tag)
           }
           // Save the managed object context after deleting the tags
           do {
               try viewContext.save()
           } catch {
               // Handle any errors during the save process
               print("Error saving context after deleting tags: \(error)")
           }
       }
}

struct TagListView_Previews: PreviewProvider {
    static var previews: some View {
        TagListView()
    }
}
