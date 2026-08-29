//
// Karmic Healing 2026
//

import Foundation

/// Which of the app's languages a person has actually read.
///
/// The rest were translated by machine. That is worth saying out loud rather than hiding: the
/// only people who can tell a wrong word from a right one are the ones reading it, and they
/// will only write in if they know the app would welcome hearing from them.
public enum Translation {
  /// The languages the author can vouch for. This is the same list the string catalogue keeps
  /// marked `translated` rather than `needs_review`, and the two are meant to move together —
  /// a language read through by a native speaker is added here at the same time.
  public static let reviewed: Set<String> = ["en", "uk", "ru"]

  /// Whether the words the user is reading came from a machine.
  ///
  /// The language is asked of the bundle rather than of the system: what matters is the one the
  /// app actually fell back to, which is not always the first the user asked for.
  public static var isMachineTranslated: Bool {
    isMachineTranslated(Bundle.main.preferredLocalizations.first)
  }

  public static func isMachineTranslated(_ localization: String?) -> Bool {
    // With no way of telling, the app says nothing: a notice shown against a language somebody
    // did read is worse than a missing one against a language nobody did.
    guard let localization else { return false }
    return !reviewed.contains(languageCode(of: localization))
  }

  /// A regional variant stands or falls with its language: `pt-BR` is reviewed when `pt` is.
  private static func languageCode(of localization: String) -> String {
    Locale(identifier: localization).language.languageCode?.identifier ?? localization
  }
}
