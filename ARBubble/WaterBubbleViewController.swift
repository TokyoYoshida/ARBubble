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

struct GlobalData2 {
    var time: Float = 0
    var x: Float = 0
    var y: Float = 0
    var width: Float = 0
    var height: Float = 0
}

class WaterBubbleViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet weak var button: UIButton!
    
    private var globalData: [GlobalData2] = []
    private var startDate: Date = Date()
    var nowRecording: Bool = false
    let bubbleNodeName = "Bubble"
    
    let orientation = UIApplication.shared.statusBarOrientation
    var viewportSize: CGSize = CGSize(width: 0, height: 0)

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewportSize = self.sceneView.bounds.size
        
        sceneView.delegate = self
        
        sceneView.scene = SCNScene()
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        sceneView.autoenablesDefaultLighting = true;

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)

        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true, block: { (timer) in
            self.updateNodesTexture()
        })
    }
    
    func updateNodesTexture() {
        func calcTextureUV(node: SCNNode) -> (u: Float, v: Float){

            let width = self.view.frame.width
            let height = self.view.frame.height

            let screenPos = sceneView.projectPoint(node.position)
            let u = screenPos.x / Float(width)
            let v = screenPos.y / Float(height)
            
            return (u: u,v: v)
        }
        let time = Float(Date().timeIntervalSince(startDate))

        guard let cameraImage = captureCamera() else {return}
        let imageProperty = SCNMaterialProperty(contents: cameraImage)
        let nodes = sceneView.scene.rootNode.childNodes.compactMap {
            $0.childNode(withName: bubbleNodeName, recursively: true)
        }
        for (i, node) in nodes.enumerated() {
            guard let material = node.geometry?.firstMaterial else {return}
            guard let parent = node.parent else {return}
            material.diffuse.contents = cameraImage
            material.setValue(imageProperty, forKey: "diffuseTexture")


            var data = globalData[i]
            data.time = time
            let uv = calcTextureUV(node: parent)
            data.x = uv.u
            data.y = uv.v
            let uniformsData = Data(bytes: &data, count: MemoryLayout<GlobalData2>.size)
            node.geometry?.firstMaterial?.setValue(uniformsData, forKey: "globalData")
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard !(anchor is ARPlaneAnchor) else { return }
        addBubble(node: node)
    }
    
    func addBubble(node: SCNNode) {
        let sphereNode = SCNNode()

        sphereNode.geometry = makeBox()// SCNSphere(radius: 0.02) // SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)//SCNSphere(radius: 0.02)
        sphereNode.position.y += Float(0.05)
        
        guard let material = sphereNode.geometry?.firstMaterial else {return}
        let program = SCNProgram()
        program.vertexFunctionName = "vertexShader"
        program.fragmentFunctionName = "fragmentShader2"
            sphereNode.geometry?.firstMaterial?.program = program
            
        let time = Float(Date().timeIntervalSince(startDate))
        var data = GlobalData2()
        data.time = time
        globalData += [data]
        let uniformsData = Data(bytes: &data, count: MemoryLayout<GlobalData>.size)
        sphereNode.geometry?.firstMaterial?.setValue(uniformsData, forKey: "globalData")
        if let cameraImage = captureCamera() {
            let imageProperty = SCNMaterialProperty(contents: cameraImage)
            material.setValue(imageProperty, forKey: "diffuseTexture")
        }
        material.lightingModel = .lambert
        sphereNode.name = bubbleNodeName
            

        node.addChildNode(sphereNode)
        
        node.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3(0, 0.01, 0), duration: 1)))
    }
    
    func transformedBubble() -> SCNGeometry{
        let sphere = SCNSphere(radius: 0.02)
        let vertexes = sphere.sourceVectors(for: .vertex)
        print(vertexes.indices)
        let transformedVertices = vertexes.map {
            SCNVector3(x: $0.x , y: $0.y, z: $0.z)
        }
        let normals = sphere.sourceVectors(for: .normal)
        let transformedNormals = normals.map {
            SCNVector3(x: $0.x , y: $0.y, z: $0.z)
        }

        let verticesSource = SCNGeometrySource(vertices: transformedVertices)
        let normalsSource = SCNGeometrySource(normals: transformedNormals)
        let indices = (0..<transformedVertices.count).map{ Int( $0 ) }
        let faceSource = SCNGeometryElement(indices: indices, primitiveType: .triangleStrip)
        let  geometry = SCNGeometry(sources: [verticesSource, normalsSource], elements: [faceSource])
        
        return geometry
    }
    
    func makeBox() ->  SCNGeometry {
        // 頂点を定義します。
           let half = Float(2)
           let vertices = [
               // 手前
               SCNVector3(-half, +half, +half), // 手前+左上 0
               SCNVector3(+half, +half, +half), // 手前+右上 1
               SCNVector3(-half, -half, +half), // 手前+左下 2
               SCNVector3(+half, -half, +half), // 手前+右下 3

               // 奥
               SCNVector3(-half, +half, -half), // 奥+左上 4
               SCNVector3(+half, +half, -half), // 奥+右上 5
               SCNVector3(-half, -half, -half), // 奥+左下 6
               SCNVector3(+half, -half, -half), // 奥+右下 7

               // 左側
               SCNVector3(-half, +half, -half), // 8 (=4)
               SCNVector3(-half, +half, +half), // 9 (=0)
               SCNVector3(-half, -half, -half), // 10 (=6)
               SCNVector3(-half, -half, +half), // 11 (=2)

               // 右側
               SCNVector3(+half, +half, +half), // 12 (=1)
               SCNVector3(+half, +half, -half), // 13 (=5)
               SCNVector3(+half, -half, +half), // 14 (=3)
               SCNVector3(+half, -half, -half), // 15 (=7)

               // 上側
               SCNVector3(-half, +half, -half), // 16 (=4)
               SCNVector3(+half, +half, -half), // 17 (=5)
               SCNVector3(-half, +half, +half), // 18 (=0)
               SCNVector3(+half, +half, +half), // 19 (=1)

               // 下側
               SCNVector3(-half, -half, +half), // 20 (=2)
               SCNVector3(+half, -half, +half), // 21 (=3)
               SCNVector3(-half, -half, -half), // 22 (=6)
               SCNVector3(+half, -half, -half), // 23 (=7)
           ]

           // 各頂点における法線ベクトルを定義します。
           let normals = [
               // 手前
               SCNVector3(0, 0, 1),
               SCNVector3(0, 0, 1),
               SCNVector3(0, 0, 1),
               SCNVector3(0, 0, 1),

               // 奥
               SCNVector3(0, 0, -1),
               SCNVector3(0, 0, -1),
               SCNVector3(0, 0, -1),
               SCNVector3(0, 0, -1),

               // 左側
               SCNVector3(-1, 0, 0),
               SCNVector3(-1, 0, 0),
               SCNVector3(-1, 0, 0),
               SCNVector3(-1, 0, 0),

               // 右側
               SCNVector3(1, 0, 0),
               SCNVector3(1, 0, 0),
               SCNVector3(1, 0, 0),
               SCNVector3(1, 0, 0),

               // 上側
               SCNVector3(0, 1, 0),
               SCNVector3(0, 1, 0),
               SCNVector3(0, 1, 0),
               SCNVector3(0, 1, 0),

               // 下側
               SCNVector3(0, -1, 0),
               SCNVector3(0, -1, 0),
               SCNVector3(0, -1, 0),
               SCNVector3(0, -1, 0),
           ]

           // ポリゴンを定義します。
           let indices: [Int32] = [
               // 手前
               0, 2, 1,
               1, 2, 3,

               // 奥
               4, 5, 7,
               4, 7, 6,

               // 左側
               8, 10, 9,
               9, 10, 11,

               // 右側
               13, 12, 14,
               13, 14, 15,

               // 上側
               16, 18, 17,
               17, 18, 19,

               // 下側
               22, 23, 20,
               23, 21, 20,
           ]

           // カスタムジオメトリを作成します。
           let verticesSource = SCNGeometrySource(vertices: vertices)
           let normalsSource = SCNGeometrySource(normals: normals)
        let faceSource = SCNGeometryElement(indices: indices, primitiveType: .triangles)
           let customGeometry = SCNGeometry(sources: [verticesSource, normalsSource], elements: [faceSource])
            return customGeometry
    }
    
    func captureCamera() -> CGImage?{
        guard let frame = sceneView.session.currentFrame else {return nil}


        let pixelBuffer = frame.capturedImage

        var image = CIImage(cvPixelBuffer: pixelBuffer)

        let transform = frame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
        image = image.transformed(by: transform)

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
