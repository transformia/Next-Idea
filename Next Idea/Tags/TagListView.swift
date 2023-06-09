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
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.id, ascending: true)],
        animation: .default)
    private var tags: FetchedResults<Tag>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task> // to be able to count the tasks in each tag
    
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
//            .onMove(perform: moveItem)
        }
        .navigationTitle("Tags")
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
    
    private func countTasks(tag: Tag) -> Int {
        return tasks.filter({$0.tags?.contains(tag) ?? false && !$0.completed}).count
    }
}

struct TagListView_Previews: PreviewProvider {
    static var previews: some View {
        TagListView()
    }
}
