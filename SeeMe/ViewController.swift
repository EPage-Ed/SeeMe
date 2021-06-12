//
//  ViewController.swift
//  SeeMe
//
//  Created by Edward Arenberg on 6/12/21.
//

import UIKit
import ARKit
import RealityKit
import AVFoundation
import CoreML
import Vision
import AudioToolbox
import CoreLocation
import simd

struct FaceIdent {
  let name : String
  let features : MLMultiArray
  
  func similarity(with f: MLMultiArray) -> Double {
    return 0.0
  }
}

class ViewController: UIViewController {
  
  @IBOutlet var arView: ARView!
  
  private var faceRequests = [VNRequest]()

  private var lastFrameTime : TimeInterval = 0
  private let faceIdModel = try! VNCoreMLModel(for: FaceId_resnet50_quantized().model)
  private var faceIdents = [Face]()

  
  private let audioEngine = AVAudioEngine()
  private let audioEnvironment = AVAudioEnvironmentNode()
  private let audioPlayer = AVAudioPlayerNode()
  
  private let locationManager = CLLocationManager()
  private var currentLocation: CLLocation?
  
  
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
    
    let orientation = CGImagePropertyOrientation(rawValue:image.imageOrientation)
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

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Load the "Box" scene from the "Experience" Reality File
    //    let boxAnchor = try! Experience.loadBox()
    
    // Add the box anchor to the scene
    //    arView.scene.anchors.append(boxAnchor)
  }
}

extension ViewController : ARSCNViewDelegate {
  
}
