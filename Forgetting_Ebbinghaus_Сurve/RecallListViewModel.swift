//
//  RecallListViewModel.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 05.11.2025.
//

import Foundation

@MainActor
class RecallListViewModel: ObservableObject {

    @Published private(set) var items: [RecallItem] = [] {
        didSet {
            persistenceManager.saveItems(items)
        }
    }

    private let notificationManager: NotificationManagerProtocol
    private let persistenceManager: PersistenceManagerProtocol

    // Dependency injection with default parameters for backward compatibility
    init(
        notificationManager: NotificationManagerProtocol = NotificationManager.shared,
        persistenceManager: PersistenceManagerProtocol = PersistenceManager.shared
    ) {
        self.notificationManager = notificationManager
        self.persistenceManager = persistenceManager
        self.items = persistenceManager.loadItems()
    }
    
    // --- НОВЫЙ МЕТОД ---
    // Безопасно удаляет элементы по указанным индексам
    // и отменяет связанные с ними уведомления.
    func delete(at offsets: IndexSet) {
        // Сначала получаем элементы, которые будут удалены.
        let itemsToDelete = offsets.map { items[$0] }
        
        // Для каждого из них отменяем запланированные уведомления.
        itemsToDelete.forEach { item in
            notificationManager.cancelNotifications(for: item)
        }
        
        // Наконец, удаляем сами элементы из нашего массива.
        items.remove(atOffsets: offsets)
    }
    
    // --- Старые методы (без изменений) ---
    
    func requestNotificationPermission() {
        notificationManager.requestAuthorization()
    }
    
    /// Checks if scheduling notifications for the given content would result in night-time conflicts.
    /// Only checks intervals >= 10 minutes (skips 5s, 25s, 2min).
    /// - Parameter content: The content to be added
    /// - Returns: NotificationConflict if conflicts detected, nil otherwise
    func checkForConflicts(content: String) -> NotificationConflict? {
        guard !content.isEmpty else { return nil }

        // Create a temporary item to calculate notification dates
        let tempItem = RecallItem(content: content)
        let allDates = ForgettingCurve.reminderDates(from: tempItem.createdAt)

        // Filter to only check intervals >= 10 minutes (indices 3+)
        // Index 0: 5s, Index 1: 25s, Index 2: 2min (skip these)
        // Index 3: 10min and beyond (check these)
        let datesToCheck = Array(allDates.dropFirst(3))

        // Find dates that fall in the night window
        let conflictingDates = datesToCheck.filter { NightWindow.isDateInNightWindow($0) }

        // If no conflicts, return nil
        guard !conflictingDates.isEmpty else { return nil }

        // Calculate postponed dates (7 AM on the same day as each conflicting notification)
        let postponedDates = conflictingDates.map { date in
            NightWindow.morningWakeTime(onSameDayAs: date)
        }

        // Detect user's region
        let region = NightWindow.detectUserRegion()

        return NotificationConflict(
            item: tempItem,
            allScheduledDates: allDates,
            conflictingDates: conflictingDates,
            postponedDates: postponedDates,
            userRegion: region
        )
    }

    /// Adds an item with optional postponement of conflicting notifications.
    /// - Parameters:
    ///   - content: The content to remember
    ///   - conflict: Optional conflict information. If provided, conflicting dates will be postponed.
    func addItem(content: String, withConflict conflict: NotificationConflict? = nil) {
        guard !content.isEmpty else { return }

        let newItem = RecallItem(content: content)
        items.insert(newItem, at: 0)

        // Determine which dates to use for scheduling
        let scheduleDates: [Date]
        if let conflict = conflict {
            // Use the final schedule that combines non-conflicting and postponed dates
            scheduleDates = conflict.finalSchedule
        } else {
            // Use all original dates
            scheduleDates = ForgettingCurve.reminderDates(from: newItem.createdAt)
        }

        notificationManager.scheduleNotifications(for: newItem, on: scheduleDates)
    }
    
    func getReminderDates(for item: RecallItem) -> [Date] {
        return ForgettingCurve.reminderDates(from: item.createdAt)
    }
    
    func getNextReminderDate(for item: RecallItem) -> Date? {
        let allDates = ForgettingCurve.reminderDates(from: item.createdAt)
        return allDates.first(where: { $0 > Date() })
    }
    
    func cancelAllPendingNotifications() {
        notificationManager.cancelAllNotifications()
    }
    
    func logAllPendingNotifications() {
        notificationManager.logPendingNotifications()
    }
}
