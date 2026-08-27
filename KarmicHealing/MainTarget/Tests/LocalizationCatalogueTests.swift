//
// Karmic Healing 2026
//

import Foundation
import XCTest
@testable import KarmicHealing

/// The phone reads its words from a string catalogue, which Xcode compiles into one `.strings`
/// table per language inside the app. These tests read the built tables rather than the catalogue
/// source, so what they check is what actually ships: every language present, every key answered
/// in every one of them, and every format specifier carried across intact — a translation that
/// drops the `%@` out of "Next step in %@", or reorders `%1$d` and `%2$d`, crashes the screen it
/// is on rather than reading oddly.
final class LocalizationCatalogueTests: XCTestCase {
  /// The languages the app promises. Written out rather than read from the bundle, so that a
  /// language quietly dropped from the catalogue fails here instead of passing unnoticed.
  private let shippedLanguages = [
    "en", "uk", "ru", "es", "pt-BR", "fr", "de", "it", "pl", "tr", "zh-Hans", "ja", "ko", "hi", "bn"
  ]

  private let sourceLanguage = "en"

  func testTheAppShipsEveryLanguageItPromises() throws {
    let bundled = Set(try appBundle().localizations)

    XCTAssertEqual(
      Set(shippedLanguages).subtracting(bundled),
      [],
      "The app ships without languages it promises"
    )
  }

  func testEveryLanguageAnswersEveryKeyTheSourceLanguageDoes() throws {
    let source = try table(for: sourceLanguage)
    XCTAssertFalse(source.isEmpty, "The \(sourceLanguage) table is empty, so nothing is checked")

    for language in shippedLanguages where language != sourceLanguage {
      let translated = try table(for: language)
      let missing = Set(source.keys).subtracting(translated.keys).sorted()

      XCTAssertEqual(missing, [], "\(language) has no words for these keys")
    }
  }

  func testNoTranslationIsBlank() throws {
    for language in shippedLanguages {
      for (key, value) in try table(for: language) {
        XCTAssertFalse(
          value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          "'\(key)' translates to nothing in \(language)"
        )
      }
    }
  }

  /// What has to match is which argument each specifier reaches for and what it reads it as, not
  /// where in the sentence it sits. A numbered specifier names its argument outright, so Korean is
  /// free to say "%2$d단계 중 %1$d단계" and put the total first; an unnumbered one is claimed by its
  /// place in the line, and there moving it does swap the values around.
  func testEveryTranslationReadsTheSameArgumentsTheSameWay() throws {
    let source = try table(for: sourceLanguage)

    for language in shippedLanguages where language != sourceLanguage {
      let translated = try table(for: language)

      for (key, original) in source {
        guard let translation = translated[key] else { continue }

        XCTAssertEqual(
          argumentsRead(by: translation),
          argumentsRead(by: original),
          "'\(key)' in \(language) does not read the arguments of '\(original)' — \(translation)"
        )
      }
    }
  }

  // MARK: - Helpers

  private func appBundle() throws -> Bundle {
    let bundle = Bundle.main

    try XCTSkipUnless(
      bundle.bundleIdentifier == "com.villi.karmichealing",
      """
      These tests read the app's own bundle, but they are running against \
      \(bundle.bundleIdentifier ?? "no bundle") — the test target has lost its host application.
      """
    )

    return bundle
  }

  private func table(for language: String) throws -> [String: String] {
    let bundle = try appBundle()

    let path = try XCTUnwrap(
      bundle.path(
        forResource: "Localizable",
        ofType: "strings",
        inDirectory: nil,
        forLocalization: language
      ),
      "The app carries no Localizable table for \(language)"
    )

    return try XCTUnwrap(
      NSDictionary(contentsOfFile: path) as? [String: String],
      "The \(language) Localizable table is not a table of strings"
    )
  }

  /// Captures the argument number of a numbered specifier, its length modifier, and what it reads
  /// the argument as. Width and precision are left out of the capture: `%.2f` and `%f` reach for
  /// the same argument and read it the same way, and only the reading can crash.
  private static let formatSpecifier = try! NSRegularExpression(
    pattern: #"%(?:(\d+)\$)?[-+ #0]*[\d*]*(?:\.\d+)?(hh|h|ll|l|q|L|z|t|j)?([@dDiuUxXoOfeEgGcCsSpaAF%])"#
  )

  /// Which argument the line reaches for, and what it reads each one as. An unnumbered specifier
  /// takes the next argument in line, which is what makes its position part of its meaning.
  private func argumentsRead(by string: String) -> [Int: String] {
    let range = NSRange(string.startIndex..<string.endIndex, in: string)
    var arguments: [Int: String] = [:]
    var nextUnnumbered = 1

    for match in Self.formatSpecifier.matches(in: string, range: range) {
      let capture = { (index: Int) -> String? in
        Range(match.range(at: index), in: string).map { String(string[$0]) }
      }

      // `%%` is a written percent sign. It reads no argument at all.
      guard let conversion = capture(3), conversion != "%" else { continue }

      let number: Int
      if let numbered = capture(1), let parsed = Int(numbered) {
        number = parsed
      } else {
        number = nextUnnumbered
        nextUnnumbered += 1
      }

      arguments[number] = (capture(2) ?? "") + conversion
    }

    return arguments
  }
}
