//
//  Extensions.swift
//  SeeMe
//
//  Created by Edward Arenberg on 6/12/21.
//

import AVFoundation

extension Float {
  func deg2rad() -> CGFloat {
    return CGFloat(self * .pi / 180)
  }
  
}

extension AVAudioFile {
  
  var duration: TimeInterval {
    let sampleRateSong = Double(processingFormat.sampleRate)
    let lengthSongSeconds = Double(length) / sampleRateSong
    return lengthSongSeconds
  }
  
}
