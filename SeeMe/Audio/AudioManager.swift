//
//  AudioManager.swift
//  SeeMe
//
//  Created by Ethan Saadia on 6/12/21.
//

import PHASE
import Foundation

class AudioManager {
    private let engine = PHASEEngine(updateMode: .automatic)
    private var soundEvent: PHASESoundEvent? = nil
    private var listener: PHASEListener? = nil
    
    private var person1Source: PHASESource? = nil
        
    struct Identifiers {
        static let person1 = "person1"
        static let person1Event = "person1event"
    }
    
    init() {
        // Load person1 asset into PHASE
        let audioFileUrl = Bundle.main.url(forResource: "person1", withExtension: "wav")!
        let soundAsset = try! engine.assetRegistry.registerSoundAsset(url: audioFileUrl, identifier: Identifiers.person1, assetType: .resident, channelLayout: nil, normalizationMode: .dynamic)

        // Align channel layout with person1.wav
        let channelLayout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Mono)!
        // Create sampler node for reference later
        let channelMixerDefinition = PHASEChannelMixerDefinition(channelLayout: channelLayout)
        let samplerNodeDefinition = PHASESamplerNodeDefinition(soundAssetIdentifier: Identifiers.person1, mixerDefinition: channelMixerDefinition)
        
        try! engine.start()
        spatialPipeline()
    }
    
    private func spatialPipeline() {
        // Create a Spatial Pipeline.
        let spatialPipelineOptions: PHASESpatialPipeline.Options = [.directPathTransmission, .lateReverb]
        let spatialPipeline = PHASESpatialPipeline(options: spatialPipelineOptions)!
        spatialPipeline.entries[PHASESpatialCategory.lateReverb]!.sendLevel = 0.1
        engine.defaultReverbPreset = .cathedral
        
        // Create a Spatial Mixer with the Spatial Pipeline.
        let spatialMixerDefinition = PHASESpatialMixerDefinition(spatialPipeline: spatialPipeline)
        
        // Set the Spatial Mixer's Distance Model
        let distanceModelParameters = PHASEGeometricSpreadingDistanceModelParameters()
        distanceModelParameters.fadeOutParameters = PHASEDistanceModelFadeOutParameters(cullDistance: 12)
        distanceModelParameters.rolloffFactor = 1
        spatialMixerDefinition.distanceModelParameters = distanceModelParameters
        
        let samplerNodeDefinition = PHASESamplerNodeDefinition(soundAssetIdentifier: Identifiers.person1, mixerDefinition: spatialMixerDefinition)
        samplerNodeDefinition.playbackMode = .looping
        samplerNodeDefinition.setCalibrationMode(.relativeSpl, level: 0)
        samplerNodeDefinition.cullOption = .sleepWakeAtRealtimeOffset
        
        let soundEventAsset = try! engine.assetRegistry.registerSoundEventAsset(rootNode: samplerNodeDefinition, identifier: Identifiers.person1Event)
        
        
        // Listener transform setup
        self.listener = PHASEListener(engine: engine)
        listener!.transform = matrix_identity_float4x4
        
        try! engine.rootObject.addChild(listener!)
        
        // Create volumetric source
        let mesh = MDLMesh.newIcosahedron(withRadius: 0.0142, inwardNormals: false, allocator: nil)
        let shape = PHASEShape(engine: engine, mesh: mesh)
        
        let source = PHASESource(engine: engine, shapes: [shape])
        var sourceTransform = matrix_identity_float4x4
      /*
        sourceTransform.columns.0 = simd_make_float4(-1,0,0,0)
        sourceTransform.columns.1 = simd_make_float4(0,1,0,0)
        sourceTransform.columns.2 = simd_make_float4(0,0,-1,0)
        sourceTransform.columns.3 = simd_make_float4(0,0,2,1)
       */
        source.transform = sourceTransform
        source.gain = 0.0
        
        self.person1Source = source
        
        try! engine.rootObject.addChild(source)
        
        // Cardboard occluder
        let boxMesh = MDLMesh.newBox(withDimensions: simd_make_float3(0.6096*1, 0.3048*1, 0.1016*1), segments: simd_uint3(repeating: 6), geometryType: .triangles, inwardNormals: false, allocator: nil)
        let boxShape = PHASEShape(engine: engine, mesh: boxMesh)
        let material = PHASEMaterial(engine: engine, preset: .cardboard)
        boxShape.elements[0].material = material
        
        let occluder = PHASEOccluder(engine: engine, shapes: [boxShape])
        var occluderTransform = matrix_identity_float4x4
        occluderTransform.columns.0 = simd_make_float4(-1,0,0,0)
        occluderTransform.columns.1 = simd_make_float4(0,1,0,0)
        occluderTransform.columns.2 = simd_make_float4(0,0,-1,0)
        occluderTransform.columns.3 = simd_make_float4(0,0,1,1)
        occluder.transform = occluderTransform
        
//        try! engine.rootObject.addChild(occluder)
        
        // Create sound event
        let mixerParameters = PHASEMixerParameters()
        mixerParameters.addSpatialMixerParameters(identifier: spatialMixerDefinition.identifier, source: source, listener: listener!)
        
        self.soundEvent = try! PHASESoundEvent(engine: engine, assetIdentifier: Identifiers.person1Event, mixerParameters: mixerParameters)
        try! soundEvent!.start()
    }
    
    func update(cameraTransform: simd_float4x4?, faceTransform: simd_float4x4?) {
        guard let listener = self.listener, let source = self.person1Source else { return }

        if let cameraTransform = cameraTransform {
            listener.transform = cameraTransform
        }
        if let faceTransform = faceTransform {
            source.transform = faceTransform
        }
    }
    
    /// Turn the sound on or off
    func stop() {
      NSLog("--Stop")
//      print("--Stop")
      person1Source?.gain = 0
//      engine.pause()
//        engine.stop()
    }
    
    func start() {
      NSLog("Play--")
//      print("Play--")
      person1Source?.gain = 1
//      try! engine.start()
//        try! engine.start()
    }
    
    
}
