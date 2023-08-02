//
//  Extensions.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-07-25.
//

import Foundation

extension Task {
    
    func filterTasks(filter: String) -> Bool {
        switch filter {
        case "Inbox":
            return (!self.completed && self.project == nil) // return true if the task is not completed and has no project
        case "Focus":
            return (!self.completed && self.project != nil && self.focus) // return true if the task is not completed, has a project and is focused
        case "Due":
            return (!self.completed && self.dateactive && Calendar.current.startOfDay(for: self.date ?? Date()) <= Calendar.current.startOfDay(for: Date())) // return true if the task is not completed, has a date active, and that date is today or in the past. Show tasks without a project, in case I have inbox tasks that are due
        case "Deferred":
            return (!self.completed && self.dateactive && self.hideuntildate && Calendar.current.startOfDay(for: self.date ?? Date()) > Date()) // return true if the task is not completed, has a date, is hidden until that date, and that date is in the future
        case "Waiting for":
            return (!self.completed && self.waitingfor) // return true if the task is not completed, has a project and is waiting for
        case "Next":
            return (!self.completed && self.project != nil && !self.focus && !self.someday) // return true if the task is not completed, has a project, is not focused, is not someday
        case "Someday":
            return (!self.completed && self.project != nil && self.someday) // return true if the task is not completed, has a project and is someday
        default:
            return false
        }
    }
}
