@preconcurrency import ProjectDescription
import ProjectDescriptionHelpers

let appName = "KarmicHealing"

let mainTarget = Target.target(
  name: appName,
  destinations: [.iPhone, .iPad],
  product: .app,
  bundleId: "home.KarmicHealing",
  deploymentTargets: iosDeploymentTargets,
  infoPlist: mainTargetPlist,
  sources: [
    "KarmicHealing/MainTarget/Sources/**",
  ],
  resources: [
    "KarmicHealing/MainTarget/Resources/**",
  ],
  dependencies: [
    .target(home.implementationTarget),
    .target(common.implementationTarget),
    .target(onboarding.implementationTarget),
    .target(requests.implementationTarget),
    .target(balancingEnergyList.implementationTarget),
    .target(balancingEnergy.implementationTarget),
    .external(name: "ComposableArchitecture")
  ],
  settings: .settings(
    base: [
      "CFBundleName": .string("KarmicHealing"),
      "CFBundleDisplayName": .string("Karmic Healing"),
      "CODE_SIGN_STYLE": "Manual",
      "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
      "ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES": .array(["AppIcon"]),
      "ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS": "YES"
    ]
  )
)

let project = Project(
  name: appName,
  organizationName: "home",
  settings: nil,
  targets: .all(
    [mainTarget],
    common.targets,
    home.targets,
    appSettings.targets,
    onboarding.targets,
    requests.targets,
    balancingEnergyList.targets,
    balancingEnergy.targets,
    resources.targets,
    testingUtilities.targets
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


