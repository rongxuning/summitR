---
name: ios-developer
description: Provides iOS app development expertise including Swift, SwiftUI, UIKit, best practices, and Apple frameworks. Use when developing iOS apps, working with Xcode, Swift code, or when the user mentions iOS, iPhone, iPad, or Apple development.
---

# iOS App Developer

## Core Technologies

### Swift Language
- Use Swift 5.9+ features (async/await, actors, macros)
- Follow Swift API Design Guidelines
- Prefer value types (structs, enums) over reference types when appropriate
- Use optionals properly and avoid force unwrapping
- Leverage Swift's type system for safety

### UI Frameworks

**SwiftUI** (Preferred for new projects):
- Declarative UI with `@State`, `@Binding`, `@ObservedObject`, `@StateObject`
- Use `View` protocol and modifiers
- Navigation with `NavigationStack` (iOS 16+)
- Lists with `List` and `ForEach`
- Forms with `Form` and form controls

**UIKit** (Legacy or complex requirements):
- View controllers and view lifecycle
- Auto Layout with constraints or Stack Views
- Storyboards or programmatic UI
- Delegation pattern for communication

### Architecture Patterns

**MVVM** (Recommended for SwiftUI):
- Model: Data structures and business logic
- View: SwiftUI views
- ViewModel: `ObservableObject` classes with `@Published` properties

**MVC** (UIKit):
- Model: Data and business logic
- View: UI components
- Controller: View controllers coordinating between Model and View

**Other patterns**:
- Coordinator pattern for navigation
- Repository pattern for data access
- Dependency injection for testability

## Apple Frameworks

### Core Frameworks
- **Foundation**: Basic types, collections, networking
- **Combine**: Reactive programming with publishers and subscribers
- **SwiftUI**: Modern declarative UI framework
- **UIKit**: Traditional imperative UI framework
- **Core Data**: Object graph and persistence framework
- **UserDefaults**: Simple key-value storage
- **Keychain**: Secure credential storage

### Networking
- Use `URLSession` for HTTP requests
- Consider `async/await` for modern async code
- Parse JSON with `Codable` protocol
- Handle errors appropriately

### Data Persistence
- **UserDefaults**: Simple preferences
- **Core Data**: Complex relational data
- **SwiftData** (iOS 17+): Modern alternative to Core Data
- **FileManager**: File system operations

## Best Practices

### Code Quality
- Write self-documenting code with clear naming
- Keep functions small and focused (single responsibility)
- Use extensions to organize code
- Prefer composition over inheritance
- Handle errors explicitly, avoid silent failures

### Performance
- Use lazy loading for heavy operations
- Optimize images and assets
- Profile with Instruments
- Use `@MainActor` for UI updates
- Avoid blocking the main thread

### Memory Management
- Understand ARC (Automatic Reference Counting)
- Avoid retain cycles with `weak` and `unowned`
- Use value types to reduce memory overhead
- Clean up resources in `deinit`

### Testing
- Write unit tests with XCTest
- Test business logic independently
- Use dependency injection for testability
- Mock external dependencies
- Aim for high code coverage

## Xcode Workflow

### Project Structure
- Organize files by feature or layer
- Use groups to mirror folder structure
- Keep related files together
- Separate concerns (UI, networking, models)

### Build Settings
- Set minimum deployment target appropriately
- Configure code signing and provisioning
- Use build configurations (Debug/Release)
- Manage dependencies with Swift Package Manager or CocoaPods

### Debugging
- Use breakpoints and LLDB
- Print debugging with `print()` or `os_log`
- Use Instruments for performance profiling
- Check console logs for warnings and errors

## Common Patterns

### Async Operations
```swift
// Modern async/await
Task {
    let data = try await fetchData()
    await MainActor.run {
        updateUI(with: data)
    }
}

// Combine
publisher
    .receive(on: DispatchQueue.main)
    .sink { value in
        updateUI(with: value)
    }
```

### Error Handling
```swift
enum AppError: Error {
    case networkError
    case decodingError
    case unknown
}

do {
    let result = try await performOperation()
} catch {
    handleError(error)
}
```

### State Management
```swift
// SwiftUI
@StateObject private var viewModel = ViewModel()

// Combine
@Published var items: [Item] = []
```

## iOS-Specific Considerations

### Lifecycle
- Understand app lifecycle (foreground, background, suspended)
- Handle app state transitions
- Save state when app enters background
- Resume appropriately when returning to foreground

### User Experience
- Follow Human Interface Guidelines
- Support Dark Mode
- Handle different screen sizes and orientations
- Provide accessibility support (VoiceOver, Dynamic Type)
- Design for different device capabilities

### Security
- Store sensitive data in Keychain
- Use App Transport Security (ATS)
- Validate and sanitize user input
- Protect against common vulnerabilities

## Resources

- Apple Developer Documentation
- WWDC sessions for latest features
- Swift.org for language evolution
- Human Interface Guidelines for design
- App Store Review Guidelines for submission
