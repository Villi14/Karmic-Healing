//
// Karmic Healing 2025
//

import Foundation

public struct RequestItem: Equatable, Identifiable, Codable {
  public let id: UUID
  public let title: String
  public let description: String
  public var isCompleted: Bool
  public let createdAt: Date
  
  public init(
    id: UUID = UUID(),
    title: String,
    description: String,
    isCompleted: Bool = false,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.isCompleted = isCompleted
    self.createdAt = createdAt
  }
} 