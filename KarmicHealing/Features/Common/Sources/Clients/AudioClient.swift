import Foundation
import OSLog
import AVFoundation
import Dependencies

public struct AudioClient {
  public var playSound: @Sendable (String, String) -> Void
  public var setVolume: @Sendable (Float) -> Void
  public var getVolume: @Sendable () -> Float
  public var stopSound: @Sendable () -> Void
  /// Puts the app into a playback audio session so a session's chime is heard over the silent
  /// switch and over whatever the user is already listening to.
  public var activateSession: @Sendable () -> Void
  public var deactivateSession: @Sendable () -> Void

  public init(
    playSound: @escaping @Sendable (String, String) -> Void,
    setVolume: @escaping @Sendable (Float) -> Void,
    getVolume: @escaping @Sendable () -> Float,
    stopSound: @escaping @Sendable () -> Void,
    activateSession: @escaping @Sendable () -> Void,
    deactivateSession: @escaping @Sendable () -> Void
  ) {
    self.playSound = playSound
    self.setVolume = setVolume
    self.getVolume = getVolume
    self.stopSound = stopSound
    self.activateSession = activateSession
    self.deactivateSession = deactivateSession
  }
}

extension AudioClient: DependencyKey {
  public static let liveValue: Self = {
    let audioPlayer = AudioPlayer()
    return Self(
      playSound: { soundName, ext in
        audioPlayer.playSound(named: soundName, withExtension: ext)
      },
      setVolume: { volume in
        audioPlayer.setVolume(volume)
      },
      getVolume: {
        audioPlayer.getVolume()
      },
      stopSound: {
        audioPlayer.stopSound()
      },
      activateSession: {
        audioPlayer.activateSession()
      },
      deactivateSession: {
        audioPlayer.deactivateSession()
      }
    )
  }()

  public static let testValue: Self = Self(
    playSound: { _, _ in },
    setVolume: { _ in },
    getVolume: { 1.0 },
    stopSound: { },
    activateSession: { },
    deactivateSession: { }
  )
}

private class AudioPlayer {
  private var audioPlayer: AVAudioPlayer?
  private var volume: Float = 1.0

  /// `.playback` is what makes the chime audible with the ring switch flipped to silent, and
  /// `.duckOthers` lowers the user's own music for the moment the chime lands instead of stopping it.
  func activateSession() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default, options: [.duckOthers])
      try session.setActive(true)
    } catch {
      Log.audio.error("Failed to activate audio session: \(error.localizedDescription, privacy: .public)")
    }
  }

  func deactivateSession() {
    do {
      try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
      Log.audio.error("Failed to deactivate audio session: \(error.localizedDescription, privacy: .public)")
    }
  }

  func playSound(named soundName: String, withExtension ext: String = "wav") {
    activateSession()

    // Try to find sound in Resources module first, then fallback to main bundle
    let soundURL: URL?
    if let resourcesBundle = Bundle(identifier: "com.villi.karmichealing.resources") {
      soundURL = resourcesBundle.url(forResource: soundName, withExtension: ext)
    } else {
      soundURL = Bundle.main.url(forResource: soundName, withExtension: ext)
    }
    
    guard let soundURL = soundURL else {
      Log.audio.error("Sound file not found: \(soundName, privacy: .public).\(ext, privacy: .public)")
      return
    }
    
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
      audioPlayer?.volume = volume
      audioPlayer?.prepareToPlay()
      audioPlayer?.play()
    } catch {
      Log.audio.error("Error playing sound: \(error.localizedDescription, privacy: .public)")
    }
  }
  
  func setVolume(_ newVolume: Float) {
    volume = max(0.0, min(1.0, newVolume))
    audioPlayer?.volume = volume
  }
  
  func stopSound() {
    audioPlayer?.stop()
    audioPlayer = nil
  }
  
  func getVolume() -> Float {
    return volume
  }
}

extension DependencyValues {
  public var audio: AudioClient {
    get { self[AudioClient.self] }
    set { self[AudioClient.self] = newValue }
  }
} 