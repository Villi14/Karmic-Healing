//
// Karmic Healing 2025
//

import Foundation
import SQLiteData
import SwiftUI
import XCTest
@testable import Db

/// The colour a request wears lives in the database as a single integer, so the trip out and
/// back has to return the very colour that was picked — a channel lost here is a request that
/// quietly changes colour between launches.
final class ColorHexRepresentationTests: XCTestCase {
  private let sacralBlue: Int64 = 0x4A99_EFFF
  private let amber: Int64 = 0xED89_35FF

  func testHexUnpacksIntoItsFourChannels() {
    let color = Color.HexRepresentation(hexValue: 0x1020_3040).queryOutput

    XCTAssertEqual(Color.HexRepresentation(queryOutput: color).hexValue, 0x1020_3040)
  }

  func testEveryChannelValueSurvivesTheRoundTrip() {
    for channel in stride(from: 0, through: 0xFF, by: 1) {
      let hexValue = Int64(channel) << 24 | Int64(channel) << 16 | Int64(channel) << 8 | 0xFF
      let color = Color.HexRepresentation(hexValue: hexValue).queryOutput

      XCTAssertEqual(
        Color.HexRepresentation(queryOutput: color).hexValue,
        hexValue,
        "Channel \(channel) came back changed"
      )
    }
  }

  func testTheColoursTheAppShipsWithSurviveTheRoundTrip() {
    for hexValue in [sacralBlue, amber, 0x0000_00FF, 0xFFFF_FFFF] as [Int64] {
      let color = Color.HexRepresentation(hexValue: hexValue).queryOutput

      XCTAssertEqual(Color.HexRepresentation(queryOutput: color).hexValue, hexValue)
    }
  }

  func testTransparencyIsCarriedAlongWithTheColour() {
    let halfTransparent = Int64(0x4A99_EF80)
    let color = Color.HexRepresentation(hexValue: halfTransparent).queryOutput

    XCTAssertEqual(Color.HexRepresentation(queryOutput: color).hexValue, halfTransparent)
  }

  /// A grey carries one channel and its alpha rather than three channels, and it used to be
  /// read as though the alpha were its green — reaching past the end of the pair for a blue.
  func testAGreySurvivesInsteadOfTrapping() {
    let grey = Color.HexRepresentation(queryOutput: Color(white: 0.5))

    guard let hexValue = grey.hexValue else {
      return XCTFail("A grey has no colour to store")
    }
    let red = (hexValue >> 24) & 0xFF
    let green = (hexValue >> 16) & 0xFF
    let blue = (hexValue >> 8) & 0xFF
    XCTAssertEqual(red, green, "A grey has to stay grey")
    XCTAssertEqual(green, blue, "A grey has to stay grey")
    XCTAssertEqual(hexValue & 0xFF, 0xFF, "An opaque grey came back transparent")
  }

  // MARK: - Through the database

  func testTheColourOfARequestSurvivesTheDatabase() throws {
    let database = try appDatabase()
    let id = UUID()
    let color = Color.HexRepresentation(hexValue: amber).queryOutput

    try database.write { db in
      try RequestsList.insert { RequestsList(id: id, color: color, title: "Family") }.execute(db)
    }

    let stored = try database.read { try RequestsList.find(id).fetchOne($0) }

    XCTAssertEqual(
      Color.HexRepresentation(queryOutput: try XCTUnwrap(stored).color).hexValue,
      amber
    )
  }

  /// The colour column is an integer, so anything else stored in it is not a colour.
  func testANonIntegerBindingIsNotAColour() {
    XCTAssertNil(Color.HexRepresentation(queryBinding: .text("blue")))
    XCTAssertNil(Color.HexRepresentation(queryBinding: .null))
  }

  func testAColourBindsAsItsInteger() {
    let binding = Color.HexRepresentation(hexValue: sacralBlue).queryBinding

    guard case .int(let hexValue) = binding else {
      return XCTFail("Expected the colour to bind as an integer")
    }
    XCTAssertEqual(hexValue, sacralBlue)
  }
}
