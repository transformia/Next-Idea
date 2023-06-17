//
//  AddTaskButtonsView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-06-12.
//

import SwiftUI

struct AddTaskButtonsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task>
    
    let list: Int16 // list to add the task to
    let project: Project?
    let tag: Tag?
    
    @EnvironmentObject var tab: Tab
    
    var body: some View {
        HStack {
            addTaskTopButton
            addTaskToInbox
            addTaskBottomButton
        }
    }
    
    var addTaskTopButton: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
            impactMed.impactOccurred() // haptic feedback
            // Create a new task:
            let task = Task(context: viewContext)
            task.id = UUID()
            task.order = (tasks.first?.order ?? 0) - 1
            task.list = list
            task.name = ""
            task.project = project
            tag?.addToTasks(task)
            task.createddate = Date()
//            PersistenceController.shared.save() // don't save it now, otherwise it will show up as a blank task on other devices, and the task name might get erased
        } label: {
            Image(systemName: "arrow.up")
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(.white)
                .padding(10)
                .background(.green)
                .clipShape(Circle())
        }
        .padding(.bottom, 8)
    }
    
    var addTaskToInbox: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
            impactMed.impactOccurred() // haptic feedback
            
            tab.selection = 0
            
            // Create a new task:
            let task = Task(context: viewContext)
            task.id = UUID()
            task.order = (tasks.last?.order ?? 0) + 1
            task.list = 0
            task.name = ""
            task.createddate = Date()
//            PersistenceController.shared.save() // don't save it now, otherwise it will show up as a blank task on other devices, and the task name might get erased
        } label: {
            Image(systemName: "tray")
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(.white)
                .padding(10)
                .background(.green)
                .clipShape(Circle())
        }
        .padding(.bottom, 8)
    }
    
    var addTaskBottomButton: some View {
        Button {
            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
            impactMed.impactOccurred() // haptic feedback
            // Create a new task:
            let task = Task(context: viewContext)
            task.id = UUID()
            task.order = (tasks.last?.order ?? 0) + 1
            task.list = list
            task.name = ""
            task.project = project
            tag?.addToTasks(task)
            task.createddate = Date()
//            PersistenceController.shared.save() // don't save it now, otherwise it will show up as a blank task on other devices, and the task name might get erased
        } label: {
            Image(systemName: "arrow.down")
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(.white)
                .padding(10)
                .background(.green)
                .clipShape(Circle())
        }
        .padding(.bottom, 8)
    }
}

struct AddTaskButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskButtonsView(list: 0, project: nil, tag: nil)
    }
}
