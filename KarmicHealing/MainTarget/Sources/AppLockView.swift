//
// Karmic Healing 2026
//

import LocalAuthentication
import SwiftUI
import Common

@MainActor
final class AppLockController: ObservableObject {
  @Published private(set) var isUnlocked = false
  @Published private(set) var isAuthenticating = false
  @Published private(set) var errorMessage: String?
  @Published private(set) var biometryType: LABiometryType = .none

  /// Set when the user dismisses the system prompt themselves, so returning to the app
  /// shows the unlock button instead of putting the prompt straight back up.
  private var didCancel = false

  init() {
    biometryType = Self.availableBiometryType()
  }

  var biometryIconName: String {
    switch biometryType {
    case .faceID: return "faceid"
    case .touchID: return "touchid"
    default: return "lock.fill"
    }
  }

  /// Called when the app leaves the screen for good — the next return asks again.
  func lock() {
    isUnlocked = false
    errorMessage = nil
    didCancel = false
  }

  /// Grants the current session without a prompt, for when the user turns the lock on
  /// from inside the app and has therefore just proved they are the owner.
  func unlockWithoutPrompt() {
    isUnlocked = true
    errorMessage = nil
    didCancel = false
  }

  /// The automatic attempt made on launch and on returning from the background.
  func authenticateIfNeeded() {
    guard !isUnlocked, !isAuthenticating, !didCancel else { return }
    authenticate()
  }

  func authenticate() {
    guard !isAuthenticating else { return }

    let context = LAContext()
    biometryType = Self.availableBiometryType(using: context)
    var authenticationError: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authenticationError) else {
      errorMessage = "app_lock_unavailable".loc
      return
    }

    isAuthenticating = true
    errorMessage = nil
    didCancel = false

    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "app_lock_reason".loc) { [weak self] success, error in
      Task { @MainActor in
        guard let self else { return }
        self.isAuthenticating = false
        self.isUnlocked = success

        guard !success else { return }
        if Self.isCancellation(error) {
          // Dismissing the prompt is a choice, not a failure — leave the unlock button in place.
          self.didCancel = true
          self.errorMessage = nil
        } else {
          self.errorMessage = "app_lock_failed".loc
        }
      }
    }
  }

  private static func availableBiometryType(using context: LAContext = LAContext()) -> LABiometryType {
    _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    return context.biometryType
  }

  private static func isCancellation(_ error: Error?) -> Bool {
    guard let code = (error as? LAError)?.code else { return false }
    switch code {
    case .userCancel, .systemCancel, .appCancel: return true
    default: return false
    }
  }
}

struct AppLockView<Content: View>: View {
  @Environment(\.scenePhase) private var scenePhase
  @AppStorage(UserDefaultsClient.Keys.userTheme) private var userTheme: String = "system"
  @AppStorage(UserDefaultsClient.Keys.appLockEnabled) private var appLockEnabled = false
  @StateObject private var lockController = AppLockController()
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    Group {
      // Anything but an active scene keeps the content hidden, which also keeps it
      // out of the app switcher snapshot.
      if !appLockEnabled || (lockController.isUnlocked && scenePhase == .active) {
        content
      } else {
        lockScreen
      }
    }
    .preferredColorScheme(lockColorScheme)
    .onAppear {
      authenticateIfNeeded()
    }
    .onChange(of: appLockEnabled) { _, isEnabled in
      // Turning the lock on happens inside an unlocked app, so it takes effect from
      // the next launch rather than throwing the user out of the screen they are on.
      guard isEnabled else { return }
      lockController.unlockWithoutPrompt()
    }
    .onChange(of: scenePhase) { _, phase in
      switch phase {
      case .active:
        authenticateIfNeeded()
      case .background:
        if appLockEnabled {
          lockController.lock()
        }
      case .inactive:
        // Only a passing interruption — the system prompt itself lands here.
        break
      @unknown default:
        break
      }
    }
  }

  private var lockColorScheme: ColorScheme? {
    switch userTheme {
    case "light": return .light
    case "dark": return .dark
    default: return nil
    }
  }

  private var lockScreen: some View {
    ZStack {
      AuraBackground(level: .brow)

      VStack(spacing: DesignConstants.spacingXLarge) {
        ZStack {
          Circle()
            .fill(AuraGradient.soft(for: .brow))
            .frame(width: DesignConstants.scaled(128), height: DesignConstants.scaled(128))

          Circle()
            .stroke(AuraGradient.edge(for: .brow), lineWidth: DesignConstants.lineWidth)
            .frame(width: DesignConstants.scaled(104), height: DesignConstants.scaled(104))

          Image(systemName: lockController.biometryIconName)
            .font(.system(size: DesignConstants.scaled(50), weight: .light))
            .foregroundStyle(AuraGradient.gradient(for: .brow))
        }

        VStack(spacing: DesignConstants.spacingSmall) {
          Text("app_locked".loc)
            .font(Typography.heading)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)

          Text("face_id_lock_subtitle".loc)
            .font(Typography.bodySecondary)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
        }

        VStack(spacing: DesignConstants.spacingMedium) {
          if lockController.isAuthenticating {
            ProgressView()
              .tint(Spectrum.brow.color)
              .frame(height: DesignConstants.frameHeightXLarge)
          } else {
            unlockButton
          }

          if let errorMessage = lockController.errorMessage {
            Text(errorMessage)
              .font(Typography.caption)
              .multilineTextAlignment(.center)
              .foregroundStyle(.secondary)
          }
        }
      }
      .padding(DesignConstants.paddingXXLarge)
      .frame(maxWidth: DesignConstants.maxAlertWidth)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusLarge, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusLarge, style: .continuous)
          .stroke(AuraGradient.edge(for: .brow), lineWidth: DesignConstants.lineWidthThin)
      }
      .shadow(color: Spectrum.brow.color.opacity(DesignConstants.opacityCardShadow), radius: DesignConstants.shadowRadiusCard, y: DesignConstants.shadowOffsetCard)
      .padding(DesignConstants.paddingXLarge)
      .karmicContentWidth(DesignConstants.maxAlertWidth)
    }
    .accessibilityElement(children: .contain)
  }

  private var unlockButton: some View {
    Button(action: lockController.authenticate) {
      Text("unlock_with_face_id".loc)
        .font(Typography.body.weight(.semibold))
        .multilineTextAlignment(.center)
        .foregroundStyle(.black.opacity(0.82))
        .frame(maxWidth: .infinity, minHeight: DesignConstants.frameHeightXLarge)
    }
    .buttonStyle(.plain)
    .background {
      RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusLarge, style: .continuous)
        .fill(AuraGradient.gradient(for: .brow))
    }
    .frame(maxWidth: .infinity)
  }

  private func authenticateIfNeeded() {
    guard appLockEnabled, scenePhase == .active else { return }
    lockController.authenticateIfNeeded()
  }
}
