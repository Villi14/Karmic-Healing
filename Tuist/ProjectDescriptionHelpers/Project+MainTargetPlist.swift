import Foundation
@preconcurrency import ProjectDescription

public let bundleShortVersionString: String = "1.2"
public let bundleVersion: String = "0.7"

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
    "UIApplicationSceneManifest": [
      "UIApplicationSupportsMultipleScenes": .boolean(false),
      "UISceneConfigurations": [
        "UIWindowSceneSessionRoleApplication": [
          [
            "UISceneConfigurationName": .string("Default Configuration"),
            "UISceneDelegateClassName": .string("$(PRODUCT_MODULE_NAME).SceneDelegate")
          ]
        ]
      ]
    ],
    "CFBundleName": .string("KarmicHealing"),
    "CFBundleDisplayName": .string("Karmic Healing"),
    "CFBundleShortVersionString": .string(bundleShortVersionString),
    "CFBundleVersion": .string(bundleVersion),
    "LSApplicationCategoryType": .string("public.app-category.lifestyle")
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
    "WKCompanionAppBundleIdentifier": .string("com.villi.karmichealing"),
    "CFBundleDisplayName": .string("Karmic Healing"),
    "CFBundleName": .string("Karmic Healing"),
    "CFBundleShortVersionString": .string(bundleShortVersionString),
    "CFBundleVersion": .string(bundleVersion),
    "LSApplicationCategoryType": .string("public.app-category.lifestyle")
  ]
)