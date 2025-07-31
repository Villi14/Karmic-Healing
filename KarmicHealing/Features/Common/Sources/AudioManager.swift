//
// Karmic Healing 2025
//

import Foundation
import AVFoundation

public class AudioManager {
  public static let shared = AudioManager()
  
  private var audioPlayer: AVAudioPlayer?
  
  private init() {}
  
  public func playSound(named soundName: String, withExtension ext: String = "wav") {
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