// Karmic Healing 2025

import SQLiteData
import SwiftUI

extension Color {
  public struct HexRepresentation: QueryRepresentable {
    public var queryOutput: Color
    public init(queryOutput: Color) {
      self.queryOutput = queryOutput
    }
    public init(hexValue: Int64) {
      self.init(
        queryOutput: Color(
          red: Double((hexValue >> 24) & 0xFF) / 0xFF,
          green: Double((hexValue >> 16) & 0xFF) / 0xFF,
          blue: Double((hexValue >> 8) & 0xFF) / 0xFF,
          opacity: Double(hexValue & 0xFF) / 0xFF
        )
      )
    }
    public var hexValue: Int64? {
      guard let components = UIColor(queryOutput).cgColor.components, !components.isEmpty
      else { return nil }
      // A grey arrives as a single channel and its alpha, not as three channels, so that one
      // channel stands for all three — reaching for a green and a blue that are not there
      // would trap.
      let isGrey = components.count < 3
      let red = components[0]
      let green = isGrey ? components[0] : components[1]
      let blue = isGrey ? components[0] : components[2]
      let alpha: CGFloat =
      switch components.count {
      case 2: components[1]
      case 4...: components[3]
      default: 1
      }

      // Each channel comes back as a fraction that a single-precision trip has already nudged
      // just below where it started, so cutting the remainder off loses a shade on every save —
      // a colour saved twice is a colour that has quietly darkened.
      let r = Int64((red * 0xFF).rounded()) << 24
      let g = Int64((green * 0xFF).rounded()) << 16
      let b = Int64((blue * 0xFF).rounded()) << 8
      let a = Int64((alpha * 0xFF).rounded())
      return r | g | b | a
    }
  }
}

extension Color.HexRepresentation: QueryBindable {
  public init?(queryBinding: StructuredQueriesCore.QueryBinding) {
    guard case .int(let hexValue) = queryBinding else { return nil }
    self.init(hexValue: hexValue)
  }
  public var queryBinding: QueryBinding {
    guard let hexValue else {
      struct InvalidColor: Error {}
      return .invalid(InvalidColor())
    }
    return .int(hexValue)
  }
}

extension Color.HexRepresentation: QueryDecodable {
  public init(decoder: inout some QueryDecoder) throws {
    try self.init(hexValue: Int64(decoder: &decoder))
  }
}
