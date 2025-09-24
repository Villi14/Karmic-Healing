// Karmic Healing 2025

import Foundation

public struct Step: Equatable {
  public let title: String
  public let description: String

  public init(title: String, description: String = "") {
    self.title = title
    self.description = description
  }
}
