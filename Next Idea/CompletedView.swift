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
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.modifieddate, ascending: false)],
        animation: .default)
    private var tasks: FetchedResults<Task>
    
    var body: some View {
        
        VStack {
            List {
                ForEach(tasks.filter({$0.completed})) { task in
                    TaskView(task: task)
                }
            }
            .listStyle(PlainListStyle())
//            .padding(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8)) // reduce padding of the list items
            
            if tasks.filter({$0.completed && $0.modifieddate ?? Date() < Calendar.current.date(byAdding: .month, value: -1, to: Date())!}).count > 0 {
                Button {
                    for task in tasks.filter({$0.completed && $0.modifieddate ?? Date() < Calendar.current.date(byAdding: .month, value: -1, to: Date())!}) {
                        viewContext.delete(task)
                    }
                    PersistenceController.shared.save()
                } label: {
                    Text("Delete completed tasks older than 1 month")
                }
                .padding(.bottom, 40)
            }
            
//            if tasks.filter({$0.completed}).count > 0 {
//                Button {
//                    for task in tasks.filter({$0.completed}) {
//                        viewContext.delete(task)
//                    }
//                    PersistenceController.shared.save()
//                } label: {
//                    Text("Delete all completed tasks")
//                }
//                .padding(.bottom, 20)
//            }
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
