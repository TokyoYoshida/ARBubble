//
//  Extensions.swift
//  ARBubble
//
//  Created by TokyoYoshida on 2020/10/10.
//  Copyright © 2020 TokyoMac. All rights reserved.
//

import SceneKit

extension SCNGeometry {

    func sourceVectors(for semantic: SCNGeometrySource.Semantic) -> [float3] {
        guard let vertexSource = sources(for: semantic).first else { fatalError() }
        return vertexSource.vectors()
    }
}

extension SCNGeometrySource {
    
    func vectors() -> [float3] {
        var vectors: [float3] = []
        
        let componentCount = vectorCount * componentsPerVector
        let componentStride = dataStride / bytesPerComponent
        var components = [Float](repeating: 0, count: componentCount)
        
        let data = self.data as NSData
        components = [Float](repeating: 0, count: data.length / MemoryLayout<Float>.size)
        data.getBytes(&components, length: data.length)

        for index in stride(from: 0, to: components.count, by: componentStride) {
            let vector = float3(
                x: components[index + 0],
                y: components[index + 1],
                z: components[index + 2])
            vectors.append(vector)
        }
        
        return vectors
    }
}
