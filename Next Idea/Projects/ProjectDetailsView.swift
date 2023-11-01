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
    @State private var sequential = false // for sequential projects, only the first task is shown when looking at the Next list (except when viewed from within the project)
    
    @FocusState private var focused: Bool
    
    @State private var showDeleteAlert = false
    @State private var showIconPicker = false
    
    let colors = ["black", "red", "purple", "orange", "yellow", "brown", "green", "blue", "cyan"]
    
    var body: some View {
        NavigationStack {
            Form {
                
                // Temporary button to set my Single actions project as singleactions, and all others as not single actions:
                if projects.filter({$0.singleactions}).count != 1 {
                    Button {
                        for otherProject in projects {
                            otherProject.singleactions = false
                        }
                        project?.singleactions = true
                        project?.sequential = false
                    } label: {
                        Text("Set as single actions project, and set all others as not")
                    }
                }
                
                TextField("", text: $name, axis: .vertical)
                    .focused($focused)
                    .onAppear {
                        name = project?.name ?? ""
                        note = project?.note ?? ""
                        selectedIcon = project?.icon ?? "book.fill"
                        selectedColor = project?.color ?? "black"
                        sequential = project?.sequential == true
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
                
                if !(project?.singleactions ?? true) {
                    HStack {
                        Text("Sequential project")
                        Spacer()
                        Toggle("", isOn: $sequential)
                    }
                }
                
                if project == nil { // if this is a new project
                    
                    HStack {
                        Button() {
                            saveProject(toTop: true)
                        } label: {
                            Label("Add to top", systemImage: "arrow.up.circle.fill")
                        }
                        
                        Button() {
                            saveProject(toTop: false)
                        } label: {
                            Label("Add to bottom", systemImage: "arrow.down.circle.fill")
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                }
                
                TextField("Notes", text: $note, axis: .vertical)
                    .font(.footnote)
                
                if project != nil && !(project?.singleactions ?? true) && (project?.tasks?.allObjects as? [Task])?.filter({!$0.completed}).count == 0 { // if this is not a new project, and it is not the Single actions project, and the project has no uncompleted tasks, show a button to delete it
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
                        saveProject(toTop: true)
                    } label: {
                        Text("Save")
                    }
                }
            }
        }
        .interactiveDismissDisabled(project?.name != name || project?.note != note) // prevent accidental dismissal of the sheet if any value has been modified
    }
    
    private func saveProject(toTop: Bool) {
        if project == nil {
            let project = Project(context: viewContext)
            project.id = UUID()
            project.order = toTop ? (projects.first?.order ?? 0) - 1 : (projects.last?.order ?? 0) + 1
            project.name = name
            project.note = note
            project.icon = selectedIcon
            project.color = selectedColor
            project.sequential = sequential
            project.singleactions = false
            project.createddate = Date()
        }
        else {
            project?.name = name
            project?.note = note
            project?.modifieddate = Date()
            project?.icon = selectedIcon
            project?.color = selectedColor
            project?.sequential = sequential
        }
        PersistenceController.shared.save()
        dismiss() // dismiss the sheet
    }
}

struct ProjectDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectDetailsView(project: Project())
    }
}
