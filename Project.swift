@preconcurrency import ProjectDescription
import ProjectDescriptionHelpers

let appName = "KarmicHealing"

// MARK: - Watch App Target

let watchAppTarget = Target.target(
  name: "KarmicHealingWatch",
  destinations: [.appleWatch],
  product: .app,
  bundleId: "com.villi.karmichealing.watchkitapp",
  deploymentTargets: watchOSDeploymentTargets,
  infoPlist: watchAppTargetPlist,
  sources: [
    "KarmicHealing/Features/WatchApp/Sources/**",
  ],
  resources: [
    // Assets.xcassets nests its own catalogs, so a recursive glob would add them twice.
    .glob(
      pattern: "KarmicHealing/Features/WatchApp/Resources/**",
      excluding: ["KarmicHealing/Features/WatchApp/Resources/Assets.xcassets/**"]
    ),
    "KarmicHealing/Features/WatchApp/Resources/Assets.xcassets",
  ],
  dependencies: [
    .external(name: "ComposableArchitecture"),
    .external(name: "Dependencies"),
    .external(name: "ConcurrencyExtras")
  ],
  settings: .settings(
    base: appInfoSettings.merging([
      "ENABLE_BITCODE": "NO",
      "CODE_SIGN_STYLE": "Manual",
      "DEVELOPMENT_TEAM": "KG394T5RF5",
      // For simulators we use arm64
      "ARCHS[sdk=watchsimulator*]": "arm64",
      "VALID_ARCHS[sdk=watchsimulator*]": "arm64",
      // For physical devices we use arm64_32 (Series 6) and arm64 (Series 8+)
      "ARCHS[sdk=watchos*]": "arm64_32 arm64",
      "VALID_ARCHS[sdk=watchos*]": "arm64_32 arm64",
      // Avoid symbol conflicts between iPhone and Watch
      "DEAD_CODE_STRIPPING": "YES",
      "STRIP_INSTALLED_PRODUCT": "YES",
      "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "SWIFT_PACKAGE",
      "SWIFT_DISABLE_SAFETY_CHECKS": "YES",
    ]) { _, new in new },
    debug: [
      "CODE_SIGN_IDENTITY": "Apple Development: Alexander  Velikotsky (R7UR2DF94C)",
      "PROVISIONING_PROFILE_SPECIFIER": "karmic_healing_watch_dev"
    ],
    release: [
      "CODE_SIGN_IDENTITY": "Apple Distribution: Alexander  Velikotsky (KG394T5RF5)",
      "PROVISIONING_PROFILE_SPECIFIER": "karmic_healing_watch_distr"
    ]
  )
)

// MARK: - Main Target

let mainTarget = Target.target(
  name: appName,
  destinations: [.iPhone, .iPad],
  product: .app,
  bundleId: "com.villi.karmichealing",
  deploymentTargets: iosDeploymentTargets,
  infoPlist: mainTargetPlist,
  sources: [
    "KarmicHealing/MainTarget/Sources/**",
  ],
  resources: [
    "KarmicHealing/MainTarget/Resources/**",
  ],
  dependencies: [
    .target(common.implementationTarget),
    .target(resources.implementationTarget),
    .target(onboarding.implementationTarget),
    .target(home.implementationTarget),
    .target(db.implementationTarget),
    .target(balancingEnergyList.implementationTarget),
    .target(balancingEnergy.implementationTarget),
    .target(appSettings.implementationTarget),
    .target(watchAppTarget),
    .external(name: "ComposableArchitecture")
  ],
  settings: .settings(
    base: appInfoSettings.merging([
      "CFBundleName": .string("KarmicHealing"),
      "CODE_SIGN_STYLE": "Manual",
      "WK_COMPANION_APP_BUNDLE_IDENTIFIER": "com.villi.karmichealing.watchkitapp",
      "WK_WATCHKIT_APP": "YES",
      "WK_APP_BUNDLE_IDENTIFIER": "com.villi.karmichealing.watchkitapp",
      "WK_APP_NAME": .string(bundleDisplayName),
      "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
      "ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES": .array(["AppIcon"]),
      "ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS": "YES",
      "DEVELOPMENT_TEAM": "KG394T5RF5",
      // Avoid symbol conflicts with Watch app
      "DEAD_CODE_STRIPPING": "YES",
      "STRIP_INSTALLED_PRODUCT": "YES"
    ]) { _, new in new },
    debug: [
      "PROVISIONING_PROFILE_SPECIFIER": "karmic_healing_dev",
      "CODE_SIGN_IDENTITY": "Apple Development: Alexander  Velikotsky (R7UR2DF94C)",
    ],
    release: [
      "PROVISIONING_PROFILE_SPECIFIER": "karmic_healing_distr",
      "CODE_SIGN_IDENTITY": "Apple Distribution: Alexander  Velikotsky (KG394T5RF5)",
    ]
  )
)

// MARK: - Test Targets for the app targets

let mainTestsTarget = Target.target(
  name: "\(appName)Tests",
  destinations: [.iPhone, .iPad],
  product: .unitTests,
  bundleId: "com.villi.karmichealing.tests",
  deploymentTargets: iosDeploymentTargets,
  infoPlist: .default,
  sources: [
    "KarmicHealing/MainTarget/Tests/**",
  ],
  dependencies: [
    .target(mainTarget),
    .target(testingUtilities.implementationTarget),
    .external(name: "ComposableArchitecture")
  ],
  settings: .settings(
    base: [
      "DEVELOPMENT_TEAM": "KG394T5RF5"
    ]
  )
)

let watchAppTestsTarget = Target.target(
  name: "KarmicHealingWatchTests",
  destinations: [.appleWatch],
  product: .unitTests,
  bundleId: "com.villi.karmichealing.watchkitapp.tests",
  deploymentTargets: watchOSDeploymentTargets,
  infoPlist: .default,
  sources: [
    "KarmicHealing/Features/WatchApp/Tests/**",
  ],
  dependencies: [
    .target(watchAppTarget),
    .external(name: "ComposableArchitecture")
  ],
  settings: .settings(
    base: [
      "DEVELOPMENT_TEAM": "KG394T5RF5",
      "ARCHS[sdk=watchsimulator*]": "arm64",
      "VALID_ARCHS[sdk=watchsimulator*]": "arm64"
    ]
  )
)

// Feature unit tests need an application to be hosted by: unhosted (library) test
// bundles crash on launch on recent simulator runtimes.
let featureTargets: [Target] = Array.all(
  common.targets,
  resources.targets,
  onboarding.targets,
  home.targets,
  db.targets,
  balancingEnergyList.targets,
  balancingEnergy.targets,
  appSettings.targets,
  testingUtilities.targets
)
.map { target in
  guard target.product == .unitTests else { return target }
  var hostedTarget = target
  hostedTarget.dependencies.append(.target(mainTarget))
  return hostedTarget
}

let project = Project(
  name: appName,
  organizationName: "home",
  targets: .all(
    [mainTarget, mainTestsTarget, watchAppTarget, watchAppTestsTarget],
    featureTargets
  ),
  fileHeaderTemplate: .string("Karmic Healing ___YEAR___"),
  additionalFiles: [
    "Preview Content"
  ]
)

extension Array {
  static func all(_ elements: [Element]...) -> Array<Element> {
    elements.flatMap { $0 }
  }
}


