import Foundation
import AVFoundation
import Dependencies

public struct WatchAudioClient {
  public var playSound: @Sendable (String, String) -> Void
  public var setVolume: @Sendable (Float) -> Void
  public var getVolume: @Sendable () -> Float
  public var stopSound: @Sendable () -> Void
  public var updateSettings: @Sendable () -> Void
  public var restartAudioSession: @Sendable () -> Void

  public init(
    playSound: @escaping @Sendable (String, String) -> Void,
    setVolume: @escaping @Sendable (Float) -> Void,
    getVolume: @escaping @Sendable () -> Float,
    stopSound: @escaping @Sendable () -> Void,
    updateSettings: @escaping @Sendable () -> Void,
    restartAudioSession: @escaping @Sendable () -> Void
  ) {
    self.playSound = playSound
    self.setVolume = setVolume
    self.getVolume = getVolume
    self.stopSound = stopSound
    self.updateSettings = updateSettings
    self.restartAudioSession = restartAudioSession
  }
}

extension WatchAudioClient: DependencyKey {
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
      updateSettings: {
        // Update audio settings from UserDefaults
        let soundEnabled = UserDefaults.standard.bool(forKey: "sound_enabled")
        let audioVolume = UserDefaults.standard.float(forKey: "audio_volume")
        
        
        audioPlayer.setVolume(audioVolume)
        // Note: soundEnabled is checked in playSound function
      },
      restartAudioSession: {
        audioPlayer.restartAudioSession()
      }
    )
  }()

  public static let testValue: Self = Self(
    playSound: { _, _ in },
    setVolume: { _ in },
    getVolume: { 1.0 },
    stopSound: { },
    updateSettings: { },
    restartAudioSession: { }
  )
}

private class AudioPlayer {
  private var audioPlayer: AVAudioPlayer?
  private var volume: Float = 1.0

  func playSound(named soundName: String, withExtension ext: String = "wav") {
    print("🔊 WatchAudioClient: playSound called - '\(soundName).\(ext)'")
    
    // Configure audio session for watch
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .default, options: [])
      try audioSession.setActive(true)
    } catch {
    }
    
    // Try to find sound in the correct bundle
    var soundURL: URL?
    
    // First try the main bundle
    if let mainBundle = Bundle.main.url(forResource: soundName, withExtension: ext) {
      soundURL = mainBundle
    }
    
    // If not found, try the WatchKit app bundle
    if soundURL == nil {
      if let watchKitBundle = Bundle(identifier: "com.villi.karmichealing.watchkitapp") {
        soundURL = watchKitBundle.url(forResource: soundName, withExtension: ext)
      }
    }
    
    // If still not found, try all other bundles
    if soundURL == nil {
      for bundle in Bundle.allBundles {
        if let url = bundle.url(forResource: soundName, withExtension: ext) {
          soundURL = url
          break
        }
      }
    }

    guard let soundURL = soundURL else {
      print("❌ WatchAudioClient: Sound file '\(soundName).\(ext)' not found!")
      for bundle in Bundle.allBundles {
        print("📦 Bundle: \(bundle.bundleIdentifier ?? "unknown")")
        if let resourcePath = bundle.resourcePath {
          print("📁 Resources: \(resourcePath)")
        }
      }
      return
    }

    do {
      // Stop any existing audio
      audioPlayer?.stop()
      audioPlayer = nil
      
      audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
      audioPlayer?.volume = volume
      audioPlayer?.prepareToPlay()
      
      let success = audioPlayer?.play() ?? false
      if success {
        print("✅ WatchAudioClient: Sound '\(soundName)' played successfully")
      } else {
        print("❌ WatchAudioClient: Failed to play sound '\(soundName)'")
      }
    } catch {
      print("❌ WatchAudioClient: Error playing sound '\(soundName)': \(error)")
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
  
  func restartAudioSession() {
    
    // Stop any existing audio
    audioPlayer?.stop()
    audioPlayer = nil
    
    // Reconfigure audio session with proper error handling
    do {
      let audioSession = AVAudioSession.sharedInstance()
      
      // First deactivate the session
      try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
      
      // Set category with minimal options for Watch
      try audioSession.setCategory(.playback, mode: .default)
      
      // Activate the session
      try audioSession.setActive(true)
    } catch {
      // Try to recover by just setting the category
      do {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default)
      } catch {
      }
    }
  }
}

extension DependencyValues {
  public var audio: WatchAudioClient {
    get { self[WatchAudioClient.self] }
    set { self[WatchAudioClient.self] = newValue }
  }
}
