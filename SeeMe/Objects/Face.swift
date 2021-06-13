//
//  Face.swift
//  SeeMe
//
//  Created by Edward Arenberg on 6/12/21.
//

import AVFoundation
import CoreML

class Face : Equatable, Hashable {
  static let playTime : TimeInterval = 20
  static let maxTime : TimeInterval = 120
  static let faceWidthInMeters : Float = 7.0 / 39.37
  
  var ident : String!

  convenience init(ident:String) {
      self.init()
      self.ident = ident
  }

  static func ==(lhs: Face, rhs: Face) -> Bool {
    return lhs.ident == rhs.ident
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(ident)
  }
  
  var player = AVAudioPlayerNode()
  var audioFile : AVAudioFile!
  var lastPlayed : Date?
  var volume : Float {
    let vol = Float(bounds.size.width * bounds.size.height) // 0...1
    return max(min(1.0, vol * 10),0.1)
  }
  var xPos : Float { // -0.5 to +0.5
    Float((bounds.maxX + bounds.minX) / 2) - 0.5
  }
  var xOffsetMeters : Float {
    let sceneWidth = Face.faceWidthInMeters / Float(bounds.width)   // ~ 8 inches, percent of scene
    let x = xPos * sceneWidth
    return x
  }
  var distance : Float {
    let d = Double(xOffsetMeters) / tan(angle)
    return Float(d)
  }
  var angle : Double {  // 0 = in front, < 0 = left, > 0 = right
    // Camera FOV varies by device & orientation
    // iPhone X landscape = 60.983
    // myCamera.activeFormat.videoFieldOfView
    
    let x = Double((bounds.maxX + bounds.minX) / 2) - 0.5
    let y = Double(0.5 / tan(FaceDetect.currentFOV / 2))
    let p = atan(x / y)
    
    // let a = asin((c - 0.5) * Double(FaceDetect.currentFOV) )
    return p
  }
  var playAngle : Double = 0
  
  var features : MLMultiArray?
  var lastSeen : Date?
  var lastSeenHeading : Double = Double(Audio.shared.camDir)
  var lastPlayHeading : Double = 0
  
  var playPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
  
  var position = AVAudio3DPoint(x: 0, y: 0, z: -1) {
    didSet {
      player.position = position
      let xd = position.x - playPosition.x
      //            let yd = position.y - playPosition.y
      let zd = position.z - playPosition.z
      //            let move = sqrt(xd*xd + yd*yd + zd*zd)
      let move = sqrt(xd*xd + zd*zd)
      //            print(move)
      if move > 0.5 {
        print(ident!,"Moved ",move)
        FaceManager.shared.playFace(face: self)
      }
    }
  }
  var bounds : CGRect = .zero {
    didSet {
      position = calcPosition()
    }
  }
  func calcPosition() -> AVAudio3DPoint {
    return calcPosition(lastSeenHeading: Float(lastSeenHeading), distance: distance)
  }
  func calcPosition(lastSeenHeading:Float, distance: Float) -> AVAudio3DPoint {
    let x = distance * sin(lastSeenHeading)
    let z = distance * cos(lastSeenHeading)
    
    let p = AVAudio3DPoint(x: x, y: 0, z: -z)
    return p
  }
  
  var significantMove : Bool {
    let pp = player.position
    return abs(pp.x - xPos) > 0.2
  }
  var sound : String? {
    didSet {
    }
  }
  
  
  func play(completion:@escaping ()->()) {
    if doPlay {
      
//      Audio.shared.startAudio()
      
      self.schedule(audioFile: audioFile) { callbackType in
        completion()
      }
    } else {
      completion()
    }
  }
  var doPlay : Bool {
    return true
  }
  
  func schedule(audioFile:AVAudioFile,completion:@escaping AVAudioPlayerNodeCompletionHandler) {
    
    let doPlay = true
    player.volume = doPlay ? 1.0 : 0 // volume : 0
    
    print("Play \(ident!) x \(xOffsetMeters) vol \(player.volume) distance \(distance)")

    player.scheduleFile(audioFile, at: nil, completionCallbackType: .dataPlayedBack, completionHandler: completion)
    lastPlayed = doPlay ? Date() : lastPlayed
  }

}
