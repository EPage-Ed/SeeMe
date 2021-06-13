//
//  ViewController.swift
//  SeeMe
//
//  Created by Edward Arenberg on 6/12/21.
//

import UIKit
import ARKit
import AVFoundation
import CoreML
import Vision
import AudioToolbox
import simd

struct FaceIdent {
  let name : String
  let features : MLMultiArray
  
  func similarity(with f: MLMultiArray) -> Double {
    return 0.0
  }
}

class ViewController: UIViewController {
  
  @IBOutlet var sceneView: ARSCNView!
  
  private var faceRequests = [VNRequest]()

  private var lastFrameTime : TimeInterval = 0
  private let faceIdModel = try! VNCoreMLModel(for: FaceId_resnet50_quantized().model)
  private var faceIdents = [Face]()

  // MARK: Audio Properties
  private let audioEngine = AVAudioEngine()
  private let audioEnvironment = AVAudioEnvironmentNode()
  private let audioPlayer = AVAudioPlayerNode()
  
  private let locationManager = CLLocationManager()
  private var currentLocation: CLLocation?
    
  // MARK: Add delegate
  private var delegate: ViewControllerDelegate? = nil
    
  lazy var classificationRequest: VNCoreMLRequest = {
    do {
      let request = VNCoreMLRequest(model: faceIdModel, completionHandler: { [weak self] request, error in
        self?.processClassifications(for: request, error: error)
      })
      request.imageCropAndScaleOption = .centerCrop
      return request
    } catch {
      fatalError("Failed to load Vision ML model: \(error)")
    }
  }()


  func updateClassifications(for image: UIImage) {
    
    let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))!
    guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
    
    DispatchQueue.global(qos: .userInitiated).async {
      //            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
      do {
        try handler.perform([self.classificationRequest])
      } catch {
        print("Failed to perform classification.\n\(error.localizedDescription)")
      }
    }
  }


  func processClassifications(for request: VNRequest, error: Error?) {
    
    DispatchQueue.main.async {
      guard let results = request.results else {
        print("Unable to Classify\n\(error!.localizedDescription)")
        return
      }
      let classifications = results as! [VNClassificationObservation]
      
      if classifications.isEmpty {

      } else {
        let topClassifications = classifications.prefix(2)
        let descriptions = topClassifications.map { classification in
          return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
        }
        print(descriptions.joined(separator: "\n"))
      }
    }
  }
  
  @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
    // FaceDetect.shared.captureMode = true
  }
    
  func screenTappedSwiftUI() {
    FaceDetect.shared.captureMode = true
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    FaceManager.shared.start()

    sceneView.delegate = self
    sceneView.session.delegate = self

//    DispatchQueue.main.asyncAfter(deadline: .now()+5) {
//      FaceDetect.shared.captureMode = true
//    }
  }
  
  
  override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      // Create a session configuration
      let configuration = ARWorldTrackingConfiguration()
      configuration.worldAlignment = .gravityAndHeading

      // Run the view's session
      sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
  }
  
  override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      
      // Pause the view's session
      sceneView.session.pause()
  }
  

}

extension ViewController : ARSCNViewDelegate {
  func session(_ session: ARSession, didFailWithError error: Error) {
      // Present an error message to the user
      
  }
  
  func sessionWasInterrupted(_ session: ARSession) {
      // Inform the user that the session has been interrupted, for example, by presenting an overlay
  }
  
  func sessionInterruptionEnded(_ session: ARSession) {
      // Reset tracking and/or remove existing anchors if consistent tracking is required
      
  }
}

extension ViewController : ARSessionDelegate {

  func isFace(_ face: Face, hasCloseFeaturesWith otherFaceFeatures: MLMultiArray) -> (Bool,Double) {
    guard let features = face.features else { return(false,9999.0) }
    let treshold = 102.0 // find what is best
    var distance: Double = 0
    
    for index in 0..<otherFaceFeatures.count {
      let delta = features[index].doubleValue - otherFaceFeatures[index].doubleValue
      distance += delta * delta
    }
    distance = distance.squareRoot()
      
    let isFace = distance < treshold
    
    return (isFace, distance)
  }
  
  func identify(cgImage: CGImage, withCompletion completion: @escaping (_ faceFeatures: MLMultiArray?) -> Void) {
    
    DispatchQueue.global(qos: .userInitiated).async {
      
      let handler = VNImageRequestHandler(ciImage: CIImage(cgImage: cgImage))
      let faceIdRequest = VNCoreMLRequest(model: self.faceIdModel) { request, error in
        
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation],
              let faceFeatures = observations.first?.featureValue.multiArrayValue else {
                completion(nil)
                return
              }
        completion(faceFeatures)
      }
      
      do {
        try handler.perform([faceIdRequest])
      }
      catch {
        completion(nil)
      }
    }
  }
  
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    
    let t = frame.camera.transform
    FaceManager.shared.camTransform = t
    
    Audio.shared.camDir = frame.camera.eulerAngles.y  // roll, pitch, yaw

    let img = frame.capturedImage
    let tm = frame.timestamp
    
    if tm - lastFrameTime < 0.1 { return }
    lastFrameTime = tm

    let (xFov,yFov) = genFOV(session: session)
    let o = UIDevice.current.orientation
    FaceDetect.currentFOV = o.isLandscape ? xFov : (o.isPortrait ? yFov : FaceDetect.currentFOV)

    DispatchQueue.global().async {
      FaceDetect.shared.detectAFace(pixelBuf: img) { cgImages in
        if FaceDetect.shared.captureMode {
          FaceDetect.shared.captureMode = false
          guard let cgImg = cgImages.first else {
            return
          }
          DispatchQueue.main.async {
              
            if FaceDetect.shared.isDetecting { return }
            FaceDetect.shared.isDetecting = true
            
            let dg = DispatchGroup()
            for (i,cg) in cgImages.enumerated() {
              dg.enter()
              self.identify(cgImage: cg.0) { features in
                defer { dg.leave() }
                guard let faceFeatures = features else { return }
                if self.faceIdents.count == 0 {
                  let f = Face(ident: "Ed")
                  f.features = faceFeatures
                  f.bounds = cgImg.1
                  f.lastSeen = Date()
//                  f.index = self.faceIdents.count
                  
                  print("Adding Face")
                  self.faceIdents.append(f)
                  DispatchQueue.main.async {
                    let systemSoundID: SystemSoundID = 1016
                    AudioServicesPlaySystemSound(systemSoundID)
                  }
                }
                
                self.faceIdents.forEach { face in
                  let isFace = self.isFace(face, hasCloseFeaturesWith: faceFeatures)
                  if isFace.0 {
                    self.delegate?.detectionState(didChange: .tracking)
                    FaceManager.shared.faceSeen(face: face)
                    face.bounds = cg.1

                  } else {
                    self.delegate?.detectionState(didChange: .searching)
                  }
                }
              }
            }
            dg.notify(queue: .main) {
              FaceDetect.shared.isDetecting = false
            }

          }

        } else {
          DispatchQueue.main.async {
            z
            if FaceDetect.shared.isDetecting { return }
            FaceDetect.shared.isDetecting = true
            
            let dg = DispatchGroup()
            for (i,cg) in cgImages.enumerated() {
              dg.enter()
              self.identify(cgImage: cg.0) { features in
                defer { dg.leave() }
                guard let faceFeatures = features else { return }
                self.faceIdents.forEach { face in
                  let isFace = self.isFace(face, hasCloseFeaturesWith: faceFeatures)
                  if isFace.0 {
                    FaceManager.shared.faceSeen(face: face)
                    face.bounds = cg.1
                    
//                    print("See Person")
                  } else {
//                    print("----")
                  }
                }
              }
            }
            dg.notify(queue: .main) {
              FaceDetect.shared.isDetecting = false
            }
            
          }
          
        }
      }
    }
  }
  
  func genFOV(session: ARSession) -> (Float,Float) {
    let imageResolution = session.currentFrame!.camera.imageResolution
    let intrinsics = session.currentFrame!.camera.intrinsics
    
    let xFov = 2 * atan(Float(imageResolution.width)/(2 * intrinsics[0,0]))
    let yFov = 2 * atan(Float(imageResolution.height)/(2 * intrinsics[1,1]))
    return (xFov,yFov)
  }

}
