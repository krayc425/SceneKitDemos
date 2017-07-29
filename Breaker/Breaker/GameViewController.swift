//
//  GameViewController.swift
//  Breaker
//
//  Created by 宋 奎熹 on 2017/7/29.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    var scnView: SCNView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupNodes()
        setupSounds()
    }
    
    /// casting self.view as a SCNView and storing it for convenient access
    func setupScene() {
        scnView = self.view as! SCNView
        scnView.delegate = self
    }
    
    func setupNodes() {
        
    }
    
    func setupSounds() {
        
    }
    
    override var shouldAutorotate: Bool { return true }
    
    override var prefersStatusBarHidden: Bool { return true }
}

/// conforms to the SCNSceneRendererDelegate protocol, and there’s a stub for renderer(_: updateAtTime:) that’s called once for every frame update
extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer,
                  updateAtTime time: TimeInterval) {
    }
}
