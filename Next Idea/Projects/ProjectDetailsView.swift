//
//  ProjectDetailsView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-05-05.
//

import SwiftUI

struct ProjectDetailsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let project: Project?
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.order, ascending: true)],
        animation: .default)
    private var projects: FetchedResults<Project>
    
    @State private var name = ""
    @State private var displayOption = "All"
    @State private var note = ""
    @State private var selectedIcon = "book.fill"
    @State private var selectedColor = "black"
    
    @FocusState private var focused: Bool
    
    @State private var showDeleteAlert = false
    @State private var showIconPicker = false
    
    let colors = ["black", "green", "blue"]
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("", text: $name, axis: .vertical)
                    .focused($focused)
                    .onAppear {
                        name = project?.name ?? ""
                        displayOption = project?.displayoption ?? "All"
                        note = project?.note ?? ""
                        selectedIcon = project?.icon ?? "book.fill"
//                        selectedColor = project?.color
                        if project == nil { // if this is a new project, focus on the project name
                            focused = true
                        }
                    }
                    .onChange(of: name) { _ in
                        // If I press enter:
                        if name.contains("\n") { // if a newline is found
                            name = name.replacingOccurrences(of: "\n", with: "") // replace it with nothing
                            focused = false // close the keyboard
                        }
                    }
                
                Picker("Display", selection: $displayOption) {
                    Text("All tasks")
                        .tag("All")
                    Text("First task")
                        .tag("First")
                    Text("On hold")
                        .tag("Hold")
                }
                
                HStack {
                    Text("Icon")
                    Spacer()
                    Image(systemName: selectedIcon)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(selectedColor))
                }
                .onTapGesture {
                    showIconPicker = true
                }
                
                
                HStack {
                    Text("Color")
                    Spacer()
                    Picker("", selection: $selectedColor) {
                        ForEach(colors, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                TextField("Notes", text: $note, axis: .vertical)
                    .font(.footnote)
                
                if project != nil { // if this is not a new project, show a button to delete it
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
                                    viewContext.delete(project!)
                                    PersistenceController.shared.save() // save the changes
                                    dismiss()
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(project: project ?? Project(), selectedIcon: $selectedIcon)
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
                        if project == nil {
                            let project = Project(context: viewContext)
                            project.id = UUID()
                            project.order = (projects.first?.order ?? 0) - 1
                            project.name = name
                            project.note = note
                            project.displayoption = displayOption
                            project.icon = selectedIcon
                            project.color = selectedColor
                            project.createddate = Date()
                        }
                        else {
                            project?.name = name
                            project?.displayoption = displayOption
                            project?.note = note
                            project?.modifieddate = Date()
                            project?.icon = selectedIcon
                            project?.color = selectedColor
                        }
                        PersistenceController.shared.save()
                        dismiss() // dismiss the sheet
                    } label: {
                        Text("Save")
                    }
                }
            }
        }
        .interactiveDismissDisabled(project?.name != name || project?.note != note) // prevent accidental dismissal of the sheet if any value has been modified
    }
}

struct ProjectDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectDetailsView(project: Project())
    }
}
