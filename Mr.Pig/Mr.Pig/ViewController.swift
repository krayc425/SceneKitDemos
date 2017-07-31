//
//  ViewController.swift
//  Mr.Pig
//
//  Created by 宋 奎熹 on 2017/7/31.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

import UIKit
import SceneKit
import SpriteKit    /// SceneKit relies on SpriteKit functionality to make the transition

class ViewController: UIViewController {
    
    /// Game singleton
    let game = GameHelper.sharedInstance
    
    var scnView: SCNView!
    var gameScene: SCNScene!
    var splashScene: SCNScene!
    var pigNode: SCNNode!
    var cameraNode: SCNNode!
    var cameraFollowNode: SCNNode!
    var lightFollowNode: SCNNode!
    var trafficNode: SCNNode!
    var collisionNode: SCNNode!
    var frontCollisionNode: SCNNode!
    var backCollisionNode: SCNNode!
    var leftCollisionNode: SCNNode!
    var rightCollisionNode: SCNNode!
    
    var driveLeftAction: SCNAction!
    var driveRightAction: SCNAction!
    var jumpLeftAction: SCNAction!
    var jumpRightAction: SCNAction!
    var jumpForwardAction: SCNAction!
    var jumpBackwardAction: SCNAction!
    var triggerGameOver: SCNAction!
    
    let BitMaskPig = 1
    let BitMaskVehicle = 2
    let BitMaskObstacle = 4
    let BitMaskFront = 8
    let BitMaskBack = 16
    let BitMaskLeft = 32
    let BitMaskRight = 64
    let BitMaskCoin = 128
    let BitMaskHouse = 256
    var activeCollisionsBitMask: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScenes()
        setupNodes()
        setupActions()
        setupTraffic()
        setupGestures()
        setupSounds()
        
        game.state = .tapToPlay
    }
    
    func setupScenes() {
        scnView = SCNView(frame: self.view.frame)
        self.view.addSubview(scnView)
        /// load 2 scenes
        gameScene = SCNScene(named: "/MrPig.scnassets/GameScene.scn")
        splashScene = SCNScene(named: "/MrPig.scnassets/SplashScene.scn")
        /// game starts, you’ll see the splash scene first
        scnView.scene = splashScene
        scnView.delegate = self
        gameScene.physicsWorld.contactDelegate = self
    }
    
    func setupNodes() {
        pigNode = gameScene.rootNode.childNode(withName: "MrPig", recursively: true)!
        /// setup cameras
        cameraNode = gameScene.rootNode.childNode(withName: "camera", recursively: true)!
        cameraNode.addChildNode(game.hudNode)
        cameraFollowNode = gameScene.rootNode.childNode(withName: "FollowCamera", recursively: true)!
        lightFollowNode = gameScene.rootNode.childNode(withName: "FollowLight", recursively: true)!
        trafficNode = gameScene.rootNode.childNode(withName: "Traffic", recursively: true)!
        /// collision nodes
        collisionNode = gameScene.rootNode.childNode(withName: "Collision", recursively: true)!
        frontCollisionNode = gameScene.rootNode.childNode(withName: "Front", recursively: true)!
        backCollisionNode = gameScene.rootNode.childNode(withName: "Back", recursively: true)!
        leftCollisionNode = gameScene.rootNode.childNode(withName: "Left", recursively: true)!
        rightCollisionNode = gameScene.rootNode.childNode(withName: "Right", recursively: true)!
        /// set contact bit masks
        pigNode.physicsBody?.contactTestBitMask = BitMaskVehicle | BitMaskCoin | BitMaskHouse
        frontCollisionNode.physicsBody?.contactTestBitMask = BitMaskObstacle
        backCollisionNode.physicsBody?.contactTestBitMask = BitMaskObstacle
        leftCollisionNode.physicsBody?.contactTestBitMask = BitMaskObstacle
        rightCollisionNode.physicsBody?.contactTestBitMask = BitMaskObstacle
    }
    
    func setupActions() {
        /// vehicle actions
        driveLeftAction = SCNAction.repeatForever(SCNAction.move(by: SCNVector3Make(-2.0, 0, 0), duration: 1.0))
        driveRightAction = SCNAction.repeatForever(SCNAction.move(by: SCNVector3Make(2.0, 0, 0), duration: 1.0))
        /// pig actions
        let duration = 0.2
        /// pig bounce action
        let bounceUpAction = SCNAction.moveBy(x: 0, y: 1.0, z: 0, duration: duration * 0.5)
        let bounceDownAction = SCNAction.moveBy(x: 0, y: -1.0, z: 0, duration: duration * 0.5)
        bounceUpAction.timingMode = .easeOut
        bounceDownAction.timingMode = .easeIn
        let bounceAction = SCNAction.sequence([bounceUpAction, bounceDownAction])
        /// pig move action
        let moveLeftAction = SCNAction.moveBy(x: -1.0, y: 0, z: 0, duration: duration)
        let moveRightAction = SCNAction.moveBy(x: 1.0, y: 0, z: 0, duration: duration)
        let moveForwardAction = SCNAction.moveBy(x: 0, y: 0, z: -1.0, duration: duration)
        let moveBackwardAction = SCNAction.moveBy(x: 0, y: 0, z: 1.0, duration: duration)
        /// pig rotation action
        let turnLeftAction = SCNAction.rotateTo(x: 0, y: convertToRadians(angle: -90), z: 0, duration: duration, usesShortestUnitArc: true)
        let turnRightAction = SCNAction.rotateTo(x: 0, y: convertToRadians(angle: 90), z: 0, duration: duration, usesShortestUnitArc: true)
        let turnForwardAction = SCNAction.rotateTo(x: 0, y: convertToRadians(angle: 180), z: 0, duration: duration, usesShortestUnitArc: true)
        let turnBackwardAction = SCNAction.rotateTo(x: 0, y: convertToRadians(angle: 0), z: 0, duration: duration, usesShortestUnitArc: true)
        /// combine 3 actions
        jumpLeftAction = SCNAction.group([turnLeftAction, bounceAction, moveLeftAction])
        jumpRightAction = SCNAction.group([turnRightAction, bounceAction, moveRightAction])
        jumpForwardAction = SCNAction.group([turnForwardAction, bounceAction, moveForwardAction])
        jumpBackwardAction = SCNAction.group([turnBackwardAction, bounceAction, moveBackwardAction])
        /// gameover action
        let spinAround = SCNAction.rotateBy(x: 0, y: convertToRadians(angle: 720), z: 0, duration: 2.0)
        let riseUp = SCNAction.moveBy(x: 0, y: 10, z: 0, duration: 2.0)
        let fadeOut = SCNAction.fadeOpacity(to: 0, duration: 2.0)
        let goodByePig = SCNAction.group([spinAround, riseUp, fadeOut])
        let gameOver = SCNAction.run { (node:SCNNode) -> Void in
            self.pigNode.position = SCNVector3(x: 0, y: 0, z: 0)
            self.pigNode.opacity = 1.0
            self.startSplash()
        }
        triggerGameOver = SCNAction.sequence([goodByePig, gameOver])
    }
    
    func setupTraffic() {
        for node in trafficNode.childNodes {
            /// Buses are slow, the rest are speed demons
            if node.name?.contains("Bus") == true {
                driveLeftAction.speed = 1.0
                driveRightAction.speed = 1.0
            } else {
                driveLeftAction.speed = 2.0
                driveRightAction.speed = 2.0
            }
            /// Let vehicle drive towards its facing direction
            if node.eulerAngles.y > 0 {
                node.runAction(driveLeftAction)
            } else {
                node.runAction(driveRightAction)
            }
        }
    }
    
    func setupGestures() {
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.handleGesture(_:)))
        swipeRight.direction = .right
        scnView.addGestureRecognizer(swipeRight)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.handleGesture(_:)))
        swipeLeft.direction = .left
        scnView.addGestureRecognizer(swipeLeft)
        let swipeForward = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.handleGesture(_:)))
        swipeForward.direction = .up
        scnView.addGestureRecognizer(swipeForward)
        let swipeBackward = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.handleGesture(_:)))
        swipeBackward.direction = .down
        scnView.addGestureRecognizer(swipeBackward)
    }
    
    func setupSounds() {
        if game.state == .tapToPlay {
            /// creates an SCNAudioSource object
            let music = SCNAudioSource(fileNamed: "MrPig.scnassets/Audio/Music.mp3")!
            music.volume = 0.3;
            music.loops = true
            music.shouldStream = true
            music.isPositional = false
            /// creates an audio player making use of the music audio source for playback
            let musicPlayer = SCNAudioPlayer(source: music)
            splashScene.rootNode.addAudioPlayer(musicPlayer)
        } else if game.state == .playing {
            let traffic = SCNAudioSource(fileNamed: "MrPig.scnassets/Audio/Traffic.mp3")!
            traffic.volume = 0.3
            traffic.loops = true
            traffic.shouldStream = true
            traffic.isPositional = true
            /// start to play the audio source as soon as it’s added to the rootNode
            let trafficPlayer = SCNAudioPlayer(source: traffic)
            gameScene.rootNode.addAudioPlayer(trafficPlayer)
            game.loadSound(name: "Jump", fileNamed: "MrPig.scnassets/Audio/Jump.wav")
            game.loadSound(name: "Blocked", fileNamed: "MrPig.scnassets/Audio/Blocked.wav")
            game.loadSound(name: "Crash", fileNamed: "MrPig.scnassets/Audio/Crash.wav")
            game.loadSound(name: "CollectCoin", fileNamed: "MrPig.scnassets/Audio/CollectCoin.wav")
            game.loadSound(name: "BankCoin", fileNamed: "MrPig.scnassets/Audio/BankCoin.wav")
        }
    }
    
    /// disable metal validation in 'Edit Scheme -> Options', otherwise must uncomment these #if codes
    func startSplash() {
//        #if DEBUG
//            scnView.scene = splashScene
//            game.state = .tapToPlay
//            setupSounds()
//            splashScene.isPaused = false
//        #else
            /// pause the game scene, preventing all physics simulations and actions from running
            gameScene.isPaused = true
            /// transit to the splash scene
            let transition = SKTransition.doorsOpenVertical(withDuration: 1.0)
            scnView.present(splashScene, with: transition, incomingPointOfView: nil, completionHandler: {
                self.game.state = .tapToPlay
                self.setupSounds()
                self.splashScene.isPaused = false
            })
//        #endif
    }
    
    func startGame() {
//        #if DEBUG
//            scnView.scene = gameScene
//            game.state = .playing
//            setupSounds()
//            gameScene.isPaused = false
//        #else
            /// stop all actions and any active physics simulations in the splash screen
            splashScene.isPaused = true
            /// create a transition effect using the SKTransition object
            let transition = SKTransition.doorsOpenVertical(withDuration: 1.0)
            /// present the game scene
            scnView.present(gameScene, with: transition, incomingPointOfView: nil, completionHandler: {
                /// after the transition completes and officially sets the game state to playing and loads up the correct sounds for the scene and unpauses the scene
                self.game.state = .playing
                self.setupSounds()
                self.gameScene.isPaused = false
            })
//        #endif
    }
    
    func stopGame() {
        game.state = .gameOver
        game.reset()
        pigNode.runAction(triggerGameOver)
    }
    
    @objc func handleGesture(_ sender: UISwipeGestureRecognizer) {
        /// keeps the game state in mind
        guard game.state == .playing else {
            return
        }
        /// check for active collisions in each direction stored in activeCollisionsBitMask and saves them
        let activeFrontCollision = activeCollisionsBitMask & BitMaskFront == BitMaskFront
        let activeBackCollision = activeCollisionsBitMask & BitMaskBack == BitMaskBack
        let activeLeftCollision = activeCollisionsBitMask & BitMaskLeft == BitMaskLeft
        let activeRightCollision = activeCollisionsBitMask & BitMaskRight == BitMaskRight
        /// makes sure that you only continue on to the rest of the gesture handler code when there is no active collision in the direction of the gesture
        guard (sender.direction == .up && !activeFrontCollision) ||
            (sender.direction == .down && !activeBackCollision) ||
            (sender.direction == .left && !activeLeftCollision) ||
            (sender.direction == .right && !activeRightCollision) else {
                game.playSound(node: pigNode, name: "Blocked")
                return
        }
        /// inspects direction of the gesture recognizer to determine the direction of the player’s swipe
        switch sender.direction {
        case UISwipeGestureRecognizerDirection.up:
            pigNode.runAction(jumpForwardAction)
        case UISwipeGestureRecognizerDirection.down:
            pigNode.runAction(jumpBackwardAction)
        case UISwipeGestureRecognizerDirection.left:
            if pigNode.position.x >  -15 {
                pigNode.runAction(jumpLeftAction)
            }
        case UISwipeGestureRecognizerDirection.right:
            if pigNode.position.x < 15 {
                pigNode.runAction(jumpRightAction)
            }
        default:
            break
        }
        game.playSound(node: pigNode, name: "Jump")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if game.state == .tapToPlay {
            startGame()
        }
    }
    
    func updatePositions() {
        collisionNode.position = pigNode.position
        /// Instead of simply updating cameraFollowNode to the same position as that of the pigNode, this technique creates a smooth, lazy camera tracking effect.
        let lerpX = (pigNode.position.x - cameraFollowNode.position.x) * 0.05
        let lerpZ = (pigNode.position.z - cameraFollowNode.position.z) * 0.05
        cameraFollowNode.position.x += lerpX
        cameraFollowNode.position.z += lerpZ
        /// update light position
        lightFollowNode.position = cameraFollowNode.position
    }
    
    func updateTraffic() {
        for node in trafficNode.childNodes {
            /// Once the node’s x-position crosses the 25 unit mark, you reset it to -25 and vice versa for nodes moving in the opposite direction
            if node.position.x > 25 {
                node.position.x = -25
            } else if node.position.x < -25 {
                node.position.x = 25
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden : Bool { return true }
    
    override var shouldAutorotate : Bool { return false }
}

extension ViewController : SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        /// keeping game states in mind
        guard game.state == .playing else {
            return
        }
        /// update
        game.updateHUD()
        updatePositions()
        updateTraffic()
    }
}

extension ViewController : SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard game.state == .playing else {
            return
        }
        /// determine whether nodeA or nodeB is the obstacle, which means that the other node is the collision box
        var collisionBoxNode: SCNNode!
        if contact.nodeA.physicsBody?.categoryBitMask == BitMaskObstacle {
            collisionBoxNode = contact.nodeB
        } else {
            collisionBoxNode = contact.nodeA
        }
        /// does a bitwise OR operation to add the colliding box’s category bit mask to activeCollisionsBitMask
        activeCollisionsBitMask |= collisionBoxNode.physicsBody!.categoryBitMask
        // the contactNode is not the pig
        var contactNode: SCNNode!
        if contact.nodeA.physicsBody?.categoryBitMask == BitMaskPig {
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }
        /// If the node the pig made contact with is indeed a vehicle, then it’s the end of the game
        if contactNode.physicsBody?.categoryBitMask == BitMaskVehicle {
            stopGame()
            game.playSound(node: pigNode, name: "Crash")
        }
        /// if the node the pig made contact with is a coin
        if contactNode.physicsBody?.categoryBitMask == BitMaskCoin {
            contactNode.isHidden = true
            contactNode.runAction(SCNAction.waitForDurationThenRunBlock(duration: 60) { (node: SCNNode!) -> Void in
                node.isHidden = false
            })
            game.collectCoin()
            game.playSound(node: pigNode, name: "CollectCoin")
        }
        /// if the node is the home, and checks whether collected enough coins
        if contactNode.physicsBody?.categoryBitMask == BitMaskHouse {
            if game.bankCoins() == true {
                game.playSound(node: pigNode, name: "BankCoin")
            }
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        guard game.state == .playing else {
            return
        }
        var collisionBoxNode: SCNNode!
        if contact.nodeA.physicsBody?.categoryBitMask == BitMaskObstacle {
            collisionBoxNode = contact.nodeB
        } else {
            collisionBoxNode = contact.nodeA
        }
        /// does a bitwise NOT operation followed by a bitwise AND operation to remove the collision box category bit mask from the activeCollisionsBitMask
        activeCollisionsBitMask &= ~collisionBoxNode.physicsBody!.categoryBitMask
    }
}
