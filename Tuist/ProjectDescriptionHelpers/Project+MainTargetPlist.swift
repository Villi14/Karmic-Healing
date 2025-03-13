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
    ],
    "UIRequiresFullScreen": .boolean(true),
    "CFBundleName": .string("KarmicHealing"),
    "CFBundleDisplayName": .string("Karmic Healing"),
    "CFBundleShortVersionString": .string("0.0.1"),
  ]
)
