//
// Karmic Healing 2025
//

import Foundation
import XCTest
@testable import KarmicHealingWatch

/// The watch translates by hand, from a table keyed by the very strings the screens ask for. A
/// key the table has never heard of is handed back untouched — which puts `part3step18` on the
/// wrist in place of a sentence. These tests are the guard on that.
final class WatchLocalizationTests: XCTestCase {
  /// The three the settings screen offers.
  private let offeredLanguages = ["en", "uk", "ru"]

  /// Every word the screens ask for by hand, next to what the steps ask for.
  private let interfaceKeys = [
    "essential_self", "divine_self", "settings", "sound", "duration", "language",
    "min", "paused", "pause", "resume", "en", "uk", "ru"
  ]

  /// The abbreviation is its own English word, so here the translation matching the key is the
  /// translation rather than a missing entry.
  private let keysThatAreTheirOwnEnglishWord: Set<String> = ["min"]

  func testEveryStepOfEveryPartIsTranslatedIntoEveryLanguage() {
    for step in Step.part2 + Step.part3 {
      assertTranslated(step.title)
      if !step.description.isEmpty {
        assertTranslated(step.description)
      }
    }
  }

  func testEveryWordTheScreensAskForIsTranslatedIntoEveryLanguage() {
    for key in interfaceKeys {
      assertTranslated(key)
    }
  }

  /// The picker lists the languages in each other's words, so each name has to be there in all
  /// three — including its own.
  func testEachLanguageNamesItselfAndTheOthers() {
    XCTAssertEqual("en".localized(for: Locale(identifier: "en")), "English")
    XCTAssertEqual("uk".localized(for: Locale(identifier: "uk")), "Українська")
    XCTAssertEqual("ru".localized(for: Locale(identifier: "ru")), "Русский")
    XCTAssertEqual("uk".localized(for: Locale(identifier: "en")), "Ukrainian")
  }

  /// The stored language is a bare code, but a locale can arrive carrying a region — it is the
  /// language in it that decides the words.
  func testARegionOnTheLocaleDoesNotChangeTheWords() {
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

  /// Every language the settings picker lists has to be a language the table actually speaks.
  func testEveryLanguageThePickerOffersIsTranslated() {
    for identifier in WatchSettingsView.supportedLanguages {
      let locale = Locale(identifier: identifier)
      XCTAssertNotEqual(
        "settings".localized(for: locale),
        "settings",
        "The picker offers \(identifier) but the table has no words for it"
      )
    }
  }

  // MARK: - Helpers

  private func assertTranslated(
    _ key: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    for language in offeredLanguages {
      let translation = key.localized(for: Locale(identifier: language))
      if !(language == "en" && keysThatAreTheirOwnEnglishWord.contains(key)) {
        XCTAssertNotEqual(
          translation,
          key,
          "'\(key)' has no \(language) translation, so the key itself would be shown",
          file: file,
          line: line
        )
      }
      XCTAssertFalse(
        translation.isEmpty,
        "'\(key)' translates to nothing in \(language)",
        file: file,
        line: line
      )
    }
  }
}
