//
//  TagTaskView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-17.
//

import SwiftUI

struct TagTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest private var filteredTasks: FetchedResults<Task>
    
    let tag: Tag
    
    init(tag: Tag) { // filter the task list on the ones linked to the provided tag
        self.tag = tag
        _filteredTasks = FetchRequest(
            entity: Task.entity(),
            sortDescriptors: [
//                NSSortDescriptor(keyPath: \Task.list, ascending: true),
                NSSortDescriptor(keyPath: \Task.order, ascending: true) // tasks sorted by order
            ],
            predicate: NSPredicate(format: "tags contains %@", tag)
        )
    }
    
    @State private var showSearchView = false
    
    var body: some View {
        VStack { // Contains tag name, ZStack and Quick action buttons
            Text(tag.name ?? "")
                .font(.headline)
            
            ZStack(alignment: .bottom) { // Contains task list and Add task buttons
                
                
                List {
                    ForEach(filteredTasks.filter({!$0.completed})) { task in
                        HStack {
                            TaskView(task: task)
                        }
                    }
                    .onMove(perform: { indices, destination in
                        moveItem(at: indices, destination: destination, filter: { task in
                            return task.tags?.contains(tag) ?? false && !task.completed
                        })
                    })
                }
                .padding(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8)) // reduce padding of the list items
                .listStyle(SidebarListStyle()) // so that the sections are expandable and collapsible. Could instead use PlainListStyle, but with DisclosureGroups instead of Sections...
    //            .listStyle(PlainListStyle())
                
                
//                if tasks.filter({!$0.completed && $0.ticked}).count > 0 { // if there are ticked tasks displayed, show a button to mark them as complete, and therefore hide them
//                    Button {
//                        for task in tasks {
//                            if task.ticked {
//                                task.completed = true
//                            }
//                        }
//                        PersistenceController.shared.save()
//                    } label: {
//                        Text("Clear completed tasks")
//                    }
//                    .padding(.bottom, 60)
//                }
                
                // Add task buttons:
                AddTaskButtonsView(defaultFocus: false, defaultWaitingFor: false, defaultProject: nil, defaultTag: tag) // add the task to the "Next" list
            }
            .sheet(isPresented: $showSearchView) {
                SearchView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if filteredTasks.filter({$0.selected}).count > 0 {
                            Button {
                                deselectAllTasks()
                            } label: {
                                Label("", systemImage: "pip.remove")
                            }
                        }
                        
                        Button {
                            showSearchView.toggle()
                        } label: {
                            Label("", systemImage: "magnifyingglass")
                        }
                    }
                }
            }
            
            QuickActionView()
            
        }
    }
    
    private func moveItem(at sets: IndexSet, destination: Int, filter: (Task) -> Bool) {
        let itemToMove = sets.first!
        let itemsForMove = filteredTasks.filter({!$0.completed})
        
        // If the item is moving down:
        if itemToMove < destination {
//            print(itemToMove)
//            print(destination)
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
//            print(startIndex)
//            print(endIndex)
            var startOrder = itemsForMove[itemToMove].order
//            print(startOrder)
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
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                itemsForMove[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            itemsForMove[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
    
    private func deselectAllTasks() {
        for task in filteredTasks {
            if task.selected {
                task.selected = false
            }
        }
        PersistenceController.shared.save()
    }
}

struct TagTaskView_Previews: PreviewProvider {
    static var previews: some View {
        TagTaskView(tag: Tag())
    }
}
