//
// Karmic Healing 2025
//

import Foundation
import SQLiteData
import SwiftUI

#if DEBUG
extension Database {
  func seedSampleData() throws {
    let remindersListIDs = (0...2).map { _ in UUID() }
    let reminderIDs = (0...10).map { _ in UUID() }
    let requestsListIDs = (0...2).map { _ in UUID() }
    let requestIDs = (0...10).map { _ in UUID() }

    try seed {
      RequestsList(
        id: requestsListIDs[0],
        color: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255),
        title: "Personal Request"
      )

      RequestsList(
        id: requestsListIDs[1],
        color: Color(red: 0xed / 255, green: 0x89 / 255, blue: 0x35 / 255),
        title: "Family Request"
      )

      RequestsList(
        id: requestsListIDs[2],
        color: Color(red: 0xb2 / 255, green: 0x5d / 255, blue: 0xd3 / 255),
        title: "Business Request"
      )

      Request(
        id: requestIDs[0],
        notes: "Milk\nEggs\nApples\nOatmeal\nSpinach",
        requestsListID: requestsListIDs[0],
        title: "Groceries"
      )

      Request(
        id: requestIDs[1],
        requestsListID: requestsListIDs[0],
        title: "Haircut"
      )

      Request(
        id: requestIDs[2],
        notes: "Ask about diet",
        requestsListID: requestsListIDs[0],
        title: "Doctor appointment"
      )

      Request(
        id: requestIDs[3],
        isCompleted: true,
        requestsListID: requestsListIDs[0],
        title: "Take a walk"
      )

      Request(
        id: requestIDs[4],
        requestsListID: requestsListIDs[0],
        title: "Buy concert tickets"
      )

      Request(
        id: requestIDs[5],
        requestsListID: requestsListIDs[1],
        title: "Pick up kids from school"
      )

      Request(
        id: requestIDs[6],
        isCompleted: true,
        requestsListID: requestsListIDs[1],
        title: "Get laundry"
      )

      Request(
        id: requestIDs[7],
        isCompleted: false,
        requestsListID: requestsListIDs[1],
        title: "Take out trash"
      )

      Request(
        id: requestIDs[8],
        notes: """
            Status of tax return
            Expenses for next year
            Changing payroll company
            """,
        requestsListID: requestsListIDs[2],
        title: "Call accountant"
      )

      Request(
        id: requestIDs[9],
        isCompleted: true,
        requestsListID: requestsListIDs[2],
        title: "Send weekly emails"
      )

      Request(
        id: requestIDs[10],
        isCompleted: false,
        requestsListID: requestsListIDs[2],
        title: "Prepare for WWDC"
      )

      RemindersList(
        id: remindersListIDs[0],
        color: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255),
        title: "Personal Reminder"
      )

      RemindersList(
        id: remindersListIDs[1],
        color: Color(red: 0xed / 255, green: 0x89 / 255, blue: 0x35 / 255),
        title: "Family Reminder"
      )

      RemindersList(
        id: remindersListIDs[2],
        color: Color(red: 0xb2 / 255, green: 0x5d / 255, blue: 0xd3 / 255),
        title: "Business Reminder"
      )

      Reminder(
        id: reminderIDs[0],
        notes: "Milk\nEggs\nApples\nOatmeal\nSpinach",
        remindersListID: remindersListIDs[0],
        title: "Groceries"
      )

      Reminder(
        id: reminderIDs[1],
        dueDate: Date().addingTimeInterval(-60 * 60 * 24 * 2),
        isFlagged: true,
        remindersListID: remindersListIDs[0],
        title: "Haircut"
      )

      Reminder(
        id: reminderIDs[2],
        dueDate: Date(),
        notes: "Ask about diet",
        priority: .high,
        remindersListID: remindersListIDs[0],
        title: "Doctor appointment"
      )

      Reminder(
        id: reminderIDs[3],
        dueDate: Date().addingTimeInterval(-60 * 60 * 24 * 190),
        isCompleted: true,
        remindersListID: remindersListIDs[0],
        title: "Take a walk"
      )

      Reminder(
        id: reminderIDs[4],
        dueDate: Date(),
        remindersListID: remindersListIDs[0],
        title: "Buy concert tickets"
      )

      Reminder(
        id: reminderIDs[5],
        dueDate: Date().addingTimeInterval(60 * 60 * 24 * 2),
        isFlagged: true,
        priority: .high,
        remindersListID: remindersListIDs[1],
        title: "Pick up kids from school"
      )

      Reminder(
        id: reminderIDs[6],
        dueDate: Date().addingTimeInterval(-60 * 60 * 24 * 2),
        isCompleted: true,
        priority: .low,
        remindersListID: remindersListIDs[1],
        title: "Get laundry"
      )

      Reminder(
        id: reminderIDs[7],
        dueDate: Date().addingTimeInterval(60 * 60 * 24 * 4),
        isCompleted: false,
        priority: .high,
        remindersListID: remindersListIDs[1],
        title: "Take out trash"
      )

      Reminder(
        id: reminderIDs[8],
        dueDate: Date().addingTimeInterval(60 * 60 * 24 * 2),
        notes: """
            Status of tax return
            Expenses for next year
            Changing payroll company
            """,
        remindersListID: remindersListIDs[2],
        title: "Call accountant"
      )
      
      Reminder(
        id: reminderIDs[9],
        dueDate: Date().addingTimeInterval(-60 * 60 * 24 * 2),
        isCompleted: true,
        priority: .medium,
        remindersListID: remindersListIDs[2],
        title: "Send weekly emails"
      )

      Reminder(
        id: reminderIDs[10],
        dueDate: Date().addingTimeInterval(60 * 60 * 24 * 2),
        isCompleted: false,
        remindersListID: remindersListIDs[2],
        title: "Prepare for WWDC"
      )
    }
  }
}
#endif
