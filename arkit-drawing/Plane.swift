//
//  Plane.swift
//  ARKit-Drawing
//
//  Created by  Apple24 on 02/01/2019.
//  Copyright © 2019 Chad Zeluff. All rights reserved.
//

import SceneKit
import ARKit

class Plane: SCNNode {
    
    var anchor: ARPlaneAnchor!
    var planeGeometry: SCNPlane!
    
    init(anchor: ARPlaneAnchor) {
        self.anchor = anchor
        super.init()
        configure()
    }
    
    private func configure() {
        
        self.planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        let material = SCNMaterial()
        
        material.diffuse.contents =  #colorLiteral(red: 0.9247109294, green: 0.9298656583, blue: 0.7062471509, alpha: 0.05)
        self.planeGeometry.materials = [material]
        
        self.geometry = planeGeometry
        self.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        self.transform = SCNMatrix4MakeRotation( -.pi / 2, 1.0, 0.0, 0.0)
    }
    
    func update(anchor: ARPlaneAnchor) {
        
        self.planeGeometry.width = CGFloat(anchor.extent.x)
        self.planeGeometry.height = CGFloat(anchor.extent.z)
        self.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
