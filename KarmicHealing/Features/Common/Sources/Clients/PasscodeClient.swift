//
// Karmic Healing 2026
//

import CryptoKit
import Dependencies
import Foundation
import Security

extension DependencyValues {
  public var passcode: PasscodeClient {
    get { self[PasscodeClient.self] }
    set { self[PasscodeClient.self] = newValue }
  }
}

/// The code that opens the app when biometrics cannot.
///
/// iOS keeps the device passcode to itself — an app can ask the system to check it, but never
/// sees it and so cannot check it against digits typed on a keypad of our own. This code is
/// therefore the app's own, kept in the keychain, and only ever stored as a salted digest: what
/// the app holds is enough to recognise the right code, never enough to read it back.
public struct PasscodeClient: Sendable {
  /// Whether the user has set a code at all.
  public var isSet: @Sendable () -> Bool
  /// Replaces whatever code was there.
  public var save: @Sendable (String) -> Void
  /// True only when `code` is the code that was saved.
  public var verify: @Sendable (String) -> Bool
  /// Forgets the code, leaving the app to biometrics alone.
  public var clear: @Sendable () -> Void

  public init(
    isSet: @escaping @Sendable () -> Bool,
    save: @escaping @Sendable (String) -> Void,
    verify: @escaping @Sendable (String) -> Bool,
    clear: @escaping @Sendable () -> Void
  ) {
    self.isSet = isSet
    self.save = save
    self.verify = verify
    self.clear = clear
  }

  /// Digits in a code. Four, as on the system's own lock screen — short enough to type without
  /// looking, and it is a second door behind biometrics rather than the only one.
  public static let length = 4
}

extension PasscodeClient: DependencyKey {
  public static let liveValue = PasscodeClient.keychain()
  public static var testValue: PasscodeClient { .inMemory() }
  public static var previewValue: PasscodeClient { .inMemory() }

  /// Backed by the keychain, which survives a reinstall of the app but never leaves the device
  /// and is never written to a backup.
  public static func keychain(
    account: String = "app_lock_passcode",
    service: String = "com.villi.karmichealing.passcode"
  ) -> PasscodeClient {
    let store = KeychainDigestStore(account: account, service: service)
    return .init(store: store)
  }

  /// The same behaviour without the keychain, for tests and previews.
  public static func inMemory() -> PasscodeClient {
    .init(store: InMemoryDigestStore())
  }

  private init(store: some PasscodeDigestStore) {
    self.init(
      isSet: { store.read() != nil },
      save: { code in store.write(PasscodeDigest(code: code)) },
      verify: { code in store.read()?.matches(code) ?? false },
      clear: { store.delete() }
    )
  }
}

// MARK: - The digest

/// A code as it is stored: random salt, and the hash of that salt and the code together.
///
/// The salt is what makes the digest worth storing. Four digits are ten thousand possibilities,
/// so an unsalted hash is a lookup away from the code itself; a fresh salt per code means the
/// table would have to be built again for every device it is read from.
struct PasscodeDigest: Codable, Equatable, Sendable {
  let salt: Data
  let hash: Data

  init(code: String) {
    let salt = Data((0..<32).map { _ in UInt8.random(in: .min ... .max) })
    self.salt = salt
    self.hash = Self.hash(code: code, salt: salt)
  }

  func matches(_ code: String) -> Bool {
    // Constant-time as a matter of habit rather than need: nobody is timing a keypad.
    let candidate = Self.hash(code: code, salt: salt)
    guard candidate.count == hash.count else { return false }
    return zip(candidate, hash).reduce(into: UInt8(0)) { $0 |= $1.0 ^ $1.1 } == 0
  }

  private static func hash(code: String, salt: Data) -> Data {
    Data(SHA256.hash(data: salt + Data(code.utf8)))
  }
}

// MARK: - Where the digest lives

protocol PasscodeDigestStore: Sendable {
  func read() -> PasscodeDigest?
  func write(_ digest: PasscodeDigest)
  func delete()
}

private struct KeychainDigestStore: PasscodeDigestStore {
  let account: String
  let service: String

  private var query: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account,
      kSecAttrService as String: service
    ]
  }

  func read() -> PasscodeDigest? {
    var lookup = query
    lookup[kSecReturnData as String] = true
    lookup[kSecMatchLimit as String] = kSecMatchLimitOne

    var item: CFTypeRef?
    guard SecItemCopyMatching(lookup as CFDictionary, &item) == errSecSuccess,
          let data = item as? Data
    else { return nil }

    return try? JSONDecoder().decode(PasscodeDigest.self, from: data)
  }

  func write(_ digest: PasscodeDigest) {
    guard let data = try? JSONEncoder().encode(digest) else { return }

    // The app reads the digest while its own lock screen is up, which is only ever while the
    // device itself is unlocked; `ThisDeviceOnly` keeps it out of backups and off other devices.
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]

    let updated = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    guard updated == errSecItemNotFound else { return }

    SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
  }

  func delete() {
    SecItemDelete(query as CFDictionary)
  }
}

private final class InMemoryDigestStore: PasscodeDigestStore, @unchecked Sendable {
  private let lock = NSLock()
  private var digest: PasscodeDigest?

  func read() -> PasscodeDigest? {
    lock.withLock { digest }
  }

  func write(_ digest: PasscodeDigest) {
    lock.withLock { self.digest = digest }
  }

  func delete() {
    lock.withLock { digest = nil }
  }
}
