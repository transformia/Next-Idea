//
//  ProjectDetailsView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct ProjectDetailsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let project: Project
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    @State private var name = ""
    @State private var note = ""
    
    @FocusState private var focused: Bool
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                TextField("", text: $name, axis: .vertical)
                    .focused($focused)
                    .onAppear {
                        name = project.name ?? ""
                        note = project.note ?? ""
                    }
                    .onChange(of: name) { _ in
                        // If I press enter:
                        if name.contains("\n") { // if a newline is found
                            name = name.replacingOccurrences(of: "\n", with: "") // replace it with nothing
                            focused = false // close the keyboard
                        }
                    }
                TextField("Notes", text: $note, axis: .vertical)
                    .font(.footnote)
                
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete project", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .alert(isPresented: $showDeleteAlert) {
                    Alert(
                        title: Text("Are you sure you want to delete this project?"),
                        message: Text("This cannot be undone"),
                        primaryButton: .destructive(Text("Delete")) {
                            withAnimation {
                                viewContext.delete(project)
                                PersistenceController.shared.save() // save the changes
                                dismiss()
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button {
                            dismiss() // dismiss the sheet
                        } label: {
                            Text("Cancel")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        project.name = name
                        project.note = note
                        project.modifieddate = Date()
                        PersistenceController.shared.save()
                        dismiss() // dismiss the sheet
                    } label: {
                        Text("Save")
                    }
                }
            }
        }
        .interactiveDismissDisabled(project.name != name || project.note != note) // prevent accidental dismissal of the sheet if any value has been modified
    }
}

struct ProjectDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectDetailsView(project: Project())
    }
}
