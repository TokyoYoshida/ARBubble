//
//  ViewController.swift
//  ARBubble
//
//  Created by TokyoYoshida on 2020/10/04.
//  Copyright © 2020 TokyoMac. All rights reserved.
//

import UIKit
import ARKit
import ReplayKit

struct GlobalData {
    var time: Float
}

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet weak var button: UIButton!
    
    private var globalData: GlobalData = GlobalData(time: Float(0))
    private var startDate: Date = Date()
    var nowRecording: Bool = false

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
    }

    func updateTime(_ node: SCNNode) {
        let time = Float(Date().timeIntervalSince(startDate))
        globalData.time = time
        let uniformsData = Data(bytes: &globalData, count: MemoryLayout<GlobalData>.size)
        node.geometry?.firstMaterial?.setValue(uniformsData, forKey: "globalData")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard !(anchor is ARPlaneAnchor) else { return }
        addBubble(node: node)
    }
    
    func addBubble(node: SCNNode) {
        let sphereNode = SCNNode()

        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true, block: { (timer) in
            self.updateTime(sphereNode)
        })

        sphereNode.geometry = SCNSphere(radius: 0.02)
        sphereNode.position.y += Float(0.05)
        
        let program = SCNProgram()
        program.vertexFunctionName = "vertexShader"
        program.fragmentFunctionName = "fragmentShader2"
        sphereNode.geometry?.firstMaterial?.program = program
        
        let time = Float(Date().timeIntervalSince(startDate))
        globalData.time = time
        let uniformsData = Data(bytes: &globalData, count: MemoryLayout<GlobalData>.size)
        sphereNode.geometry?.firstMaterial?.setValue(uniformsData, forKey: "globalData")

        node.addChildNode(sphereNode)
        
        node.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3(0, 0.1, 0), duration: 1)))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        let touchPos = touch.location(in: sceneView)
        let hitTest = sceneView.hitTest(touchPos, types: .existingPlaneUsingExtent)
        if !hitTest.isEmpty {
            let anchor = ARAnchor(transform: hitTest.first!.worldTransform)
            sceneView.session.add(anchor: anchor)
        }
    }

    @IBAction func tappedButton(_ sender: Any) {
        if nowRecording {
            nowRecording = false
            button.setTitle("Start", for: .normal)
            stopRecording()
        } else {
            nowRecording = true
            button.setTitle("Stop", for: .normal)
            startRecording()
        }
    }
}

extension ViewController {
    func startRecording() {
        guard !RPScreenRecorder.shared().isRecording else { return }
        RPScreenRecorder.shared().startRecording(handler: { (error) in
            if let error = error {
                debugPrint(#function, "recording something failed", error)
            }
        })
    }

    func stopRecording() {
        guard RPScreenRecorder.shared().isRecording else { return }
        RPScreenRecorder.shared().stopRecording(handler: { (previewViewController, error) in
            guard let previewViewController = previewViewController else { return }
            previewViewController.previewControllerDelegate = self

            self.present(previewViewController, animated: true, completion: nil)
        })
    }
}

extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        DispatchQueue.main.async {
            previewController.dismiss(animated: true, completion: nil)
        }
    }
}
