//
// Karmic Healing 2025
//

import Foundation
import struct CoreMedia.CMTime

/// Extensions for `CMTime` to write more cleaner code for tests.
extension CMTime: @retroactive ExpressibleByFloatLiteral {
  public typealias FloatLiteralType = TimeInterval

  public init(floatLiteral value: Self.FloatLiteralType) {
    self.init(seconds: value, preferredTimescale: 600)
  }
}

extension CMTime: @retroactive ExpressibleByIntegerLiteral {
  public typealias IntegerLiteralType = Int

  public init(integerLiteral value: Int) {
    self = .init(floatLiteral: TimeInterval(value))
  }
}
