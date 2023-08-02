//
//  SettingsView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-11.
//

import SwiftUI
import EventKit // to be able to access reminders and calendars

struct SettingsView: View {
    @EnvironmentObject var eventKitManager: ContentView.EventKitManager // get the reminder lists from the environment
    
    @State private var showingRemindersAuthorizationAlert = false
    
    @State private var checkbox = false
    
    var body: some View {
        Form {
            Section(header: Text("Settings")) {
                Toggle("Checkbox to complete tasks", isOn: $checkbox)
                    .onAppear {
                        checkbox = UserDefaults.standard.bool(forKey: "Checkbox")
                    }
                    .onChange(of: checkbox) { _ in
                        UserDefaults.standard.set(checkbox, forKey: "Checkbox")
                    }
                
                Toggle("Import from Apple Reminders", isOn: $eventKitManager.importActive)
                    .onAppear {
                        if EKEventStore.authorizationStatus(for: .reminder) == .denied { // if the user has removed the authorization for importing reminders, deactivate the import
                            eventKitManager.importActive = false
                            UserDefaults.standard.set(eventKitManager.importActive, forKey: "RemindersImportActive")
                        }
                    }
                    .onChange(of: eventKitManager.selectedList) { _ in
                        UserDefaults.standard.set(eventKitManager.selectedList?.calendarIdentifier, forKey: "RemindersSelectedList")
                        print("Changing list to import. New list: \(UserDefaults.standard.string(forKey: "RemindersSelectedList") ?? "")")
                    }
                    .onChange(of: eventKitManager.importActive) { _ in
                        if eventKitManager.importActive { // if I'm activating the import, ask for permission if it hasn't already been done, and fetch the lists from Apple Reminders:
                            if EKEventStore.authorizationStatus(for: .reminder) == .notDetermined { // if the user hasn't authorized import yet, ask for it, and deactivate the import for now
                                eventKitManager.requestRemindersAccess()
                                eventKitManager.importActive = false
                            }
                            else if EKEventStore.authorizationStatus(for: .reminder) == .denied { // if the user has denied access to Reminders, tell him where to go to authorize it, and deactivate the import for now
                                showingRemindersAuthorizationAlert = true
                                eventKitManager.importActive = false
                            }
                            else { // if the user has authorized import, get the list of calendars
                                eventKitManager.getReminderCalendars()
                            }
                        }
                        UserDefaults.standard.set(eventKitManager.importActive, forKey: "RemindersImportActive")
                        print("Activating or deactivating import. New status: \(UserDefaults.standard.bool(forKey: "RemindersImportActive"))")
                    }
                    .alert(isPresented: $showingRemindersAuthorizationAlert) {
                        Alert (title: Text("Reminders access is required"),
                               message: Text("Please go to the Settings and allow Next Idea to access Reminders, then come back here and try again"),
                               primaryButton: .default(Text("Open Settings"), action: {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }),
                               secondaryButton: .default(Text("Cancel")))
                    }
                if eventKitManager.importActive {
                    Picker("Reminders list", selection: $eventKitManager.selectedList) {
                        ForEach(eventKitManager.reminderLists, id: \.self) { reminderList in
                            Text(reminderList.title)
                                .tag(reminderList as EKCalendar?)
                        }
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
