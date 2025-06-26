@preconcurrency import ProjectDescription

// MARK: - Common Models

public let common = Module(
  feature: .common,
  dependencies: [
    .external(name: "ComposableArchitecture"),
    .external(name: "SharingGRDB"),
    .external(name: "XCTestDynamicOverlay")
  ],
  resources: .notPresent
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
  resources: .notPresent
)

// MARK: - Home module

public let home = Module(
  feature: .home,
  dependencies: [
    .target(common.implementationTarget),
    .target(resources.implementationTarget),
    .target(balancingEnergyList.implementationTarget),
    .target(requests.implementationTarget),
    .target(notes.implementationTarget),
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
  resources: .notPresent
)

// MARK: - Balancing Energy module

public let balancingEnergy = Module(
  feature: .balancingEnergy,
  dependencies: [
    .target(common.implementationTarget),
    .target(resources.implementationTarget),
    .external(name: "ComposableArchitecture")
  ],
  resources: .notPresent
)

// MARK: - Requests module

public let requests = Module(
  feature: .requests,
  dependencies: [
    .target(common.implementationTarget),
    .target(resources.implementationTarget),
    .external(name: "ComposableArchitecture"),
    .external(name: "SharingGRDB")
  ],
  resources: .notPresent
)

// MARK: - Notes module

public let notes = Module(
  feature: .notes,
  dependencies: [
    .target(common.implementationTarget),
    .target(resources.implementationTarget),
    .external(name: "ComposableArchitecture"),
    .external(name: "SharingGRDB")
  ],
  resources: .notPresent
)

// MARK: - App Settings module

public let appSettings = Module(
  feature: .appSettings,
  dependencies: [
    .target(common.implementationTarget),
    .target(resources.implementationTarget),
    .external(name: "ComposableArchitecture")
  ],
  resources: .notPresent
)

// MARK: - Testing Utilities (links XCTest so don't depend on it in app modules)

public let testingUtilities = Module(
  feature: .testingUtilities,
  dependencies: [
    .xctest,
    .external(name: "ComposableArchitecture"),
  ],
  resources: .notPresent
)
