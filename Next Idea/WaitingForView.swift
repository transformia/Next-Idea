//
//  WaitingForView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct WaitingForView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task>
    
    @State private var showSearchView = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(tasks.filter({!$0.completed && $0.waitingfor})) { task in // filter out completed tasks, and keep only waiting for tasks
                    HStack {
                        TaskView(task: task)
                        
                        Spacer()
                        
                        // Show the list's icon:
                        switch(task.list) {
                        case 0:
                            Image(systemName: "tray")
                        case 1:
                            Image(systemName: "scope")
                        case 2:
                            Image(systemName: "terminal.fill")
                        case 3:
                            Image(systemName: "text.append")
                        default:
                            Image(systemName: "tray")
                        }
                    }
                }
                .onMove(perform: moveItem)
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Waiting for")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSearchView) {
                SearchView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    
                    
                    Button {
                        showSearchView.toggle()
                    } label: {
                        Label("", systemImage: "magnifyingglass")
                    }
                }
            }
        }
    }
    
    private func moveItem(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        
        // If the item is moving down:
        if itemToMove < destination {
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = tasks.filter({!$0.completed && $0.waitingfor})[itemToMove].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                tasks.filter({!$0.completed && $0.waitingfor})[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasks.filter({!$0.completed && $0.waitingfor})[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = tasks.filter({!$0.completed && $0.waitingfor})[destination].order + 1
            let newOrder = tasks.filter({!$0.completed && $0.waitingfor})[destination].order
            while startIndex <= endIndex {
                tasks.filter({!$0.completed && $0.waitingfor})[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            tasks.filter({!$0.completed && $0.waitingfor})[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
}

struct WaitingForView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingForView()
    }
}
