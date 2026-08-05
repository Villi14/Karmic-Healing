//
// Karmic Healing 2025
//

import OSLog

/// Unified logging for the watch app. Mirrors `Common.Log` on iOS — the watch target
/// deliberately depends on no other module, so the type is duplicated rather than shared.
enum Log {
  private static let subsystem = "com.villi.karmichealing.watchkitapp"

  static let app = Logger(subsystem: subsystem, category: "app")
  static let session = Logger(subsystem: subsystem, category: "session")
  static let notifications = Logger(subsystem: subsystem, category: "notifications")
  static let audio = Logger(subsystem: subsystem, category: "audio")
  static let settings = Logger(subsystem: subsystem, category: "settings")
}
