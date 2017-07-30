//
//  GameViewController.swift
//  Breaker
//
//  Created by 宋 奎熹 on 2017/7/29.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

import UIKit
import SceneKit

/// define the collision type bit mask
enum ColliderType: Int {
    case ball     = 0b0001
    case barrier  = 0b0010
    case brick    = 0b0100
    case paddle   = 0b1000
}

class GameViewController: UIViewController {
    
    var scnView: SCNView!
    
    var scnScene: SCNScene!
    /// 2 cameras
    var horizontalCameraNode: SCNNode!
    var verticalCameraNode: SCNNode!
    /// 1 ball
    var ballNode: SCNNode!
    /// 1 paddle
    var paddleNode: SCNNode!
    /// 1 floor
    var floorNode: SCNNode!
    /// keep track of the last node with which the ball made contact
    var lastContactNode: SCNNode!
    /// store the touch’s initial x-position and the paddle’s x- position
    var touchX: CGFloat = 0
    var paddleX: Float = 0
    /// singleton game
    var game = GameHelper.sharedInstance
    
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
        /// hide the panel
        scnView.showsStatistics = false
        
        scnScene = SCNScene(named: "Breaker.scnassets/Scenes/Game.scn")
        scnView.scene = scnScene
        scnScene.physicsWorld.contactDelegate = self
    }
    
    func setupNodes() {
        scnScene.rootNode.addChildNode(game.hudNode)
        horizontalCameraNode = scnScene.rootNode.childNode(withName: "HorizontalCamera", recursively: true)!
        verticalCameraNode = scnScene.rootNode.childNode(withName: "VerticalCamera", recursively: true)!
        ballNode = scnScene.rootNode.childNode(withName: "Ball", recursively: true)!
        paddleNode = scnScene.rootNode.childNode(withName: "Paddle", recursively: true)!
        floorNode = scnScene.rootNode.childNode(withName: "Floor", recursively: true)!
        /// adds a SCNLookAtConstraint to both cameras in the scene, which will force the camera to point towards the targeted node
        verticalCameraNode.constraints = [SCNLookAtConstraint(target: floorNode)]
        horizontalCameraNode.constraints = [SCNLookAtConstraint(target: floorNode)]
        /// you need to set the contactTestBitMask of a physics body to tell the physics engine that you’re interested in notification when collisions happen
        /// you let the physics engine know that you want to call the protocol method whenever the ball collides with nodes that have a category bit mask of either 2, 4, or 8 — respectively, these represent a barrier, brick or paddle
        ballNode.physicsBody?.contactTestBitMask =
            ColliderType.barrier.rawValue |
            ColliderType.brick.rawValue |
            ColliderType.paddle.rawValue
    }
    
    func setupSounds() {
        game.loadSound(name: "Paddle", fileNamed: "Breaker.scnassets/Sounds/Paddle.wav")
        game.loadSound(name: "Block0", fileNamed: "Breaker.scnassets/Sounds/Block0.wav")
        game.loadSound(name: "Block1", fileNamed: "Breaker.scnassets/Sounds/Block1.wav")
        game.loadSound(name: "Block2", fileNamed: "Breaker.scnassets/Sounds/Block2.wav")
        game.loadSound(name: "Barrier", fileNamed: "Breaker.scnassets/Sounds/Barrier.wav")
    }
    
    override var shouldAutorotate: Bool { return true }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    /// inspect the device’s orientation to determine the new orientation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let deviceOrientation = UIDevice.current.orientation
        switch(deviceOrientation) {
        case .portrait:
            scnView.pointOfView = verticalCameraNode
        default:
            scnView.pointOfView = horizontalCameraNode
        }
    }
    
    /// As soon as a touch starts, this code simply stores the touch and paddle’s x-position
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: scnView)
            touchX = location.x
            paddleX = paddleNode.position.x
        }
    }
    
    /// detect when the user moves their finger around the screen
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            /// this updates the paddle’s position relative to the initial touch location stored in touchX
            let location = touch.location(in: scnView)
            paddleNode.position.x = paddleX + (Float(location.x - touchX) * 0.1)
            /// limits the paddle’s movement and confines it between the barrier’s limits
            if paddleNode.position.x > 4.5 {
                paddleNode.position.x = 4.5
            } else if paddleNode.position.x < -4.5 {
                paddleNode.position.x = -4.5
            }
        }
        /// updates both cameras’ x-position to be the same as the paddle
        verticalCameraNode.position.x = paddleNode.position.x
        horizontalCameraNode.position.x = paddleNode.position.x
    }
}

/// conforms to the SCNSceneRendererDelegate protocol, and there’s a stub for renderer(_: updateAtTime:) that’s called once for every frame update
extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        game.updateHUD()
    }
}

extension GameViewController: SCNPhysicsContactDelegate {
    /// it’s called when two physics bodies you’re interested in start making contact with each other
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        /// figure out which two nodes collide
        var contactNode: SCNNode!
        if contact.nodeA.name == "Ball" {
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }
        /// prevent the ball from making contact with the same node more than once per interaction by using lastContactNode
        if lastContactNode != nil && lastContactNode == contactNode {
            return
        }
        lastContactNode = contactNode
        
        /// This section checks whether the ball is making contact with a barrier by looking at the categoryBitMask of contactNode
        if contactNode.physicsBody?.categoryBitMask == ColliderType.barrier.rawValue {
            game.playSound(node: contactNode, name: "Barrier")
            if contactNode.name == "Bottom" {
                game.lives -= 1
                if game.lives == 0 {
                    game.saveState()
                    game.reset()
                }
            }
        }
        /// This checks whether the ball is making contact with a brick using the same technique as above
        if contactNode.physicsBody?.categoryBitMask == ColliderType.brick.rawValue {
            game.playSound(node: contactNode, name: "Block\(arc4random() % 3)")
            game.score += 1
            /// lets the brick disappear for 120 seconds then makes it reappear from the dead like a zombie
            contactNode.isHidden = true
            contactNode.runAction(
                SCNAction.waitForDurationThenRunBlock(duration: 120) {
                    (node:SCNNode!) -> Void in
                    node.isHidden = false
            })
        }
        /// The last type of node to check is the paddle, so this checks which part of the paddle the ball hits
        if contactNode.physicsBody?.categoryBitMask == ColliderType.paddle.rawValue {
            game.playSound(node: contactNode, name: "Paddle")
            if contactNode.name == "Left" {
                ballNode.physicsBody!.velocity.xzAngle -= (convertToRadians(angle: 20))
            }
            if contactNode.name == "Right" {
                ballNode.physicsBody!.velocity.xzAngle += (convertToRadians(angle: 20))
            }
        }
        /// forcing the ball to a constant speed of five
        ballNode.physicsBody?.velocity.length = 5.0
    }
}
