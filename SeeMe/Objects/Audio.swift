//
//  Audio.swift
//  SeeMe
//
//  Created by Edward Arenberg on 6/12/21.
//

import Foundation
import AVFoundation

class Audio : NSObject {
  static var shared = Audio()

  let audioQueue = DispatchQueue(label: "AudioQueue", qos: .userInitiated)

  let audioFiles = [
    "person1.wav",
    "person2.wav"
  ]
  
  
  var camDir : Float = 0 { // Pos = counter-clockwise
    didSet {
      
    }
  }
}
