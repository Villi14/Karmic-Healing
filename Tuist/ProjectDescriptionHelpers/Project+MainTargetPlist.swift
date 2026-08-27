import Foundation
@preconcurrency import ProjectDescription

public let bundleShortVersionString: String = "1.6"
public let bundleVersion: String = "16"
public let bundleDisplayName: String = "Karmic Healing"
public let applicationCategory: String = "public.app-category.lifestyle"

/// Xcode's General tab reads these from build settings, not from a literal Info.plist, so both app
/// targets carry them and the plists below just reference the settings.
public let appInfoSettings: SettingsDictionary = [
  "MARKETING_VERSION": .string(bundleShortVersionString),
  "CURRENT_PROJECT_VERSION": .string(bundleVersion),
  "INFOPLIST_KEY_CFBundleDisplayName": .string(bundleDisplayName),
  "INFOPLIST_KEY_LSApplicationCategoryType": .string(applicationCategory),
]

public let mainTargetPlist: InfoPlist = .extendingDefault(
  with: [
    "UILaunchStoryboardName": .string("LaunchScreen.storyboard"),
    "UISupportedInterfaceOrientations": [
      .string("UIInterfaceOrientationPortrait"),
    ],
    "UISupportedInterfaceOrientations~ipad": [
      .string("UIInterfaceOrientationPortrait"),
      .string("UIInterfaceOrientationLandscapeLeft"),
      .string("UIInterfaceOrientationLandscapeRight")
    ],
    "UIRequiresFullScreen": .boolean(true),
    "CFBundleName": .string("KarmicHealing"),
    "CFBundleDisplayName": .string("$(INFOPLIST_KEY_CFBundleDisplayName)"),
    "NSFaceIDUsageDescription": .string("Face ID protects access to your Karmic Healing information."),
    "CFBundleShortVersionString": .string("$(MARKETING_VERSION)"),
    "CFBundleVersion": .string("$(CURRENT_PROJECT_VERSION)"),
    "LSApplicationCategoryType": .string("$(INFOPLIST_KEY_LSApplicationCategoryType)")
  ]
)

public let watchAppTargetPlist: InfoPlist = .extendingDefault(
  with: [
    "UISupportedInterfaceOrientations": [
      .string("UIInterfaceOrientationPortrait"), 
    ],
    "WKSupportedInterfaceOrientations": [
      .string("WKInterfaceOrientationPortrait")
    ],
    "CFBundleIdentifier": .string("com.villi.karmichealing.watchkitapp"),
    "CFBundleExecutable": .string("KarmicHealingWatch"),
    "CFBundlePackageType": .string("APPL"),
    "WKApplication": .boolean(true),
    // Lets a meditation hold an extended runtime session, so the app keeps chiming and vibrating
    // through a step even with the wrist down.
    "WKBackgroundModes": [
      .string("mindfulness")
    ],
    "WKCompanionAppBundleIdentifier": .string("com.villi.karmichealing"),
    "CFBundleDisplayName": .string("$(INFOPLIST_KEY_CFBundleDisplayName)"),
    "CFBundleName": .string("$(INFOPLIST_KEY_CFBundleDisplayName)"),
    "CFBundleShortVersionString": .string("$(MARKETING_VERSION)"),
    "CFBundleVersion": .string("$(CURRENT_PROJECT_VERSION)"),
    "LSApplicationCategoryType": .string("$(INFOPLIST_KEY_LSApplicationCategoryType)")
  ]
)
