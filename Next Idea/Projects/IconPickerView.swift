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
                ImageIcon(systemName: "1.circle.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "2.circle.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "3.circle.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "4.circle.fill", selectedIcon: $selectedIcon)
            }
            HStack {
                ImageIcon(systemName: "book.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "shift.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "list.bullet", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "star.fill", selectedIcon: $selectedIcon)
            }
            HStack {
                ImageIcon(systemName: "opticaldisc.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "dollarsign.circle.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "clock.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "calendar.circle.fill", selectedIcon: $selectedIcon)
            }
            HStack {
                ImageIcon(systemName: "suit.heart.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "suit.diamond.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "suit.spade.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "suit.club.fill", selectedIcon: $selectedIcon)
            }
            HStack {
                ImageIcon(systemName: "pencil.circle.fill", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "figure.2.arms.open", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "highlighter", selectedIcon: $selectedIcon)
                ImageIcon(systemName: "folder.fill", selectedIcon: $selectedIcon)
            }
        }
    }
}

//struct IconPickerView_Previews: PreviewProvider {
//    static var previews: some View {
//        IconPickerView(project: Project())
//    }
//}
