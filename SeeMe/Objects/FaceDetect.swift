//
//  FaceDetect.swift
//  SeeMe
//
//  Created by Edward Arenberg on 6/12/21.
//

import UIKit
import ARKit


class FaceDetect {
  static var shared = FaceDetect()
  static var currentFOV : Float = 0
  
  var isDetecting = false
  var faces = [Face]()
  var sceneView: ARSCNView!

  var captureMode = false
  private let ciContext = CIContext()

  
  func detectAFace(pixelBuf : CVPixelBuffer, callback: @escaping ([(CGImage,CGRect)])->()) {
    let ci = CIImage(cvPixelBuffer: pixelBuf).rotate
    
    let frr = VNDetectFaceRectanglesRequest(completionHandler: {(request:VNRequest, error:Error?) in
      
      if self.captureMode {
        
        var mainFace : VNFaceObservation?
        var mainSize : CGFloat = 0
        for face in (request.results as? [VNFaceObservation]) ?? [] {
          let bb = face.boundingBox
          let size = bb.width * bb.height
          if size > mainSize {
            mainFace = face
            mainSize = size
          }
        }
        
        if let faceObservation = mainFace {
                    
          let bb = faceObservation.boundingBox
          let r = ci.extent
          
          let w = bb.width * r.width
          let h = bb.height * r.height
          let x = bb.minX * r.width
          let y = bb.minY * r.height
          
          let crop = CGRect(x: x, y: y, width: w, height: h)
          
                    
          let croppedImage = ci.cropped(to: crop) // boundingBox // fr

          if let cgImage = self.ciContext.createCGImage(croppedImage, from:croppedImage.extent) {
            callback([(cgImage,bb)])
          }
          
        } else {
          // No face in view
          self.captureMode = false
        }
      } else {
        let cgImages : [(CGImage,CGRect)] = (request.results as! [VNFaceObservation]).compactMap { faceObservation in
          let bb = faceObservation.boundingBox
          let r = ci.extent
          
          let w = bb.width * r.width
          let h = bb.height * r.height
          let x = bb.minX * r.width
          let y = bb.minY * r.height
          
          let crop = CGRect(x: x, y: y, width: w, height: h)
          
          let croppedImage = ci.cropped(to: crop) // boundingBox // fr
          let context = CIContext()
          let cg = context.createCGImage(croppedImage, from:croppedImage.extent)
          return cg == nil ? nil : (cg!,bb)
          
        }
        callback(cgImages)
      }
      
    })
    
    
    let rh = VNImageRequestHandler(ciImage: ci, options: [:])
    try? rh.perform([frr])
    
  }


}
