import Foundation

public extension String {
  var loc: String {
    return String(localized: String.LocalizationValue(self), bundle: .main)
  }

  /// Localized string with positional arguments, e.g. "step_counter".loc(4, 14).
  func loc(_ arguments: CVarArg...) -> String {
    return String(format: self.loc, arguments: arguments)
  }
}
