import Foundation

public extension String {
  var loc: String {
    return String(localized: String.LocalizationValue(self), bundle: .main)
  }
}
