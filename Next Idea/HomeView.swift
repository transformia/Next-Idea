//
//  HomeView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                
                NavigationLink {
                    DueTodayView()
                } label: {
                    Text("Due and overdue")
                }
                
                NavigationLink {
                    ProjectListView()
                } label: {
                    Text("Projects")
                }
                
                NavigationLink {
                    TagsView()
                } label: {
                    Text("Tags")
                }
                
                NavigationLink {
                    WaitingForView()
                } label: {
                    Text("Waiting for")
                }
                
                NavigationLink {
                    CompletedView()
                } label: {
                    Text("Completed tasks")
                }
                
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
