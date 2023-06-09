//
//  SettingsView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-11.
//

import SwiftUI

struct SettingsView: View {
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
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
