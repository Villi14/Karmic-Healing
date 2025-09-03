import Foundation

public extension String {
  func loc() -> String {
    String(localized: String.LocalizationValue(self), bundle: .main)
  }
}
