import Foundation
import AVFoundation
import Dependencies

public struct AudioClient {
  public var playSound: @Sendable (String, String) -> Void
  
  public init(
    playSound: @escaping @Sendable (String, String) -> Void
  ) {
    self.playSound = playSound
  }
}

extension AudioClient: DependencyKey {
  public static let liveValue: Self = {
    let audioPlayer = AudioPlayer()
    return Self(
      playSound: { soundName, ext in
        audioPlayer.playSound(named: soundName, withExtension: ext)
      }
    )
  }()
  
  public static let testValue: Self = Self(
    playSound: { _, _ in }
  )
}

private class AudioPlayer {
  private var audioPlayer: AVAudioPlayer?
  
  func playSound(named soundName: String, withExtension ext: String = "wav") {
    guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: ext) else {
      print("Sound file not found: \(soundName).\(ext)")
      return
    }
    
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
      audioPlayer?.prepareToPlay()
      audioPlayer?.play()
    } catch {
      print("Error playing sound: \(error)")
    }
  }
}

extension DependencyValues {
  public var audio: AudioClient {
    get { self[AudioClient.self] }
    set { self[AudioClient.self] = newValue }
  }
} 