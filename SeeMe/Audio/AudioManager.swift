//
//  AudioManager.swift
//  SeeMe
//
//  Created by Ethan Saadia on 6/12/21.
//

import PHASE
import Foundation

class SoundManager {
    let engine = PHASEEngine(updateMode: .automatic)
    var soundEvent: PHASESoundEvent? = nil
    var listener: PHASEListener? = nil
    
    var person1Source: PHASESource? = nil
    
    init() {
        let audioFileUrl = Bundle.main.url(forResource: "person1", withExtension: "wav")!
        
        let soundAsset = try! engine.assetRegistry.registerSoundAsset(url: audioFileUrl, identifier: "beep", assetType: .resident, channelLayout: nil, normalizationMode: .dynamic)
        
        let channelLayout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Mono)!
        
        let channelMixerDefinition = PHASEChannelMixerDefinition(channelLayout: channelLayout)
        let samplerNodeDefinition = PHASESamplerNodeDefinition(soundAssetIdentifier: "beep", mixerDefinition: channelMixerDefinition)
        
        try! engine.start()
        spatialPipeline()
    }
    
    func spatialPipeline() {
        // Create a Spatial Pipeline.
        let spatialPipelineOptions: PHASESpatialPipeline.Options = [.directPathTransmission, .lateReverb]
        let spatialPipeline = PHASESpatialPipeline(options: spatialPipelineOptions)!
        spatialPipeline.entries[PHASESpatialCategory.lateReverb]!.sendLevel = 0.1
        engine.defaultReverbPreset = .mediumRoom
        
        // Create a Spatial Mixer with the Spatial Pipeline.
        let spatialMixerDefinition = PHASESpatialMixerDefinition(spatialPipeline: spatialPipeline)
        
        // Set the Spatial Mixer's Distance Model
        let distanceModelParameters = PHASEGeometricSpreadingDistanceModelParameters()
        distanceModelParameters.fadeOutParameters = PHASEDistanceModelFadeOutParameters(cullDistance: 10.0)
        distanceModelParameters.rolloffFactor = 0.25
        spatialMixerDefinition.distanceModelParameters = distanceModelParameters
        
        let samplerNodeDefinition = PHASESamplerNodeDefinition(soundAssetIdentifier: "beep", mixerDefinition: spatialMixerDefinition)
        samplerNodeDefinition.playbackMode = .looping
        samplerNodeDefinition.setCalibrationMode(.relativeSpl, level: 12)
        samplerNodeDefinition.cullOption = .sleepWakeAtRealtimeOffset
        
        let soundEventAsset = try! engine.assetRegistry.registerSoundEventAsset(rootNode: samplerNodeDefinition, identifier: "beepEvent")
        
        
        // Listener transform setup
        self.listener = PHASEListener(engine: engine)
        listener!.transform = matrix_identity_float4x4
        
        try! engine.rootObject.addChild(listener!)
        
        // Create volumetric source
        let mesh = MDLMesh.newIcosahedron(withRadius: 0.0142, inwardNormals: false, allocator: nil)
        let shape = PHASEShape(engine: engine, mesh: mesh)
        
        let source = PHASESource(engine: engine, shapes: [shape])
        var sourceTransform = matrix_identity_float4x4
        sourceTransform.columns.0 = simd_make_float4(-1,0,0,0)
        sourceTransform.columns.1 = simd_make_float4(0,1,0,0)
        sourceTransform.columns.2 = simd_make_float4(0,0,-1,0)
        sourceTransform.columns.3 = simd_make_float4(0,0,4,1)
        source.transform = sourceTransform
        
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
        
        try! engine.rootObject.addChild(occluder)
        
        // Create sound event
        let mixerParameters = PHASEMixerParameters()
        mixerParameters.addSpatialMixerParameters(identifier: spatialMixerDefinition.identifier, source: source, listener: listener!)
        
        self.soundEvent = try! PHASESoundEvent(engine: engine, assetIdentifier: "beepEvent", mixerParameters: mixerParameters)
        try! soundEvent!.start()
    }
}