//
//  ViewController.swift
//  AR Ruler
//
//  Created by Иван Абрамов on 29.06.2020.
//  Copyright © 2020 Иван Абрамов. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var nodes : [SCNNode]  = []
    var textNode =  SCNNode()
    var lineNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let camera = sceneView.session.currentFrame?.camera {
//            didInitializeScene = true
            let transform = camera.transform
            let position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            makeUpdateCameraPos(towards: position)
        }
    }
    
    //    MARK: - ViewControllerCycleEvents
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if nodes.count >= 2 {
            for node in nodes {
                node.removeFromParentNode()
            }
            
            nodes.removeAll()
            textNode.removeFromParentNode()
            lineNode.removeFromParentNode()
        }
        
        if let touch = touches.first {
            let location = touch.location(in: sceneView)
            
            let results = sceneView.hitTest(location, types: .featurePoint)
            
            if let result = results.first {
                let location = result.worldTransform.columns.3
                
                let vector = SCNVector3(location.x, location.y, location.z)
                let node = addPoint(wtihPosition: vector)
                
                nodes.append(node)
                
                guard nodes.count == 2 else { return }
                let distance = (nodes[0].position.distance(to: nodes[1].position) * 100).rounded()
                let distanceText = "\(distance) cm"
                
                let textPosition = nodes[0].position.findCentralPoint(to: nodes[1].position)
                
                addDistancetext(position: textPosition, text: distanceText)
                addLine(BetweenPoint: nodes[0].position, and: nodes[1].position)
            }
        }
    }
    
    func addPoint(wtihPosition position: SCNVector3) -> SCNNode {
        let sphere = SCNSphere(radius: 0.005)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        sphere.materials = [material]
        
        let node = SCNNode()
        node.geometry = sphere
        node.position = position
        
        sceneView.scene.rootNode.addChildNode(node)
        
        return node
    }
    
    func addDistancetext(position: SCNVector3,  text: String) {
        textNode.removeFromParentNode()
        lineNode.removeFromParentNode()
        
        let distanceText = SCNText(string: text, extrusionDepth: 0.3)
        distanceText.font = UIFont(name: "Arial Rounded MT Bold", size: 7)
        distanceText.firstMaterial?.diffuse.contents = UIColor.red
        distanceText.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        

        textNode = SCNNode(geometry: distanceText)
        textNode.position = position
        textNode.scale = SCNVector3Make(0.005, 0.005, 0.005)

        sceneView.scene.rootNode.addChildNode(textNode)
        
    }
    
    func addLine(BetweenPoint start: SCNVector3, and end: SCNVector3) {
        let vector = SCNVector3(start.x - end.x, start.y - end.y, start.z - end.z)
        
        let distance = vector.distance(to: SCNVector3(0, 0, 0))
        
        let midPosition = start.findCentralPoint(to: end)

        let lineGeometry = SCNCylinder()
        lineGeometry.radius = 0.003
        lineGeometry.height = CGFloat(distance)
        lineGeometry.radialSegmentCount = 25
        lineGeometry.firstMaterial!.diffuse.contents = UIColor.white

        lineNode = SCNNode(geometry: lineGeometry)
        lineNode.position = midPosition
        lineNode.look (at: end, up: sceneView.scene.rootNode.worldUp, localFront: lineNode.worldUp)
        
        sceneView.scene.rootNode.addChildNode(lineNode)
    }
    
    func rotateText(towards position: SCNVector3) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.20
        textNode.look(at: position, up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, 1))
        SCNTransaction.commit()
    }
    
    
    func makeUpdateCameraPos(towards: SCNVector3) {
        let scene = sceneView.scene
        
        scene.rootNode.enumerateChildNodes({ (node, _) in
            rotateText(towards: towards)
        })
    }

    
}

// MARK: - Extensions

extension SCNVector3 {
    func  distance(to vector:  SCNVector3) -> Float {
        return simd_distance(simd_float3(self), simd_float3(vector))
    }
    
    func findCentralPoint(to vector: SCNVector3) -> SCNVector3 {
        let centralVector = SCNVector3(
                                        (self.x + vector.x) / 2,
                                        (self.y + vector.y) / 2,
                                        (self.z + vector.z) / 2
                                       )
        
        return centralVector
    }
}
