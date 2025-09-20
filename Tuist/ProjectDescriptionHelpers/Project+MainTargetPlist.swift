import Foundation
@preconcurrency import ProjectDescription

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
    "CFBundleDisplayName": .string("Karmic Healing"),
    "CFBundleShortVersionString": .string("0.1"),
    "CFBundleVersion": .string("0.1"),
  ]
)
