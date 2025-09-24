import Foundation

public extension String {
  var loc: String {
    // Use main bundle for iOS (so system knows about supported languages)
    // Resources module will be used for Watch app later
    return String(localized: String.LocalizationValue(self), bundle: .main)
  }
}
