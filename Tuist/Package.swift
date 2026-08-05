// swift-tools-version: 6.0
@preconcurrency import PackageDescription

#if TUIST
@preconcurrency import ProjectDescription
import ProjectDescriptionHelpers

// Package settings optimized for both iOS and watchOS
let packageSettings = PackageSettings(
  productTypes: [
    "ComposableArchitecture": .framework,
    "SQLiteData": .framework,
    // Must stay dynamic: a statically linked GRDB ends up duplicated in the test
    // bundles, and its per-thread scheduling state stops matching the database queue.
    "GRDB": .framework,
    "Dependencies": .framework,
    // Linked by both ComposableArchitecture and Dependencies: leaving it static
    // copies the clock types, and their global state, into each framework.
    "Clocks": .framework,
    "ConcurrencyExtras": .framework,
    "IssueReporting": .framework,
    "XCTestDynamicOverlay": .framework,
    "CombineSchedulers": .framework,
    "IdentifiedCollections": .framework,
    "Sharing": .framework,
    "PerceptionCore": .framework,
    "CustomDump": .framework,
    "OrderedCollections": .framework,
    "InternalCollectionsUtilities": .framework,
  ],
  // The watch app and its package dependencies must use the same simulator architecture.
  // Without this, the embedded watch target can ask package frameworks for x86_64 while the
  // app target is arm64-only, which fails at link time on Apple Silicon hosts.
  baseSettings: .settings(base: [
    "ARCHS[sdk=watchsimulator*]": "arm64",
    "VALID_ARCHS[sdk=watchsimulator*]": "arm64",
  ])
)

#endif

let package = Package(
  name: "KarmicHealingDependencies",
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", exact: "1.26.1"),
    .package(url: "https://github.com/pointfreeco/swift-navigation.git", exact: "2.10.3"),
    .package(url: "https://github.com/pointfreeco/sqlite-data.git", exact: "1.8.0"),
    // Pinned below 1.13.0: newer versions gate `Clocks` behind a package trait,
    // which Tuist 4.29 ignores, breaking ComposableArchitecture's re-export.
    .package(url: "https://github.com/pointfreeco/swift-dependencies.git", exact: "1.12.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", exact: "1.18.4")
  ]
)
