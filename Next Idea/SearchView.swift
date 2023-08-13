//
//  SearchView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-08.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task>
    
    @State private var searchText = ""
    @State private var confirmedSearchText = ""
    
    // Variable determining whether the focus is on the search text field or not:
    @FocusState private var focused: Bool
    
    var body: some View {
        
        NavigationStack {
            VStack {
                TextField("Search", text: $searchText)
                    .disableAutocorrection(true)
                    .padding(20)
                    .focused($focused)
                    .onAppear {
                        focused = true
                    }
                    .onSubmit {
                        confirmedSearchText = searchText
                    }
                NavigationStack {
                    List {
                        ForEach(tasks) { task in
                            if(!task.completed) {
                                if(task.name?.range(of: confirmedSearchText, options: .caseInsensitive) != nil || confirmedSearchText == "") { // if the task name contains the value of the search text, or the search text is blank
                                    NavigationLink {
                                        ProjectTaskView(project: task.project ?? Project())
                                    } label: {
                                        HStack {
                                            TaskView(task: task)
                                            
                                            Image(systemName: task.project?.icon ?? "book.fill")
                                                .resizable()
                                                .frame(width: 18, height: 18)
                                                .foregroundColor(Color(task.project?.color ?? "black"))
                                                .padding(.leading, 3)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8)) // reduce padding of the list items
//                    .listStyle(PlainListStyle())
                }
                .scrollDismissesKeyboard(.immediately) // dismiss the keyboard when scrolling through the search results
                
//                NavigationLink {
//                    CompletedView()
//                } label: {
//                    Text("Completed tasks")
//                        .padding()
//                }
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
