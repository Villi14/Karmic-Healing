//
// Karmic Healing 2026
//

import Dependencies
import SwiftUI
import Common

@MainActor
final class AppLockController: ObservableObject {
  /// What the lock screen is asking for at the moment.
  enum Stage: Equatable {
    /// Face ID or Touch ID, either running or waiting behind the unlock button.
    case biometrics
    /// The app's own keypad, reached when biometrics cannot or would not answer.
    case passcode
    /// The owner has proved themselves and is choosing a code — the first one, or a
    /// replacement for one they have forgotten.
    case creatingPasscode
  }

  @Dependency(\.passcode) private var passcode
  @Dependency(\.biometrics) private var biometrics

  @Published private(set) var isUnlocked = false
  @Published private(set) var isAuthenticating = false
  @Published private(set) var errorMessage: String?
  @Published private(set) var biometry: Biometry = .none
  @Published private(set) var stage: Stage = .biometrics
  @Published private(set) var passcodeMessage: String?

  /// Set when the user dismisses the system prompt themselves, so returning to the app
  /// shows the unlock button instead of putting the prompt straight back up.
  private var didCancel = false

  /// Wrong codes are counted across lockings, so backgrounding the app is no way out of a wait.
  private var attempts = PasscodeAttempts()

  init() {
    biometry = biometrics.biometry()
  }

  var biometryIconName: String {
    switch biometry {
    case .faceID: return "faceid"
    case .touchID: return "touchid"
    case .opticID: return "opticid"
    case .none: return "lock.fill"
    }
  }

  /// The keypad offers a way back to biometrics only when there is one to go back to.
  var canOfferBiometrics: Bool {
    biometry != .none
  }

  /// Called when the app leaves the screen for good — the next return asks again.
  func lock() {
    isUnlocked = false
    errorMessage = nil
    passcodeMessage = nil
    didCancel = false
    stage = .biometrics
  }

  /// Grants the current session without a prompt, for when the user turns the lock on
  /// from inside the app and has therefore just proved they are the owner.
  func unlockWithoutPrompt() {
    isUnlocked = true
    errorMessage = nil
    passcodeMessage = nil
    didCancel = false
    stage = .biometrics
    attempts.recordSuccess()
  }

  /// The automatic attempt made on launch and on returning from the background.
  func authenticateIfNeeded() async {
    guard !isUnlocked, !isAuthenticating, !didCancel, stage == .biometrics else { return }
    await authenticate()
  }

  func authenticate() async {
    guard !isAuthenticating else { return }

    biometry = biometrics.biometry()
    let hasPasscode = passcode.isSet()
    let policy: BiometricsPolicy

    // Biometrics are asked for alone wherever they can answer: the system's own passcode screen
    // is exactly what the keypad is here to replace, and asking for it would put a text field in
    // front of the user on every launch. Without a code of our own it is still the only door
    // left when the device has no biometrics to offer.
    if biometrics.canEvaluate(.biometricsOnly) {
      policy = .biometricsOnly
    } else if !hasPasscode, biometrics.canEvaluate(.deviceOwner) {
      policy = .deviceOwner
    } else if hasPasscode {
      // No usable biometrics on this device, or none left after too many failures — the
      // keypad is the way in.
      stage = .passcode
      return
    } else {
      errorMessage = "app_lock_unavailable".loc
      return
    }

    isAuthenticating = true
    errorMessage = nil
    didCancel = false

    let outcome = await biometrics.evaluate(policy, "app_lock_reason".loc)

    isAuthenticating = false
    finish(outcome, hasPasscode: hasPasscode)
  }

  private func finish(_ outcome: BiometricsOutcome, hasPasscode: Bool) {
    guard outcome != .success else {
      // A lock turned on before codes existed unlocks once more the old way, and then asks
      // for a code — from here on the keypad is what stands behind biometrics.
      if hasPasscode {
        isUnlocked = true
      } else {
        stage = .creatingPasscode
      }
      return
    }

    guard hasPasscode else {
      if outcome == .cancelled {
        // Dismissing the prompt is a choice, not a failure — leave the unlock button in place.
        didCancel = true
        errorMessage = nil
      } else {
        errorMessage = "app_lock_failed".loc
      }
      return
    }

    // Whether the face was not recognised or the prompt was waved away, what is left to try
    // is the code.
    stage = .passcode
    passcodeMessage = nil
  }

  // MARK: - The code

  func remainingWait(at now: Date) -> Int {
    attempts.remainingWait(at: now)
  }

  /// Answers the keypad: `true` when the code was right and the app is now open.
  func submit(_ code: String, now: Date = Date()) -> Bool {
    guard !attempts.isWaiting(at: now) else { return false }

    guard passcode.verify(code) else {
      attempts.recordFailure(at: now)
      passcodeMessage = attempts.isWaiting(at: now) ? nil : "passcode_wrong".loc
      return false
    }

    attempts.recordSuccess()
    passcodeMessage = nil
    isUnlocked = true
    return true
  }

  /// A forgotten code is answered by the device itself: whoever can pass the phone's own
  /// Face ID or passcode is already entitled to everything the app is protecting.
  func resetPasscode() async {
    guard !isAuthenticating else { return }

    guard biometrics.canEvaluate(.deviceOwner) else {
      passcodeMessage = "app_lock_unavailable".loc
      return
    }

    isAuthenticating = true

    let outcome = await biometrics.evaluate(.deviceOwner, "passcode_reset_reason".loc)

    isAuthenticating = false
    guard outcome == .success else {
      passcodeMessage = outcome == .cancelled ? nil : "app_lock_failed".loc
      return
    }
    stage = .creatingPasscode
  }
}

struct AppLockView<Content: View>: View {
  @Environment(\.scenePhase) private var scenePhase
  @AppStorage(UserDefaultsClient.Keys.userTheme) private var userTheme: String = "system"
  @AppStorage(UserDefaultsClient.Keys.appLockEnabled) private var appLockEnabled = false
  @StateObject private var lockController = AppLockController()
  /// Ticks only while a wait is being counted down.
  @State private var now = Date()
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
    .task {
      await authenticateIfNeeded()
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
        Task { await authenticateIfNeeded() }
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

      ScrollView {
        VStack(spacing: DesignConstants.sectionSpacing) {
          if lockController.stage == .passcode {
            passcodeCard
          } else {
            biometricsCard
          }
        }
        .padding(DesignConstants.paddingXLarge)
        .karmicContentWidth(DesignConstants.maxAlertWidth)
      }
      .scrollBounceBehavior(.basedOnSize)
    }
    .accessibilityElement(children: .contain)
    .fullScreenCover(isPresented: isCreatingPasscode) {
      PasscodeSetupView(
        onFinished: { lockController.unlockWithoutPrompt() },
        // Whoever reached this screen has already answered the device itself, so backing out
        // of choosing a code leaves them in rather than locked out of their own app.
        onCancel: { lockController.unlockWithoutPrompt() }
      )
    }
  }

  private var isCreatingPasscode: Binding<Bool> {
    Binding(get: { lockController.stage == .creatingPasscode }, set: { _ in })
  }

  // MARK: - Biometrics

  private var biometricsCard: some View {
    VStack(spacing: DesignConstants.spacingXLarge) {
      auraSeal

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
    .lockCard
  }

  private var auraSeal: some View {
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
  }

  private var unlockButton: some View {
    Button {
      Task { await lockController.authenticate() }
    } label: {
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

  // MARK: - The code

  private var passcodeCard: some View {
    VStack(spacing: DesignConstants.sectionSpacing) {
      Image(systemName: "lock.fill")
        .font(.system(size: DesignConstants.scaled(32), weight: .light))
        .foregroundStyle(AuraGradient.gradient(for: .brow))

      PasscodePad(
        title: "passcode_enter_title".loc,
        message: passcodeMessage,
        biometryIconName: lockController.canOfferBiometrics ? lockController.biometryIconName : nil,
        isDisabled: waitRemaining > 0,
        onBiometry: { Task { await lockController.authenticate() } },
        onComplete: { lockController.submit($0) }
      )

      Button("passcode_forgot".loc) {
        Task { await lockController.resetPasscode() }
      }
      .buttonStyle(.karmic(tone: Spectrum.brow.color, prominence: .quiet))
    }
    .padding(DesignConstants.paddingLarge)
    .lockCard
    // Only while the keypad is on screen, and only to count a wait down to zero.
    .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now = $0 }
  }

  private var waitRemaining: Int {
    lockController.remainingWait(at: now)
  }

  private var passcodeMessage: String? {
    let wait = waitRemaining
    guard wait > 0 else { return lockController.passcodeMessage }
    return "passcode_locked_out".loc(wait)
  }

  private func authenticateIfNeeded() async {
    guard appLockEnabled, scenePhase == .active else { return }
    await lockController.authenticateIfNeeded()
  }
}

private extension View {
  /// The frosted panel every state of the lock screen sits on.
  var lockCard: some View {
    background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusLarge, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusLarge, style: .continuous)
          .stroke(AuraGradient.edge(for: .brow), lineWidth: DesignConstants.lineWidthThin)
      }
      .shadow(
        color: Spectrum.brow.color.opacity(DesignConstants.opacityCardShadow),
        radius: DesignConstants.shadowRadiusCard,
        y: DesignConstants.shadowOffsetCard
      )
  }
}
