//
// Karmic Healing 2025
//

import OSLog

/// Unified logging for the app. Categories match the areas that used to `print()`:
/// they can be filtered in Console.app and are stripped of arguments in release builds
/// unless a value is marked `privacy: .public`.
public enum Log {
  private static let subsystem = "com.villi.karmichealing"

  public static let app = Logger(subsystem: subsystem, category: "app")
  public static let session = Logger(subsystem: subsystem, category: "session")
  public static let notifications = Logger(subsystem: subsystem, category: "notifications")
  public static let audio = Logger(subsystem: subsystem, category: "audio")
  public static let database = Logger(subsystem: subsystem, category: "database")
}
