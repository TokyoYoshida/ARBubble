//
//  ViewController.swift
//  ARBubble
//
//  Created by TokyoYoshida on 2020/10/04.
//  Copyright © 2020 TokyoMac. All rights reserved.
//

import UIKit
import ARKit

struct GlobalData {
    var ch_pos: SIMD2<Float>//   = float2 (0.0, 0.0);             // character position(X,Y)
    var d: Float// = 1e6;
    var time: Float
}

class ViewController: UIViewController, ARSCNViewDelegate {
    private var globalData: GlobalData = GlobalData(ch_pos: SIMD2<Float>(0,0), d: Float(1e6), time: Float(0))
    private var startDate: Date = Date()
    let sphereNode = SCNNode()

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        sceneView.scene = SCNScene()
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        sceneView.autoenablesDefaultLighting = true;

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)

        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true, block: { (timer) in
            self.updateTime(self.sphereNode)
        })

    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        sphereNode.geometry = SCNSphere(radius: 0.05)
        sphereNode.position.y += Float(0.05)
        
        let program = SCNProgram()
        program.vertexFunctionName = "vertexShader"
        program.fragmentFunctionName = "fragmentShader"
        sphereNode.geometry?.firstMaterial?.program = program
        
        let time = Float(Date().timeIntervalSince(startDate))
        globalData.time = time
        let uniformsData = Data(bytes: &globalData, count: MemoryLayout<GlobalData>.size)
        sphereNode.geometry?.firstMaterial?.setValue(uniformsData, forKey: "globalData")

        node.addChildNode(sphereNode)
    }

    func updateTime(_ node: SCNNode) {
        let time = Float(Date().timeIntervalSince(startDate))
        globalData.time = time
        let uniformsData = Data(bytes: &globalData, count: MemoryLayout<GlobalData>.size)
        node.geometry?.firstMaterial?.setValue(uniformsData, forKey: "globalData")
    }
}
