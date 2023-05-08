//
//  DueTodayView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-06.
//

import SwiftUI

struct DueTodayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.list, ascending: true), NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default) // tasks sorted by order, then by list
    private var tasks: FetchedResults<Task>
    
    var body: some View {
        List {
            ForEach(tasks.filter({!$0.completed && $0.dateactive && Calendar.current.startOfDay(for: $0.date ?? Date()) <= Calendar.current.startOfDay(for: Date())})) { task in // filter out completed tasks, and keep only tasks due today
                HStack {
                    
                    TaskView(task: task)
                    
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
        }
        .navigationTitle("Due today")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DueTodayView_Previews: PreviewProvider {
    static var previews: some View {
        DueTodayView()
    }
}
