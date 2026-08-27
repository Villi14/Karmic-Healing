//
// Karmic Healing 2026
//

import Foundation
import XCTest
@testable import KarmicHealingWatch

/// The watch translates by hand, from `WatchTranslations.table` keyed by the very strings the
/// screens ask for. A key the table has never heard of is handed back untouched — which puts
/// `part3step18` on the wrist in place of a sentence. These tests are the guard on that.
///
/// The languages come from the settings picker rather than from a list written here, so a language
/// added to the picker is a language these tests immediately demand words for.
final class WatchLocalizationTests: XCTestCase {
  /// In the identifiers the picker offers them under — `pt-BR` and `zh-Hans` carry a region and a
  /// script, which the table, keyed by bare language, does not.
  private var offeredLanguages: [String] { WatchSettingsView.supportedLanguages }

  /// Every word the screens ask for by hand.
  private let interfaceKeys = [
    "essential_self", "divine_self", "settings", "sound", "duration", "language",
    "min", "paused", "pause", "resume"
  ]

  /// Every word the steps ask for, titles and the one description among them.
  private var stepKeys: [String] {
    (Step.part2 + Step.part3).flatMap { step in
      step.description.isEmpty ? [step.title] : [step.title, step.description]
    }
  }

  private var keysTheAppAsksFor: Set<String> {
    Set(interfaceKeys).union(stepKeys)
  }

  /// The whole point of the table. Asking the table directly rather than reading meaning into what
  /// comes back, because a handful of words — `min` in Spanish, in French, in Italian — are their
  /// own English spelling, and a translation equal to its key is not evidence of a missing one.
  func testEveryKeyTheAppAsksForIsTranslatedIntoEveryOfferedLanguage() {
    for key in keysTheAppAsksFor.sorted() {
      guard let entry = WatchTranslations.table[key] else {
        XCTFail("The screens ask for '\(key)' but the table has never heard of it")
        continue
      }

      for identifier in offeredLanguages {
        let locale = Locale(identifier: identifier)
        let languageCode = locale.language.languageCode?.identifier ?? identifier

        guard let translation = entry[languageCode] else {
          XCTFail("'\(key)' has no \(identifier) translation, so the key itself would be shown")
          continue
        }

        XCTAssertFalse(translation.isEmpty, "'\(key)' translates to nothing in \(identifier)")
        XCTAssertEqual(
          key.localized(for: locale),
          translation,
          "'\(key)' does not reach its \(identifier) translation"
        )
      }
    }
  }

  /// The other direction: an entry nothing asks for is a word that was renamed or dropped on the
  /// screens and left behind here, and it quietly carries the cost of translating it again.
  func testTheTableHoldsNothingTheAppNeverAsksFor() {
    XCTAssertEqual(
      Set(WatchTranslations.table.keys).subtracting(keysTheAppAsksFor),
      [],
      "The table translates words no screen and no step asks for"
    )
  }

  /// The picker offers `pt-BR` and `zh-Hans`, the table is keyed `pt` and `zh`, and only the
  /// language part of the locale bridges them. Storage can also hand back a locale carrying a
  /// region of its own.
  func testARegionOrScriptOnTheLocaleDoesNotChangeTheWords() {
    XCTAssertEqual(
      "settings".localized(for: Locale(identifier: "pt-BR")),
      "settings".localized(for: Locale(identifier: "pt"))
    )
    XCTAssertEqual(
      "settings".localized(for: Locale(identifier: "zh-Hans")),
      "settings".localized(for: Locale(identifier: "zh"))
    )
    XCTAssertEqual(
      "settings".localized(for: Locale(identifier: "uk_UA")),
      "settings".localized(for: Locale(identifier: "uk"))
    )
    XCTAssertEqual("settings".localized(for: Locale(identifier: "en_GB")), "Settings")
  }

  func testAKeyTheTableNeverHeardOfIsHandedBackUntouched() {
    XCTAssertEqual("part3step18".localized(for: Locale(identifier: "uk")), "part3step18")
    XCTAssertEqual("".localized(for: Locale(identifier: "en")), "")
  }

  /// Only the offered languages are translated, and any other falls through to the key rather
  /// than to English. The settings screen never offers one, so nothing reaches this — but a
  /// language written into storage from elsewhere would.
  func testALanguageOutsideTheOfferedOnesFallsThroughToTheKey() {
    XCTAssertEqual("settings".localized(for: Locale(identifier: "sv")), "settings")
  }

  /// The picker lists each language in its own words, through `Locale` rather than a table of
  /// names. What matters is that every offered identifier is one `Locale` can actually name, and
  /// that no two rows come out reading the same.
  func testEachOfferedLanguageIsNamedInItsOwnWords() {
    let names = offeredLanguages.map(WatchSettingsView.languageName)

    for (identifier, name) in zip(offeredLanguages, names) {
      XCTAssertFalse(name.isEmpty, "\(identifier) is offered under no name at all")
      XCTAssertNotEqual(
        name,
        identifier,
        "Locale cannot name \(identifier), so the picker would show the bare code"
      )
    }

    XCTAssertEqual(
      Set(names).count,
      names.count,
      "Two languages are offered under the same name: \(names)"
    )
  }

  func testALanguageIsNamedInItsOwnWordsAndCapitalised() {
    XCTAssertEqual(WatchSettingsView.languageName("en"), "English")
    XCTAssertEqual(WatchSettingsView.languageName("uk"), "Українська")
  }
}
