//
//  GameViewController.swift
//  MarbleMaze
//
//  Created by 宋 奎熹 on 2017/7/30.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//
import UIKit
import SceneKit

class GameViewController: UIViewController {
    /// category masks
    let CollisionCategoryBall   = 1
    let CollisionCategoryStone  = 2
    let CollisionCategoryPillar = 4
    let CollisionCategoryCrate  = 8
    let CollisionCategoryPearl  = 16
    
    var scnView: SCNView!
    var scnScene: SCNScene!
    /// the ball
    var ballNode: SCNNode!
    /// the camera
    var cameraNode: SCNNode!
    var cameraFollowNode: SCNNode!
    var lightFollowNode: SCNNode!
    
    var game = GameHelper.sharedInstance
    var motion = CoreMotionHelper()
    var motionForce = SCNVector3Zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupNodes()
        setupSounds()
        
        resetGame()
    }
    
    func setupScene() {
        scnView = self.view as! SCNView
        scnView.delegate = self
//        scnView.allowsCameraControl = true
//        scnView.showsStatistics = true
        /// creates an instance of SCNScene using your new scene
        scnScene = SCNScene(named: "art.scnassets/game.scn")
        /// sets your new scene as the active scene for the view
        scnView.scene = scnScene
        /// responsible for handling these contact events
        scnScene.physicsWorld.contactDelegate = self
    }
    
    func setupNodes() {
        ballNode = scnScene.rootNode.childNode(withName: "ball", recursively: true)!
        /// sets up the actual contactTestBitMask by performing a bitwise OR on all category masks
        ballNode.physicsBody?.contactTestBitMask = CollisionCategoryPillar | CollisionCategoryCrate | CollisionCategoryPearl
        /// attach cameraNode to the actual camera in the game scene
        cameraNode = scnScene.rootNode.childNode(withName: "camera", recursively: true)!
        /// sets up a SCNLookAtConstraint to look at the ballNode
        let constraint = SCNLookAtConstraint(target: ballNode)
        /// keep the camera aligned horizontally as it follows its target
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]
        cameraFollowNode = scnScene.rootNode.childNode(withName: "follow_camera", recursively: true)!
        /// adds the HUD to the camera as a child node so that it remains in view of the camera
        cameraNode.addChildNode(game.hudNode)
        lightFollowNode = scnScene.rootNode.childNode(withName: "follow_light", recursively: true)!
    }
    
    func setupSounds() {
        game.loadSound(name: "GameOver", fileNamed: "GameOver.wav")
        game.loadSound(name: "Powerup", fileNamed: "Powerup.wav")
        game.loadSound(name: "Reset", fileNamed: "Reset.wav")
        game.loadSound(name: "Bump", fileNamed: "Bump.wav")
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if game.state == GameStateType.TapToPlay {
            playGame()
        }
    }
    
    func playGame() {
        game.state = GameStateType.Playing
        cameraFollowNode.eulerAngles.y = 0
        cameraFollowNode.position = SCNVector3Zero
        replenishLife()
    }
    
    func resetGame() {
        game.state = GameStateType.TapToPlay
        game.playSound(node: ballNode, name: "Reset")
        ballNode.physicsBody!.velocity = SCNVector3Zero
        ballNode.position = SCNVector3(x: 0, y: 10, z: 0)
        cameraFollowNode.position = ballNode.position
        lightFollowNode.position = ballNode.position
        scnView.isPlaying = true
        game.reset()
    }
    
    func testForGameOver() {
        /// checks if the ball’s y-position has dropped lower than -5 units
        if ballNode.presentation.position.y < -5 {
            game.state = GameStateType.GameOver
            game.playSound(node: ballNode, name: "GameOver")
            ballNode.runAction(SCNAction.waitForDurationThenRunBlock(duration: 5) {
                (node:SCNNode!) -> Void in
                self.resetGame()
            })
        }
    }
    
    func replenishLife() {
        /// get the first and only material for the ballNode
        let material = ballNode.geometry!.firstMaterial!
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        material.emission.intensity = 1.0
        /// commits the animation transaction
        SCNTransaction.commit()
        game.score += 1
        game.playSound(node: ballNode, name: "Powerup")
    }
    
    func diminishLife() {
        // 1
        let material = ballNode.geometry!.firstMaterial!
        // 2
        if material.emission.intensity > 0 {
            material.emission.intensity -= 0.001
        } else {
            resetGame()
        }
    }
    
    func updateMotionControl() {
        /// updates the motionForce vector with the current motion data
        if game.state == GameStateType.Playing {
            motion.getAccelerometerData(interval: 0.1) {
                (x,y,z) in
                self.motionForce = SCNVector3(x: Float(x) * 0.05, y:0, z: Float(y + 0.8) * -0.05)
            }
            /// adds the motionForce vector to the ball’s velocity
            ballNode.physicsBody!.velocity += motionForce
        }
    }
    
    func updateCameraAndLights() {
        /// Instead of simply setting the camera FollowNode position to that of ballNode,
        /// you calcualate a linearly-interpolated position to slowly move the camera
        /// in the direction of ball. This creates a spectacular lazy camera effect.
        let lerpX = (ballNode.presentation.position.x - cameraFollowNode.position.x) * 0.01
        let lerpY = (ballNode.presentation.position.y - cameraFollowNode.position.y) * 0.01
        let lerpZ = (ballNode.presentation.position.z - cameraFollowNode.position.z) * 0.01
        cameraFollowNode.position.x += lerpX
        cameraFollowNode.position.y += lerpY
        cameraFollowNode.position.z += lerpZ
        /// Light is always in the same position as the cameraFollowNode
        lightFollowNode.position = cameraFollowNode.position
        /// Spins the camera in the right direction around the ball
        if game.state == GameStateType.TapToPlay {
            cameraFollowNode.eulerAngles.y -= 0.005
        }
    }
    
    func updateHUD() {
        switch game.state {
        case .Playing:
            game.updateHUD()
        case .GameOver:
            game.updateHUD(s: "-GAME OVER-")
        case .TapToPlay:
            game.updateHUD(s: "-TAP TO PLAY-")
        }
    }
}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateMotionControl()
        updateCameraAndLights()
        updateHUD()
        if game.state == GameStateType.Playing {
            testForGameOver()
            diminishLife()
        }
    }
}

extension GameViewController : SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        /// quickly determine the actual contact node
        var contactNode: SCNNode!
        if contact.nodeA.name == "ball" {
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }
        /// spawn the pearl again after 30 seconds
        if contactNode.physicsBody?.categoryBitMask == CollisionCategoryPearl {
            replenishLife()
            
            contactNode.isHidden = true
            contactNode.runAction(
                SCNAction.waitForDurationThenRunBlock(duration: 30) {
                    (node:SCNNode!) -> Void in
                    node.isHidden = false
            })
        }
        if contactNode.physicsBody?.categoryBitMask == CollisionCategoryPillar ||
            contactNode.physicsBody?.categoryBitMask == CollisionCategoryCrate {
            game.playSound(node: ballNode, name: "Bump")
        }
    }
}
