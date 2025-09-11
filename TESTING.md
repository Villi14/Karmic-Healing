# Тестування KarmicHealing

Цей документ описує структуру тестів та як їх запускати в проекті KarmicHealing.

## Структура тестів

### 1. **DB Tests** (`KarmicHealing/Features/DB/Tests/`)

#### `RequestsListsModelTests.swift`
- Тести для основної моделі списків запитів
- Перевіряє навігацію, ініціалізацію та основні методи
- Тести для `requestsListTapped`, `addListButtonTapped`, `helpButtonTapped`

#### `RemindersListsModelTests.swift`
- Тести для моделі списків нагадувань
- Перевіряє навігацію та статистику
- Тести для `statTapped`, `remindersListTapped`

#### `DataModelTests.swift`
- Тести для всіх моделей даних
- Перевіряє ініціалізацію `RequestsList`, `Request`, `RemindersList`, `Reminder`
- Тести для Draft класів та Priority enum

#### `SearchModelTests.swift`
- Тести для моделей пошуку
- Перевіряє `SearchRequestsModel` та `SearchRemindersModel`
- Тести для поведінки пошуку та фільтрації

### 2. **TestingUtilities Tests** (`KarmicHealing/Features/TestingUtilities/Tests/`)

#### `TestingUtilitiesTests.swift`
- Тести для утиліт тестування
- Перевіряє `XCTest+expectParameter` та `XCTest+withTrackedCalls`
- Тести для CMTime extensions

### 3. **Home Tests** (`KarmicHealing/Features/Home/Tests/`)

#### `HomeTests.swift`
- Тести для головного екрану
- Перевіряє навігацію, кнопки та lifecycle
- Тести для Composable Architecture

## Запуск тестів

### Через Xcode
1. Відкрийте `KarmicHealing.xcworkspace`
2. Натисніть `Cmd+U` для запуску всіх тестів
3. Або виберіть конкретний тест і натисніть `Cmd+U`

### Через командний рядок
```bash
# Запуск всіх тестів
xcodebuild test -workspace KarmicHealing.xcworkspace -scheme KarmicHealing

# Запуск конкретного тесту
xcodebuild test -workspace KarmicHealing.xcworkspace -scheme KarmicHealing -only-testing:DBTests/RequestsListsModelTests
```

## Налаштування тестів

### База даних для тестів
Тести використовують тестову базу даних, яка створюється в тимчасовій директорії:

```swift
// В Schema.swift
let path = URL.temporaryDirectory.appending(component: "\(UUID().uuidString)-db.sqlite").path()
```

### Dependencies для тестів
Тести використовують `@Dependency` для ізоляції:

```swift
@Dependency(\.defaultDatabase) private var database
```

## Покриття тестами

### Поточне покриття
- ✅ Моделі даних (RequestsList, Request, RemindersList, Reminder)
- ✅ Основні ViewModels (RequestsListsModel, RemindersListsModel)
- ✅ Моделі пошуку (SearchRequestsModel, SearchRemindersModel)
- ✅ Утиліти тестування
- ✅ Home функціональність

### Планується додати
- 🔄 Тести для UI компонентів
- 🔄 Тести для інтеграції з базою даних
- 🔄 Тести для навігації
- 🔄 Тести для утиліт (DesignConstants, Extensions)

## Написання нових тестів

### Структура тесту
```swift
final class MyModelTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Налаштування тесту
  }
  
  override func tearDown() {
    super.tearDown()
    // Очищення після тесту
  }
  
  func testMyFunction() {
    // Arrange
    let model = MyModel()
    
    // Act
    let result = model.myFunction()
    
    // Assert
    XCTAssertEqual(result, expectedValue)
  }
}
```

### Тестування з базою даних
```swift
func testDatabaseOperation() async {
  let model = MyModel()
  
  // Використовуйте withErrorReporting для тестування операцій з БД
  await withErrorReporting {
    try await model.performDatabaseOperation()
  }
  
  // Перевірте результат
  XCTAssertTrue(model.operationCompleted)
}
```

### Тестування Composable Architecture
```swift
func testReducer() async {
  let store = TestStore(initialState: MyState()) {
    MyReducer()
  }
  
  await store.send(.myAction) {
    // Assert state changes
    $0.someProperty = expectedValue
  }
  
  await store.receive(.myEffect) {
    // Assert effects
  }
}
```

## Найкращі практики

1. **Назви тестів** - використовуйте описові назви: `testRequestsListTappedSetsCorrectDestination`
2. **Arrange-Act-Assert** - структуруйте тести згідно з цією патерном
3. **Ізоляція** - кожен тест повинен бути незалежним
4. **Mocking** - використовуйте моки для зовнішніх залежностей
5. **Асинхронність** - правильно тестуйте async/await код

## Відлагодження тестів

### Логування
```swift
func testWithLogging() {
  print("DEBUG: Starting test")
  
  let result = myFunction()
  
  print("DEBUG: Result: \(result)")
  
  XCTAssertNotNil(result)
}
```

### Breakpoints
- Встановлюйте breakpoints в тестах для відлагодження
- Використовуйте `po` команди в консолі для перевірки значень

## CI/CD

Тести автоматично запускаються при:
- Pull Request
- Push до main гілки
- Ручному запуску

Переконайтеся, що всі тести проходять перед мерджем коду.

