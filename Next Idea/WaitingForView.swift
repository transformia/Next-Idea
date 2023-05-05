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
    
    var body: some View {
        List {
            ForEach(tasks.filter({!$0.completed && $0.waitingfor})) { task in // filter out completed tasks, and keep only waiting for tasks
                TaskView(task: task)
            }
            .onMove(perform: moveItem)
        }
        .navigationTitle("Waiting for")
        .navigationBarTitleDisplayMode(.inline)
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
