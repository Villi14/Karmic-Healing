import Foundation
@preconcurrency import ProjectDescription

public let iosDeploymentTargets = DeploymentTargets.iOS("17.4")

public enum Feature: String {
  case common
  case resources
  case onboarding
  case home
  case balancingEnergyList
  case balancingEnergy
  case requests
  case notes
  case appSettings
  case testingUtilities
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
    self.implementationTarget = .target(
      name: feature.rawValue.firstLetterCapitalized,
      destinations: [.iPhone],
      product: .framework,
      bundleId: "home.KarmicHealing.\(feature.rawValue)",
      deploymentTargets: iosDeploymentTargets,
      infoPlist: .default,
      sources: hasSources
        ? ["KarmicHealing/Features/\(feature.rawValue.firstLetterCapitalized)/Sources/**"]
        : nil,
      resources: resources.resolved(feature: feature),
      dependencies: dependencies
    )

    switch unitTests {
    case .present(let dependencies):
      self.unitTestsTarget = .target(
        name: "\(feature.rawValue.firstLetterCapitalized)Tests",
        destinations: [.iPhone],
        product: .unitTests,
        bundleId: "home.KarmicHealing.\(feature.rawValue).tests",
        deploymentTargets: iosDeploymentTargets,
        infoPlist: .default,
        sources: [
          "KarmicHealing/Features/\(feature.rawValue.firstLetterCapitalized)/Tests/**",
        ],
        dependencies: dependencies + [.target(self.implementationTarget)]
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
