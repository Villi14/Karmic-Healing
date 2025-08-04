# Common Clients

Цей каталог містить клієнти в стилі TCA (The Composable Architecture) для різних системних сервісів.

## AudioClient

`AudioClient` - це TCA-стильний клієнт для роботи з аудіо в додатку.

### Використання

```swift
@Reducer
public struct MyFeature {
  @Dependency(\.audio) var audio
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .playSound:
        audio.playSound("ding")
        return .none
      case .stopSound:
        audio.stopSound()
        return .none
      case .setVolume:
        audio.setVolume(0.5)
        return .none
      }
    }
  }
}
```

### Методи

- `playSound(named:withExtension:)` - відтворює звук з файлу
- `playSound(_:)` - відтворює звук з розширенням .wav за замовчуванням
- `stopSound()` - зупиняє поточний звук
- `isPlaying()` - перевіряє, чи відтворюється звук
- `setVolume(_:)` - встановлює гучність
- `getVolume()` - отримує поточну гучність

### Тестування

```swift
let store = TestStore(initialState: MyFeature.State()) {
  MyFeature()
} withDependencies: {
  $0.audio.playSound = { soundName, ext in
    XCTAssertEqual(soundName, "ding")
    XCTAssertEqual(ext, "wav")
  }
  $0.audio.isPlaying = { true }
}
```

## NotificationClient

Клієнт для роботи з локальними сповіщеннями.

## UserDefaultsClient

Клієнт для роботи з UserDefaults з типобезпечними ключами.

### Типобезпечні ключі

```swift
// Bool keys
public static let soundEnabled = BoolKey("sound_enabled")
public static let vibrationEnabled = BoolKey("vibration_enabled")

// String keys  
public static let userLanguage = StringKey("user_language")

// Int keys
public static let sessionDuration = IntKey("session_duration")
```

### Використання

```swift
@Dependency(\.userDefaults) var userDefaults

// Reading
let soundEnabled = userDefaults.bool(for: .soundEnabled)
let language = userDefaults.string(for: .userLanguage)
let duration = userDefaults.integer(for: .sessionDuration)

// Writing
await userDefaults.setAsync(true, for: .soundEnabled)
await userDefaults.setAsync("uk", for: .userLanguage)
await userDefaults.setAsync(10, for: .sessionDuration)
``` 