# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"Forgetting Ebbinghaus Curve" is an iOS/macOS SwiftUI application that implements spaced repetition based on the Ebbinghaus forgetting curve. The app schedules smart notifications to help users retain information using adaptive learning algorithms that consider text complexity, length, and time of day.

## Project Structure

The codebase is organized into logical folders under `Forgetting_Ebbinghaus_Сurve/`:

```
Forgetting_Ebbinghaus_Сurve/
├── App/
│   └── Forgetting_Ebbinghaus__urveApp.swift      # Main app entry point
├── Models/
│   ├── FlashcardItem.swift                       # Flashcard data model
│   ├── RecallItem.swift                          # Recall task data model
│   ├── StudyProgress.swift                       # Review tracking for flashcards
│   ├── ReviewDifficulty.swift                    # Difficulty rating enum (Easy/Good/Hard)
│   ├── TextCategory.swift                        # Text categorization enum (Short/Medium/Long)
│   └── NotificationConflict.swift                # Night window conflict representation
├── Services/
│   ├── NotificationManager.swift                 # System notification handling
│   ├── PersistenceManager.swift                  # JSON-based data persistence
│   ├── ForgettingCurve.swift                     # Spaced repetition interval calculations
│   ├── TextComplexityAnalyzer.swift              # Text analysis and categorization
│   └── NightWindow.swift                         # Night-time scheduling utilities
├── Utilities/
│   ├── AppColor.swift                            # Color theme definitions
│   ├── Constants.swift                           # App-wide constants
│   └── TimeInterval+Formatting.swift             # Time formatting extensions
├── ViewModels/
│   └── RecallListViewModel.swift                 # Main business logic coordinator
├── Views/
│   ├── RecallItems/                              # Recall task views
│   │   └── ContentView.swift                     # Main recall interface
│   └── Flashcards/                               # Flashcard system views
│       ├── FlashcardListView.swift               # Main flashcard list with filters
│       ├── FlashcardRowView.swift                # Individual row in list
│       ├── FlashcardDetailView.swift             # Card with flip animation
│       ├── StudySessionView.swift                # Dedicated study mode interface
│       └── IndividualFlashcardReviewView.swift   # Single card review with stats
└── Assets.xcassets                               # Images and color assets
```

**Organizational Principles**:
- **Models/**: Pure data structures (Codable, Identifiable, no business logic)
- **Services/**: Core business logic and system integrations
  - Managers (NotificationManager, PersistenceManager) use singleton pattern
  - Utilities (ForgettingCurve, TextComplexityAnalyzer, NightWindow) are stateless
- **Utilities/**: UI extensions, constants, and formatting helpers
- **ViewModels/**: State management and view coordination (@MainActor, @Published properties)
- **Views/**: SwiftUI views organized by feature (RecallItems, Flashcards)
  - Each feature has its own subfolder with related views

## Build and Development Commands

### Building the Project
```bash
# Build for all platforms (iOS and macOS)
xcodebuild -scheme "Forgetting_Ebbinghaus_Сurve" -configuration Debug build

# Build for specific destination
xcodebuild -scheme "Forgetting_Ebbinghaus_Сurve" -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild -scheme "Forgetting_Ebbinghaus_Сurve" -destination 'platform=macOS' build
```

### Running Tests
```bash
# Run all tests
xcodebuild test -scheme "Forgetting_Ebbinghaus_Сurve" -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test target
xcodebuild test -scheme "Forgetting_Ebbinghaus_Сurve" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:Forgetting_Ebbinghaus_СurveTests

# Run UI tests
xcodebuild test -scheme "Forgetting_Ebbinghaus_Сurve" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:Forgetting_Ebbinghaus_СurveUITests
```

### Cleaning Build
```bash
xcodebuild clean -scheme "Forgetting_Ebbinghaus_Сurve"
```

## Architecture Overview

### Core Data Flow
1. **ContentView** → User interface with real-time text analysis and category detection
2. **RecallListViewModel** → Business logic coordinator, manages items, flashcards, and notifications
3. **ForgettingCurve** → Pure business logic for calculating spaced repetition intervals
4. **NotificationManager** → Handles system notifications and scheduling
5. **PersistenceManager** → JSON-based data persistence to local storage (recall_items.json and flashcards.json)

### Flashcard System

The app includes a full-featured flashcard system for spaced repetition learning:

**Core Components**:
- **FlashcardItem** → Data model with front (question) and back (answer) content
- **StudyProgress** → Tracks review performance and adaptive interval multipliers
- **FlashcardDetailView** → Interactive card with 3D flip animation
- **StudySessionView** → Dedicated study interface showing cards one at a time
- **FlashcardListView** → Main list view with filtering and search

**Study Mode Behavior**:
- Shows **all available flashcards** regardless of due status (modern app behavior)
- Cards always start with the question side (front)
- Progress tracking with card counter (e.g., "Card 2 of 10")
- Completion screen after reviewing all cards

**Review Difficulty System**:
- Three difficulty levels: Easy, Good, Hard
- Each difficulty adjusts the interval multiplier:
  - **Easy**: +15% longer intervals (multiplier +0.15)
  - **Good**: Standard intervals (no change)
  - **Hard**: -20% shorter intervals (multiplier -0.20)
- Multiplier clamped between 0.5x and 2.0x
- Affects all future review intervals for that card

**View Identity Management**:
- FlashcardDetailView uses `.id()` modifier to force recreation on card change
- Prevents flip state (`showingBack`) from persisting across cards
- Ensures every new card starts with question side visible

### Adaptive Learning System

The app features a three-tier text categorization system:

- **Short** (<20 chars): Fast-paced intervals for quick notes (3s → 1 year, 11 intervals)
- **Medium** (20-400 chars): Standard Ebbinghaus curve (5s → 2 years, 11 intervals)
- **Long** (>400 chars): Extended intervals for complex content (10s → 3 years, 11 intervals)

**TextComplexityAnalyzer** automatically detects category based on:
- Character count (primary factor)
- Complexity score (formulas, numbers, technical terms, capitalization density)
- Mathematical symbols and scientific notation
- Acronyms and technical terminology patterns

Users can manually override detected categories via the segmented picker in ContentView.

### Smart Notification Timing

**Night Window System** (22:00-07:00):
- **NightWindow** utility checks if notifications fall during sleep hours
- **NotificationConflict** represents scheduling conflicts with night window
- When adding items at night, the system detects conflicts and offers to postpone notifications to 7 AM
- Only intervals ≥10 minutes are checked (skips 5s, 25s, 2min for immediate learning)
- Region-aware messaging based on timezone detection

### Dependency Injection Pattern

The ViewModel uses protocol-based dependency injection for testability:
```swift
init(
    notificationManager: NotificationManagerProtocol = NotificationManager.shared,
    persistenceManager: PersistenceManagerProtocol = PersistenceManager.shared
)
```

This allows mocking managers in tests while using singletons in production.

### Data Models

**RecallItem**:
- Core data structure representing a recall task
- Contains `textCategory` and `isManuallyOverridden` fields for adaptive scheduling
- Uses custom `Codable` implementation for backwards compatibility (defaults to `.medium`)

**FlashcardItem**:
- Represents a flashcard with front (question) and back (answer) content
- Contains `studyProgress` field tracking review history and performance
- Supports text categorization (short/medium/long) affecting base intervals
- Includes computed properties: `hasBeenReviewed`, `characterCount`, `frontPreview`, `backPreview`
- Conforms to `Identifiable`, `Codable`, `Equatable`, `Hashable`

**StudyProgress** (embedded in FlashcardItem):
- Tracks review statistics: `totalReviews`, `easyCount`, `goodCount`, `hardCount`
- Maintains `currentIntervalMultiplier` (1.0 default, clamped 0.5-2.0)
- Records `lastReviewDate` for each flashcard
- Provides computed properties: `successRate`, `averageDifficulty`
- Implements Anki-style interval adjustment based on difficulty ratings

**TextCategory** enum:
- `.short`, `.medium`, `.long`
- Provides display names, descriptions, and SF Symbol icons for UI
- Applies to both RecallItems and FlashcardItems

### Notification System

**NotificationManager**:
- Implements `UNUserNotificationCenterDelegate` for foreground notifications
- Initialized in app lifecycle (`Forgetting_Ebbinghaus_urveApp.init()`)
- Uses UUID-based identifiers: `{item.id}-{timestamp}` for precise cancellation
- Supports bulk operations: cancel all, cancel by item, log pending

**Scheduling Logic**:
- Notifications scheduled using `UNCalendarNotificationTrigger` with specific date components
- Supports conflict resolution by replacing dates in the schedule (see RecallListViewModel:139-147)

### Platform-Specific Features

**macOS**:
- Multi-selection support in List with keyboard shortcuts (⌫ for delete)
- Context menu for selected items
- Custom CommandGroup for Edit menu integration
- Compact flashcard difficulty buttons with keyboard shortcuts (1, 2, 3)
- Horizontal difficulty button layout in study mode

**iOS**:
- Swipe-to-delete gestures on list items
- Standard iOS confirmation dialogs
- Full-width flashcard difficulty buttons with descriptions
- Vertical difficulty button layout in study mode
- Hover effects on interactive elements

## Key Implementation Details

### Debounced Text Analysis
ContentView uses Task-based debouncing (300ms) for complexity analysis to avoid expensive calculations on every keystroke (ContentView:239-283). Provides immediate preliminary categorization, then runs full analysis after debounce.

### Backwards Compatibility
ForgettingCurve includes `@available(*, deprecated)` markers for legacy methods that don't support text categories. These will be removed in version 2.0.

### State Management
- ContentView maintains UI state for category selection, conflict alerts, and analysis details
- RecallListViewModel is `@MainActor` and uses `@Published` properties
- PersistenceManager auto-saves on every items array mutation via `didSet`

### Notification Lifecycle
1. Item created → ViewModel calculates reminder dates
2. Night window check → Detect conflicts, show alert if needed
3. User chooses → Schedule with original or postponed dates
4. Item deleted → Cancel notifications by UUID prefix matching

## Working with the Codebase

### Adding New Reminder Intervals
Modify the interval arrays in ForgettingCurve.swift (shortTextIntervals, mediumTextIntervals, longTextIntervals). Keep 11 intervals per category for consistency.

### Modifying Text Complexity Detection
Update TextComplexityAnalyzer thresholds or complexity calculation logic. The analyzer uses weighted factors (math symbols ×3, numbers ×1.5, special chars ×2, etc.).

### Changing Night Window Hours
Modify NightWindow constants: `nightStartHour` (default 22) and `morningWakeHour` (default 7).

### Data Persistence
Items are stored in Documents directory:
- `recall_items.json` → RecallItem storage
- `flashcards.json` → FlashcardItem storage with StudyProgress
PersistenceManager handles encoding/decoding with error recovery (returns empty array on failure).

### Working with Flashcards

**Adding Flashcards**:
```swift
viewModel.addFlashcard(
    frontContent: "Question text",
    backContent: "Answer text",
    manualCategory: .medium  // Optional, auto-detects if nil
)
```

**Recording Reviews**:
```swift
viewModel.recordReview(
    flashcardId: flashcard.id,
    difficulty: .good  // .easy, .good, or .hard
)
```

**Getting Due Flashcards** (Study Mode):
- `getDueFlashcards()` returns all flashcards (modern behavior)
- Previously filtered by due status, now returns `flashcardItems` array
- Allows users to study any cards anytime

**View State Management**:
- Always use `.id()` modifier when displaying FlashcardDetailView in a loop/list
- This ensures flip state resets between cards
- Example: `.id(flashcard.id)` or `.id(dueFlashcards[currentIndex].id)`

### Testing Notifications
Use toolbar buttons in ContentView:
- "Show Log" → Print all pending notifications to console
- "Cancel All" → Remove all scheduled notifications

## Important Notes

- The app name contains a Cyrillic 'С' in some files (Forgetting_Ebbinghaus_Сurve) - be mindful when referencing paths
- All notification scheduling respects user's system timezone
- The project targets both iOS and macOS with conditional compilation (`#if os(macOS)`)
- No external dependencies - uses only Foundation, SwiftUI, and UserNotifications frameworks
- При создании файлов, пиши в названии, как в легаси файлах, например ContentView.swift, то есть не указывай, что файл создал ты, а указывай, что его создал mac
- Старайся писать человечные комментарии к коду на английском языке

## Recent Changes and Bugfixes

### Study Mode Behavior Update
- Changed `getDueFlashcards()` to return **all flashcards** instead of filtering by due status
- Modern flashcard app behavior: allows studying any card anytime
- Updated UI text from "No Cards Due" to "No Cards Available"
- Renamed internal variable from `dueCount` to `studyCardsCount` for clarity

### Flashcard Flip State Bug (Critical Fix)
**Problem**: When reviewing multiple cards in Study Mode, after rating the first card, the second card would appear flipped (showing answer instead of question).

**Root Cause**: SwiftUI was reusing the existing FlashcardDetailView instead of creating a new one, causing the `@State var showingBack` to persist across cards.

**Solution**: Added `.id()` modifier to force View recreation:
- `StudySessionView.swift:76` → `.id(dueFlashcards[currentIndex].id)`
- `IndividualFlashcardReviewView.swift:35` → `.id(flashcard.id)`

**Result**: Every flashcard now correctly starts with the question side visible.

### Best Practices
- **Always** use `.id()` modifier when displaying FlashcardDetailView in dynamic contexts
- This pattern applies to any SwiftUI view with `@State` that should reset when data changes
- The `.id()` modifier is crucial for proper view lifecycle management in lists/loops

