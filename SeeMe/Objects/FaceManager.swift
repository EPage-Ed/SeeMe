//
//  FaceManager.swift
//  SeeMe
//
//  Created by Edward Arenberg on 6/12/21.
//

import Foundation
import simd

class FaceManager {
  static var shared = FaceManager()
  
  private var audioManager = AudioManager()
  var camTransform : simd_float4x4 = matrix_identity_float4x4 // simd_float4x4()
  
  private var allFaces = Set([Face]())
  private var playFaces = Set([Face]())
  private var faceArray = [Face]()
  private var playIndex = 0
  private let audio = Audio.shared
  private var timer : Timer!
  private var timerCount = 0
  private let timerInterval : TimeInterval = 2
  private var timerPlayAllTime = 10
  
  func start() {
//    audioManager.update(cameraTransform: camTransform, faceTransform: Face.farTransform)
//    audioManager.start()
    
    timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { timer in
      self.timerCount += Int(self.timerInterval)
      if self.timerCount % self.timerPlayAllTime == 0 {
        let now = Date()
        self.playFaces.formUnion(self.allFaces.filter {
          ($0.lastPlayed?.timeIntervalSince(now) ?? -100.0) < -10 // Played more than 10 seconds ago
                                                                && ($0.lastSeen?.timeIntervalSince(now) ?? -999.0) > -120 // Seen less than 120 seconds ago
        })
      }
      self.play()
      
      let audioTime = Int(self.allFaces.reduce(0, {(s,f) in s + 2}) * 3)
//      let audioTime = Int(self.allFaces.reduce(0, {$0 + $1.audioFile.duration}) * 3)
      self.timerPlayAllTime = max(10, audioTime)
    }
  }
  
  func playFace(face:Face) {
    playFaces.insert(face)
  }
  
  func faceSeen(face:Face) {
    face.lastSeen = Date()
//    print("Seen")
    
    let (success,f) = allFaces.insert(face)
    if success {
      playFace(face: f)
    }
  }
  
  var playing = false
  func play() {
    if playing { return }
    if playFaces.count == 0 { return }
    playing = true
    
    doPlay()
    
  }
  
  func doPlay() {
    guard let face = playFaces.popFirst() else { playing = false; return }
//    NSLog("Play \(String(describing:face.ident))")
    face.play(audioManager: audioManager, camTrans: camTransform) {
      self.playFaces.remove(face)
      self.doPlay()
    }
    
    /*
    face.play {
      self.playFaces.remove(face)
      self.doPlay()
    }
     */
  }


}
