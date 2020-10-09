//
//  WaterBubbleViewController.swift
//  ARBubble
//
//  Created by TokyoYoshida on 2020/10/09.
//  Copyright © 2020 TokyoMac. All rights reserved.
//

import UIKit
import ARKit
import ReplayKit

class WaterBubbleViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet weak var button: UIButton!
    
    private var globalData: GlobalData = GlobalData(time: Float(0))
    private var startDate: Date = Date()
    var nowRecording: Bool = false
    let bubbleNodeName = "Bubble"
    
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
//            self.updateNodesTexture()
        })
    }
    
    func updateNodesTexture() {
        let cameraImage = captureCamera()
        let nodes = sceneView.scene.rootNode.childNodes.compactMap {
            $0.childNode(withName: bubbleNodeName, recursively: true)
        }
        for node in nodes {
            guard let material = node.geometry?.firstMaterial else {return}
            material.diffuse.contents = cameraImage
        }
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
        
        guard let material = sphereNode.geometry?.firstMaterial else {return}
        let program = SCNProgram()
        program.vertexFunctionName = "vertexShader"
        program.fragmentFunctionName = "fragmentShader2"
            sphereNode.geometry?.firstMaterial?.program = program
            
        let time = Float(Date().timeIntervalSince(startDate))
        globalData.time = time
        let uniformsData = Data(bytes: &globalData, count: MemoryLayout<GlobalData>.size)
        sphereNode.geometry?.firstMaterial?.setValue(uniformsData, forKey: "globalData")
        let cameraImage = captureCamera()
        let imageProperty = SCNMaterialProperty(contents: cameraImage)
        material.setValue(imageProperty, forKey: "diffuseTexture")
        material.lightingModel = .lambert
        sphereNode.name = bubbleNodeName
            

        node.addChildNode(sphereNode)
        
        node.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3(0, 0.01, 0), duration: 1)))
    }
    
    func captureCamera() -> CGImage?{
        guard let frame = sceneView.session.currentFrame else {return nil}
        let pixelBuffer = frame.capturedImage

        let image = CIImage(cvPixelBuffer: pixelBuffer)

        let context = CIContext(options:nil)
        guard let cameraImage = context.createCGImage(image, from: image.extent) else {return nil}

        return cameraImage
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

extension WaterBubbleViewController {
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

extension WaterBubbleViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        DispatchQueue.main.async {
            previewController.dismiss(animated: true, completion: nil)
        }
    }
}
