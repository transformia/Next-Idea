//
//  Extensions.swift
//  Next Idea
//
//  Created by Michael Frisk on 2023-07-25.
//

import Foundation
import SwiftUI

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
    
    func hasTag(tag: Tag) -> Bool { // returns true if the task has the specified tag
        for tasktag in self.tags ?? [] {
            if (tasktag as! Tag) == tag {
                return true
            }
        }
        return false
    }
    
    func createNotification() { // create a notification for this task at the date and time specified in the task, using the same id as the task
//        let notificationId = UUID().uuidString
        let notificationId = String(describing: self.id) // use the same id as on the task
        let reminderDate: Date
        let title: String
        
        reminderDate = self.date ?? Date() // reminder on the date and time
        title = "Task due now"
        
        print("Creating a notification for \(reminderDate) for task \(self.name ?? ""): id \(notificationId)")
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.subtitle = self.name ?? ""
        notificationContent.sound = UNNotificationSound.default
//        notificationContent.categoryIdentifier = "TASK"
        
        let dateComponents = Calendar.current.dateComponents(Set(arrayLiteral: Calendar.Component.year, Calendar.Component.month, Calendar.Component.day, Calendar.Component.hour, Calendar.Component.minute), from: reminderDate)
        
        let notificationTrigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let notificationRequest = UNNotificationRequest(identifier: notificationId, content: notificationContent, trigger: notificationTrigger) // create the notification request
        
        UNUserNotificationCenter.current().add(notificationRequest) // add the notification request
        
//        self.notificationid = notificationId // save the id of the notification
    }
    
    
    // Not used for now, but could be useful:
//    func checkNotification() { // check if a notification exists, and cancel it or create it if necessary
//
//        let notificationId = String(describing: self.id) // get the id from the task (which is also the notification's identifier)
//
//        // Check if there is a local notification with this id on this device:
//        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
//            let notificationExists = requests.contains { request in
//                return request.identifier == notificationId
//            }
//
//            if notificationExists { // if the notification exists, cancel it if it shouldn't exist
//                print("Notification for task \(self.name ?? "") exists")
//                if !self.reminderactive || self.date ?? Date() < Date() {
//                    print("The date is the past, or the reminder is inactive, so nothing will be done")
//                    self.cancelNotification()
//                }
//                else {
//
//                }
//
//            } else { // else if the notification doesn't exist, create it if it should exist
//                print("Notification for task \(self.name ?? "") does not exist")
//                if self.reminderactive && self.date ?? Date() > Date() {
//                    self.createNotification()
//                }
//                else {
//                    print("The date is the past, or the reminder is inactive, so nothing will be done")
//                }
//            }
//        }
//    }
    
    func cancelNotification() {
        let notificationId = String(describing: self.id)
        print("Canceling notification \(notificationId) if it exists")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId]) // remove the pending notification
    }
}
