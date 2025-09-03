import Foundation

public extension String {
  var localized: String {
    NSLocalizedString(self, comment: "")
  }
  
  /// Локалізація з bundle .main
  func localized() -> String {
    String(localized: self, bundle: .main)
  }
}
