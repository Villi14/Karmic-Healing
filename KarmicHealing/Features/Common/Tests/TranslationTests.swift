//
// Karmic Healing 2026
//

import XCTest
@testable import Common

/// Who the app apologises to for its words.
///
/// Both mistakes here are quiet ones: an apology shown against a language somebody did read
/// makes the app look careless, and a missing one leaves a reader assuming the odd phrasing
/// was meant.
final class TranslationTests: XCTestCase {
  func testTheLanguagesTheAuthorCanVouchForAreNotApologisedFor() {
    for language in Translation.reviewed {
      XCTAssertFalse(Translation.isMachineTranslated(language), "\(language) was apologised for")
    }
  }

  func testEveryOtherLanguageIsOwnedUpTo() {
    for language in ["de", "es", "fr", "it", "ja", "ko", "pl", "pt-BR", "tr", "zh-Hans", "hi", "bn"] {
      XCTAssertTrue(Translation.isMachineTranslated(language), "\(language) passed itself off as read")
    }
  }

  /// A region says nothing about who read the words: Brazilian Portuguese is the Portuguese in
  /// the catalogue, and Austrian German is the German.
  func testARegionalVariantIsJudgedByItsLanguage() {
    XCTAssertFalse(Translation.isMachineTranslated("en-GB"))
    XCTAssertFalse(Translation.isMachineTranslated("uk-UA"))
    XCTAssertTrue(Translation.isMachineTranslated("de-AT"))
  }

  /// Written out rather than counted, so that adding a language to the reviewed list is a
  /// deliberate act with a test to change alongside it.
  func testOnlyThreeLanguagesHaveBeenRead() {
    XCTAssertEqual(Translation.reviewed, ["en", "uk", "ru"])
  }

  func testAnAppThatCannotTellWhatItIsSpeakingSaysNothing() {
    XCTAssertFalse(Translation.isMachineTranslated(nil))
  }
}
