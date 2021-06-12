//
//  Face.swift
//  SeeMe
//
//  Created by Edward Arenberg on 6/12/21.
//

import AVFoundation

class Face : Equatable, Hashable {
  var ident : String!

  static func ==(lhs: Face, rhs: Face) -> Bool {
      return lhs.ident == rhs.ident
  }
  func hash(into hasher: inout Hasher) {
      hasher.combine(ident)
  }

  var player = AVAudioPlayerNode()
  var audioFile : AVAudioFile!
  var lastPlayed : Date?

}
