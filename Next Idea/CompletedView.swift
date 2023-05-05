//
//  CompletedView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct CompletedView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task>
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            List {
                ForEach(tasks.filter({$0.completed})) { task in
                    TaskView(task: task)
                }
            }
            
            if tasks.filter({$0.completed}).count > 0 {
                Button {
                    for task in tasks {
                        if task.completed {
                            viewContext.delete(task)
                        }
                    }
                    PersistenceController.shared.save()
                } label: {
                    Text("Delete completed tasks")
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Completed tasks")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CompletedView_Previews: PreviewProvider {
    static var previews: some View {
        CompletedView()
    }
}
