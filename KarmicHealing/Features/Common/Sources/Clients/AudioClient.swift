import Foundation
import AVFoundation
import Dependencies

public struct AudioClient {
  public var playSound: @Sendable (String, String) -> Void
  public var setVolume: @Sendable (Float) -> Void
  public var getVolume: @Sendable () -> Float
  
  public init(
    playSound: @escaping @Sendable (String, String) -> Void,
    setVolume: @escaping @Sendable (Float) -> Void,
    getVolume: @escaping @Sendable () -> Float
  ) {
    self.playSound = playSound
    self.setVolume = setVolume
    self.getVolume = getVolume
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
      }
    )
  }()
  
  public static let testValue: Self = Self(
    playSound: { _, _ in },
    setVolume: { _ in },
    getVolume: { 1.0 }
  )
}

private class AudioPlayer {
  private var audioPlayer: AVAudioPlayer?
  private var volume: Float = 1.0
  
  func playSound(named soundName: String, withExtension ext: String = "wav") {
    guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: ext) else {
      print("Sound file not found: \(soundName).\(ext)")
      return
    }
    
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
      audioPlayer?.volume = volume
      audioPlayer?.prepareToPlay()
      audioPlayer?.play()
    } catch {
      print("Error playing sound: \(error)")
    }
  }
  
  func setVolume(_ newVolume: Float) {
    volume = max(0.0, min(1.0, newVolume))
    audioPlayer?.volume = volume
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