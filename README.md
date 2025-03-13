# Karmic Healing 2025

An app for spiritual growth and energy balancing, built with modern iOS technologies.

## 🏗️ Architecture

The project is based on **The Composable Architecture (TCA)** with a modular structure:

### Main modules:
- **Home** – main screen with navigation
- **Onboarding** – welcome screen for new users
- **BalancingEnergyList** – list of energy balancing processes
- **BalancingEnergy** – detailed energy balancing process
- **Requests** – management of requests and prayers
- **AppSettings** – app settings
- **Common** – shared components and utilities

### Technologies:
- **SwiftUI** – UI framework
- **ComposableArchitecture** – architecture pattern
- **Tuist** – project management
- **SwiftData** – local data storage

## 🚀 Getting Started

### Requirements:
- Xcode 15.0+
- iOS 17.4+
- Tuist 4.0+

### Installation:
```bash
# Clone the repository
git clone <repository-url>
cd KarmicHealing

# Install dependencies
tuist fetch
tuist generate
```

### Launch:
```bash
# Generate the project
tuist generate

# Open in Xcode
open KarmicHealing.xcworkspace
```

## 📱 Features

### Main features:
1. **Energy balancing** – three process levels:
   - Initial Process
   - Essential Self
   - Divine Self

2. **Request management** – create and track prayers

3. **Settings** – app personalization

4. **Localization** – support for Ukrainian, Russian, and English

## 🏛️ Architectural Principles

### TCA Reducers:
```swift
@Reducer
public struct Home {
  @ObservableState
  public struct State: Equatable {
    var path = StackState<Path.State>()
    let homeButtons: [HomeButton]
  }

  public enum Action: Equatable {
    case didTap(HomeButton)
    case path(StackActionOf<Path>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      // Action handling logic
    }
    .forEach(\.path, action: \.path)
  }
}
```

### Dependency Injection:
```swift
@Dependency(\.userDefaults) var userDefaults
@Dependency(\.analytics) var analytics
@Dependency(\.persistence) var persistence
```

## 🧪 Testing

### Unit Tests:
```bash
# Run tests
xcodebuild test -workspace KarmicHealing.xcworkspace -scheme Home
```

### Test Coverage:
- Reducer logic
- UI components
- Dependency injection
- Navigation flows

## 📊 Analytics & Performance

### Analytics Events:
- Onboarding completion
- Energy balancing sessions
- Request creation
- Settings changes

### Performance Monitoring:
- Screen load times
- Navigation performance
- Memory usage

## ♿ Accessibility

### Supported features:
- VoiceOver
- Dynamic Type
- High Contrast
- Reduce Motion
- Switch Control

### Usage:
```swift
Button("Start Process") {
  // action
}
.karmicHealingButtonAccessibility(
  label: "Start Energy Balancing Process",
  hint: "Double tap to begin the healing session"
)
```

## 🌍 Localization

### Supported languages:
- 🇺🇦 Ukrainian (uk)
- 🇷🇺 Russian (ru)
- 🇺🇸 English (en)

### Adding new strings:
1. Add to `MainTarget/Resources/Localizable.xcstrings`
2. Use `String(localized: "key", bundle: .main)`

## 🔧 Configuration

### Environment Variables:
- `DEBUG` – debug mode
- `ANALYTICS_ENABLED` – enable analytics
- `PERFORMANCE_MONITORING` – enable performance monitoring

### Build Configurations:
- Debug
- Release
- Test

## 📦 Dependencies

### External:
- ComposableArchitecture
- Dependencies

### Internal:
- Common
- Resources
- TestingUtilities

## 🤝 Contributing

### Code Style:
- SwiftLint rules
- TCA best practices
- SwiftUI guidelines

### Pull Request Process:
1. Create a feature branch
2. Add tests
3. Update documentation
4. Submit PR

## 📄 License

MIT License – see [LICENSE](LICENSE) for details.

## 🆘 Support

For questions and support:
- Email: karmic.healing@gmail.com
- Issues: GitHub Issues
- Documentation: Wiki

---

**Karmic Healing 2025** – Your path to spiritual growth 🌟 