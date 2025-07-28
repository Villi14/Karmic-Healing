// swift-tools-version: 6.0
@preconcurrency import PackageDescription

#if TUIST
@preconcurrency import ProjectDescription
import ProjectDescriptionHelpers

let packageSettings = PackageSettings(
  productTypes: [
    "ComposableArchitecture": .framework,
    "SharingGRDB": .framework,
    "Dependencies": .framework,
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
  ]
)

#endif

let package = Package(
  name: "KarmicHealingDependencies",
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.19.1"),
    .package(url: "https://github.com/pointfreeco/sharing-grdb.git", from: "0.4.1"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.18.3")
  ]
)
