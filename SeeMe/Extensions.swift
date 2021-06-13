//
//  Extensions.swift
//  SeeMe
//
//  Created by Edward Arenberg on 6/12/21.
//

import UIKit
import AVFoundation
import Vision

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


extension UIImage {
  
  /// Fix image orientaton to protrait up
  func fixedOrientation() -> UIImage? {
    guard imageOrientation != UIImage.Orientation.up else {
      // This is default orientation, don't need to do anything
      return self.copy() as? UIImage
    }
    
    guard let cgImage = self.cgImage else {
      // CGImage is not available
      return nil
    }
    
    guard let colorSpace = cgImage.colorSpace, let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
      return nil // Not able to create CGContext
    }
    
    var transform: CGAffineTransform = CGAffineTransform.identity
    
    switch imageOrientation {
    case .down, .downMirrored:
      transform = transform.translatedBy(x: size.width, y: size.height)
      transform = transform.rotated(by: CGFloat.pi)
    case .left, .leftMirrored:
      transform = transform.translatedBy(x: size.width, y: 0)
      transform = transform.rotated(by: CGFloat.pi / 2.0)
    case .right, .rightMirrored:
      transform = transform.translatedBy(x: 0, y: size.height)
      transform = transform.rotated(by: CGFloat.pi / -2.0)
    case .up, .upMirrored:
      break
    @unknown default:
      break
    }
    
    // Flip image one more time if needed to, this is to prevent flipped image
    switch imageOrientation {
    case .upMirrored, .downMirrored:
      transform = transform.translatedBy(x: size.width, y: 0)
      transform = transform.scaledBy(x: -1, y: 1)
    case .leftMirrored, .rightMirrored:
      transform = transform.translatedBy(x: size.height, y: 0)
      transform = transform.scaledBy(x: -1, y: 1)
    case .up, .down, .left, .right:
      break
    @unknown default:
      break
    }
    
    ctx.concatenate(transform)
    
    switch imageOrientation {
    case .left, .leftMirrored, .right, .rightMirrored:
      ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
    default:
      ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
      //            break
    }
    
    guard let newCGImage = ctx.makeImage() else { return nil }
    return UIImage.init(cgImage: newCGImage, scale: 1, orientation: .up)
  }
}


extension UIDeviceOrientation {
  func cameraOrientation() -> CGImagePropertyOrientation {
    switch self {
    case .landscapeLeft: return .up
    case .landscapeRight: return .down
    case .portraitUpsideDown: return .left
    default: return .right
    }
  }
}

extension CIImage {
  
  var rotate: CIImage {
    get {
      return self.oriented(UIDevice.current.orientation.cameraOrientation())
    }
  }
  
  /// Cropping the image containing the face.
  ///
  /// - Parameter toFace: the face to extract
  /// - Returns: the cropped image
  func cropImage(toFace face: VNFaceObservation) -> CIImage {
    let percentage: CGFloat = 0.6
    
    let width = face.boundingBox.width * CGFloat(extent.size.width)
    let height = face.boundingBox.height * CGFloat(extent.size.height)
    let x = face.boundingBox.origin.x * CGFloat(extent.size.width)
    let y = face.boundingBox.origin.y * CGFloat(extent.size.height)
    let rect = CGRect(x: x, y: y, width: width, height: height)
    
    let increasedRect = rect.insetBy(dx: width * -percentage, dy: height * -percentage)
    return self.cropped(to: increasedRect)
  }
}
