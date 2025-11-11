//
//  RecallListViewModel.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 05.11.2025.
//

import Foundation

@MainActor
class RecallListViewModel: ObservableObject {
    
    @Published private(set) var items: [RecallItem] = []
    
    private let notificationManager = NotificationManager.shared
    
    func requestNotificationPermission() {
        notificationManager.requestAuthorization()
    }
    
    func addItem(content: String) {
        guard !content.isEmpty else { return }
        
        let newItem = RecallItem(content: content)
        items.insert(newItem, at: 0)

        let reminderDates = ForgettingCurve.reminderDates(from: newItem.createdAt)
        notificationManager.scheduleNotifications(for: newItem, on: reminderDates)
    }
    
    func getReminderDates(for item: RecallItem) -> [Date] {
        return ForgettingCurve.reminderDates(from: item.createdAt)
    }
    
    func getNextReminderDate(for item: RecallItem) -> Date? {
        let allDates = ForgettingCurve.reminderDates(from: item.createdAt)
        return allDates.first(where: { $0 > Date() })
    }
    
    // --- НОВЫЙ МЕТОД №1 ---
    func cancelAllPendingNotifications() {
        notificationManager.cancelAllNotifications()
    }
    
    // --- НОВЫЙ МЕТОД №2 ---
    func logAllPendingNotifications() {
        notificationManager.logPendingNotifications()
    }
}
