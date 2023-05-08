//
//  ContentView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI
import CoreData
import UserNotifications

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(9)
            
            ListView(list: 0, showDeferred: false)
                .tabItem {
                    Label("Inbox", systemImage: "tray")
                }
                .tag(0)
            
            ListView(list: 1, showDeferred: false)
                .tabItem {
                    Label("Now", systemImage: "scope")
                }
                .tag(1)
            
            ListView(list: 2, showDeferred: false)
                .tabItem {
                    Label("Next", systemImage: "terminal.fill")
                }
                .tag(2)
            
            ListView(list: 3, showDeferred: false)
                .tabItem {
                    Label("Someday", systemImage: "text.append")
                }
                .tag(3)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
