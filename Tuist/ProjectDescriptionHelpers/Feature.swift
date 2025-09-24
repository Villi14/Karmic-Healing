import Foundation
@preconcurrency import ProjectDescription

public let iosDeploymentTargets = DeploymentTargets.iOS("18.0")
public let watchOSDeploymentTargets = DeploymentTargets.watchOS("11.0")

public enum Feature: String {
  case common
  case resources
  case watchModule
  case onboarding
  case home
  case balancingEnergyList
  case balancingEnergy
  case db
  case appSettings
  case testingUtilities
  case watchApp
}

public struct Module: Sendable {
  public let implementationTarget: Target
  public let unitTestsTarget: Target?

  public var targets: [Target] {
    [implementationTarget, unitTestsTarget].compactMap { $0 }
  }

  public init(
    feature: Feature,
    dependencies: [TargetDependency],
    resources: Resources,
    hasSources: Bool = true,
    unitTests: UnitTests = .notPresent
  ) {
    let destinations: Set<Destination> = [.iPhone]
    let deploymentTargets: DeploymentTargets = iosDeploymentTargets
    
    let sources: SourceFilesList? = hasSources 
      ? ["KarmicHealing/Features/\(feature.rawValue.firstLetterCapitalized)/Sources/**"]
      : nil
    
    let settings: Settings? = nil
    
    self.init(
      feature: feature,
      dependencies: dependencies,
      resources: resources,
      hasSources: hasSources,
      unitTests: unitTests,
      destinations: destinations,
      deploymentTargets: deploymentTargets,
      sources: sources,
      settings: settings
    )
  }

  private init(
    feature: Feature,
    dependencies: [TargetDependency],
    resources: Resources,
    hasSources: Bool,
    unitTests: UnitTests,
    destinations: Set<Destination>,
    deploymentTargets: DeploymentTargets,
    sources: SourceFilesList?,
    settings: Settings?
  ) {
    
    self.implementationTarget = .target(
      name: feature.rawValue.firstLetterCapitalized,
      destinations: destinations,
      product: .framework,
      bundleId: "com.villi.karmichealing.\(feature.rawValue)",
      deploymentTargets: deploymentTargets,
      infoPlist: .default,
      sources: sources,
      resources: resources.resolved(feature: feature),
      dependencies: dependencies,
      settings: settings
    )

    switch unitTests {
    case .present(let dependencies):
      self.unitTestsTarget = .target(
        name: "\(feature.rawValue.firstLetterCapitalized)Tests",
        destinations: [.iPhone],
        product: .unitTests,
        bundleId: "com.villi.karmichealing.\(feature.rawValue).tests",
        deploymentTargets: iosDeploymentTargets,
        infoPlist: .default,
        sources: [
          "KarmicHealing/Features/\(feature.rawValue.firstLetterCapitalized)/Tests/**",
        ],
        dependencies: dependencies + [.target(self.implementationTarget)],
        settings: .settings(
          base: [
            "DEVELOPMENT_TEAM": "KG394T5RF5"
          ]
        )
      )
    case .notPresent:
      self.unitTestsTarget = nil
    }
  }

  public enum UnitTests {
    case notPresent
    /// Extra dependencies, **excluding the implementation target**
    case present(dependencies: [TargetDependency])
  }

  public enum Resources {
    case notPresent
    /// Resources are located under `Features/[FEATURE_NAME]/Resources/**`
    case present
    /// Resources are located under custom path(s)
    case custom(ResourceFileElements)

    fileprivate func resolved(feature: Feature) -> ResourceFileElements? {
      switch self {
      case .notPresent:
        return nil
      case .present:
        return ["KarmicHealing/Features/\(feature.rawValue.firstLetterCapitalized)/Resources/**"]
      case .custom(let resourceFileElements):
        return resourceFileElements
      }
    }
  }
}

extension String {
  fileprivate var firstLetterCapitalized: String {
    guard let firstLetter = self.first else {
      return self
    }
    return firstLetter.uppercased() + self.dropFirst()
  }
}
