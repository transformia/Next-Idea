//
//  IconPickerView.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-06-26.
//

import SwiftUI

struct IconPickerView: View {
    
    let project: Project
    
    @Binding var selectedIcon: String
    
    struct ImageIcon: View {
        
        @Environment(\.dismiss) private var dismiss // used for dismissing this view
        
        var systemName: String
        @Binding var selectedIcon: String
        
        var body: some View {
            Image(systemName: systemName)
                .resizable()
                .frame(width: 24, height: 24)
                .padding()
                .onTapGesture {
                    selectedIcon = systemName
//                    print(selectedIcon)
                    dismiss()
                }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "shift.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "play.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "star.fill", selectedIcon: $selectedIcon)
            }
            HStack {
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
            }
            HStack {
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
            }
            HStack {
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
            }
        }
    }
}

//struct IconPickerView_Previews: PreviewProvider {
//    static var previews: some View {
//        IconPickerView(project: Project())
//    }
//}
