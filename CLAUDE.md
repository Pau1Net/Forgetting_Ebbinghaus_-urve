# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Forgetting Ebbinghaus Curve is an iOS and macOS application for creating text-based notes designed to enhance information retention based on the Ebbinghaus forgetting curve. The app schedules spaced repetition notifications at scientifically-determined intervals to improve memory retention.

## Building and Running

**Build the project:**
```bash
xcodebuild -project "Forgetting_Ebbinghaus_Сurve.xcodeproj" -scheme "Forgetting_Ebbinghaus_Сurve" build
```

**Run tests:**
```bash
# Run all tests
xcodebuild test -project "Forgetting_Ebbinghaus_Сurve.xcodeproj" -scheme "Forgetting_Ebbinghaus_Сurve" -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test class
xcodebuild test -project "Forgetting_Ebbinghaus_Сurve.xcodeproj" -scheme "Forgetting_Ebbinghaus_Сurve" -only-testing:Forgetting_Ebbinghaus_СurveTests/ClassName -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Open in Xcode:**
```bash
open "Forgetting_Ebbinghaus_Сurve.xcodeproj"
```

## Architecture

### Core Components

**ForgettingCurve (ForgettingCurve.swift)**
- Business logic module defining the Ebbinghaus spaced repetition intervals
- Hardcoded intervals: 5s, 25s, 2m, 10m, 1h, 5h, 1d, 5d, 25d, 4mo, 2yr
- Provides `reminderDates(from:)` to calculate all reminder dates from a start date

**RecallItem ( RecallItem.swift)**
- Data model representing a single piece of information to remember
- Contains: UUID, content string, and creation timestamp
- Conforms to Identifiable and Codable for SwiftUI integration and persistence

**RecallListViewModel (RecallListViewModel.swift)**
- Main business logic coordinator using `@MainActor`
- Manages the list of RecallItems with automatic persistence on changes
- Uses dependency injection for `NotificationManagerProtocol` and `PersistenceManagerProtocol`
- Key methods:
  - `addItem(content:)` - Creates item and schedules notifications
  - `delete(at:)` - Removes items and cancels their notifications
  - `getReminderDates(for:)` and `getNextReminderDate(for:)` - Calculate notification schedules

**NotificationManager (NotificationManager.swift)**
- Singleton managing UserNotifications integration
- Protocol-based design (`NotificationManagerProtocol`) for testability
- Implements `UNUserNotificationCenterDelegate` to show notifications while app is in foreground
- Notification identifiers follow pattern: `{itemID}-{timestamp}` for granular cancellation
- Must call `setupDelegate()` in app initializer (see Forgetting_Ebbinghaus__urveApp.swift:16)

**PersistenceManager (PersistenceManager.swift)**
- Singleton handling JSON-based local storage
- Protocol-based design (`PersistenceManagerProtocol`) for testability
- Saves to `recall_items.json` in Documents directory
- Gracefully handles missing or corrupt data files

### UI Layer

**ContentView (ContentView.swift)**
- Main interface with platform-specific behaviors
- iOS: Swipe-to-delete on list items
- macOS: Multi-selection support, context menus, keyboard shortcuts (Delete/Cmd+Delete), custom Edit menu command
- Uses `@StateObject` for ViewModel lifecycle management
- Includes confirmation dialog for multi-item deletion

**RecallItemRowView (RecallItemRowView.swift)**
- Row component displaying individual recall items
- Shows reminder schedule and next reminder date

### Platform-Specific Code

The app uses `#if os(macOS)` compiler directives for platform-specific features:
- macOS: Selection-based deletion, keyboard shortcuts, Edit menu commands
- iOS: Swipe gestures for deletion

### Dependency Injection

Both managers use protocols and default parameters in initializers:
```swift
init(
    notificationManager: NotificationManagerProtocol = NotificationManager.shared,
    persistenceManager: PersistenceManagerProtocol = PersistenceManager.shared
)
```
This allows production code to use singletons while tests can inject mocks.

## Key Implementation Details

**Notification Scheduling:**
- All 11 notifications are scheduled when an item is created
- Uses `UNCalendarNotificationTrigger` with exact date components
- Notifications persist even if app is closed

**Data Flow:**
1. User adds item in ContentView
2. RecallListViewModel creates RecallItem
3. ViewModel triggers NotificationManager to schedule reminders
4. Items array change triggers PersistenceManager auto-save
5. On app restart, PersistenceManager loads items, but notifications persist independently

**Critical Initialization Order:**
The NotificationManager delegate must be set in the App initializer (Forgetting_Ebbinghaus__urveApp.swift:16) before any views are created to ensure foreground notifications display properly.

## Project Status

Currently in early development. See README.md for full roadmap. Implemented features:
- Basic note creation and deletion
- Ebbinghaus curve notification scheduling
- Local JSON persistence
- Cross-platform UI (iOS/macOS)

Planned features include: smart notifications, flashcard generation, adaptive learning, PDF support, AI-powered context, multi-language support.

Never write "created by Claude", instead always write "created by mac" and the creation date.
