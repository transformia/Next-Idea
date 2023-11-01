//
//  ReviewView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-11-01.
//

import SwiftUI

struct ReviewView: View {
    
    @EnvironmentObject var tab: Tab
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task> // to be able to count the tasks in each tile
    
    var body: some View {
        List {
            Text("Collect everything that is on your mind")
            HStack {
                Image(systemName: countTasks(filter: "Inbox", reviewActive: false) == 0 ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 24.0, height: 24.0)
                Text("Empty your Inbox")
                    .strikethrough(countTasks(filter: "Inbox", reviewActive: false) == 0)
                Spacer()
                Text("\(countTasks(filter: "Inbox", reviewActive: false))")
            }
            .foregroundColor(countTasks(filter: "Inbox", reviewActive: false) == 0 ? .green : nil)
            Text("Empty your Focus list")
            Text("Review your Next actions. Still relevant? Actually a project? Less than 2 min - do it! Don't need to do it soon - move to Someday. Can I delegate it? Can I clarify the next action? Do I resist doing it because it not short enough, and I should break it down further?")
            Text("Review your Waiting for list. Create a task, or set a date, to remind someone?")
            Text("Review the Project list, evaluating the status of each, and ensuring that each has a next action")
                .onTapGesture {
                    withAnimation {
                        tab.selection = 1
                    }
                }
            Text("If time permits: Review your Someday list - keep for later, eliminate, or create a project")
        }
        .listStyle(PlainListStyle())
        .navigationTitle("Review checklist")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func countTasks(filter: String, reviewActive: Bool) -> Int {
        if filter != "" {
            return tasks.filter({
                $0.filterTasks(filter: filter)
                && ( !reviewActive || Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date()) ) // review mode is active, or the task has a next review date before the end of today
            }).count
        }
        else {
            return tasks.filter({
                !$0.completed
                && ( !reviewActive || Calendar.current.startOfDay(for: $0.nextreviewdate ?? Date()) <= Calendar.current.startOfDay(for: Date()) ) // review mode is active, or the task has a next review date before the end of today
            }).count
        }
    }
}

#Preview {
    ReviewView()
}
