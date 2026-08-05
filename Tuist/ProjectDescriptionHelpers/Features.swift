@preconcurrency import ProjectDescription

// MARK: - Common Models

public let common = Module(
  feature: .common,
  dependencies: [
    .target(resources.implementationTarget),
    .external(name: "ComposableArchitecture"),
    .external(name: "XCTestDynamicOverlay")
  ],
  resources: .notPresent,
  unitTests: .present(
    dependencies: [
      .target(testingUtilities.implementationTarget),
      .external(name: "ComposableArchitecture")
    ]
  )
)

// MARK: - Shared Resources (colors)

public let resources = Module(
  feature: .resources,
  dependencies: [],
  resources: .custom(
    [
      "KarmicHealing/Features/Resources/Assets/**",
    ]
  ),
  hasSources: false
)

// MARK: - Onboarding module

public let onboarding = Module(
  feature: .onboarding,
  dependencies: [
    .target(common.implementationTarget),
    .target(resources.implementationTarget),
    .external(name: "ComposableArchitecture")
  ],
  resources: .notPresent,
  unitTests: .present(
    dependencies: [
      .target(testingUtilities.implementationTarget),
      .external(name: "ComposableArchitecture")
    ]
  )
)

// MARK: - Home module

public let home = Module(
  feature: .home,
  dependencies: [
    .target(common.implementationTarget),
    .target(resources.implementationTarget),
    .target(balancingEnergyList.implementationTarget),
    .target(db.implementationTarget),
    .target(appSettings.implementationTarget),
    .external(name: "ComposableArchitecture")
  ],
  resources: .notPresent,
  unitTests: .present(
    dependencies: [
      .target(testingUtilities.implementationTarget),
      .external(name: "ComposableArchitecture")
    ]
  )
)

// MARK: - Balancing Energy List module

public let balancingEnergyList = Module(
  feature: .balancingEnergyList,
  dependencies: [
    .target(common.implementationTarget),
    .target(resources.implementationTarget),
    .target(balancingEnergy.implementationTarget),
    .external(name: "ComposableArchitecture")
  ],
  resources: .notPresent,
  unitTests: .present(
    dependencies: [
      .target(testingUtilities.implementationTarget),
      .external(name: "ComposableArchitecture")
    ]
  )
)

// MARK: - Balancing Energy module

public let balancingEnergy = Module(
  feature: .balancingEnergy,
  dependencies: [
    .target(common.implementationTarget),
    .target(resources.implementationTarget),
    .external(name: "ComposableArchitecture")
  ],
  resources: .notPresent,
  unitTests: .present(
    dependencies: [
      .target(testingUtilities.implementationTarget),
      .external(name: "ComposableArchitecture")
    ]
  )
)

// MARK: - Requests module

public let db = Module(
  feature: .db,
  dependencies: [
    .target(common.implementationTarget),
    .target(resources.implementationTarget),
    .external(name: "ComposableArchitecture"),
    .external(name: "SQLiteData"),
    // SQLiteData, unlike the old SharingGRDB, does not re-export Sharing.
    .external(name: "Sharing")
  ],
  resources: .notPresent,
  unitTests: .present(
    dependencies: [
      .target(testingUtilities.implementationTarget),
      .external(name: "ComposableArchitecture")
    ]
  )
)

// MARK: - App Settings module

public let appSettings = Module(
  feature: .appSettings,
  dependencies: [
    .target(common.implementationTarget),
    .target(resources.implementationTarget),
    .external(name: "ComposableArchitecture")
  ],
  resources: .notPresent,
  unitTests: .present(
    dependencies: [
      .target(testingUtilities.implementationTarget),
      .external(name: "ComposableArchitecture")
    ]
  )
)

// MARK: - Testing Utilities (links XCTest so don't depend on it in app modules)

public let testingUtilities = Module(
  feature: .testingUtilities,
  dependencies: [
    .xctest,
    .external(name: "ComposableArchitecture"),
  ],
  resources: .notPresent,
  unitTests: .present(dependencies: [])
)

// MARK: - Watch App (all-in-one for watchOS)

public let watchApp = Module(
  feature: .watchApp,
  dependencies: [
    .external(name: "ComposableArchitecture")
  ],
  resources: .custom(
    [
      "KarmicHealing/Features/WatchApp/Resources/**"
    ]
  ),
  hasSources: true
)

