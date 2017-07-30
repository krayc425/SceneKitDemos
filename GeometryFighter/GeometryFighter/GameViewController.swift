//
//  GameViewController.swift
//  GeometryFighter
//
//  Created by 宋 奎熹 on 2017/7/29.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    
    /// 声明了一个类型为 SCNView 的属性用来渲染 SCNScene 的内容以供显示
    var scnView: SCNView!
    
    /// 声明了一个类型为 SCNScene 的属性
    var scnScene: SCNScene!
    
    /// 声明了一个摄像头节点
    var cameraNode: SCNNode!
    
    /// 决定下次生成几何体的时间
    var rebirthTime: TimeInterval = 0
    
    /// 一个 GameHelper 的单例对象
    var game = GameHelper.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setMyView()
        setMyScene()
        setMyCamera()
        generateShape()
        createHUD()
    }
    
    /// 把 self.view 转换成了 SCNView 类型并把它存储在了 scnView 这个属性里
    func setMyView() {
        scnView = self.view as! SCNView
        scnView.delegate = self
    }
    
    /// 创建了一个空白的 SCNScene 对象并将其存储在了 scnScene 里；然后把这个空白的场景设置给了 scnView 以备其使用
    func setMyScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.png"
        /// 会在底部打开一个实时的统计数据的面板
//        scnView.showsStatistics = true
        /// (不)允许用户使用简单的手势来控制摄像机
        scnView.allowsCameraControl = false
        /// 会自动给我们的场景添加一个全方向的灯光，这样暂时我们就不需要自己来添加灯光了
        scnView.autoenablesDefaultLighting = true
        /// 这行代码让 Scene Kit 的视图一直保持运行状态
        scnView.isPlaying = true
    }
    
    func setMyCamera() {
        /// 首先创建一个空的节点 SCNNode 并把它赋值给了变量 cameraNode
        cameraNode = SCNNode()
        /// 然后创建一个新的 SCNCamera 对象并把它赋值给了 cameraNode 的 camera 这个属性
        cameraNode.camera = SCNCamera()
        /// 然后设置 cameraNode 的位置为 (x:0, y:0, z:10)
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        /// 最后，把 cameraNode 作为子节点加入到场景的根节点中
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    /// 随机生成几何体
    func generateShape() {
        let color = UIColor.random()
        var shape: SCNGeometry
        switch Shape.randomShape() {
        case .Box:
            shape = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        case .Sphere:
            shape = SCNSphere(radius: 1.0)
        case .Pyramid:
            shape = SCNPyramid(width: 1.0, height: 2.0, length: 1.0)
        case .Cone:
            shape = SCNCone(topRadius: 0, bottomRadius: 0.5, height: 2.0)
        case .Cylinder:
            shape = SCNCylinder(radius: 0.5, height: 1.0)
        case .Capsule:
            shape = SCNCapsule(capRadius: 0.5, height: 1.0)
        case .Tube:
            shape = SCNTube(innerRadius: 0.5, outerRadius: 1.0, height: 1.0)
        case .Torus:
            shape = SCNTorus(ringRadius: 1.0, pipeRadius: 0.25)
        }
        /// 给随机的几何体上色，调整了几何体的 materials（材质）
        shape.materials.first?.diffuse.contents = color
        /// 带 geometry 参数的初始化方法，这样生成的节点会自动跟我们提供的几何体链接起来
        let shapeNode = SCNNode(geometry: shape)
        /// 所有的物理实体都是 SCNPhysicsBody 这个类的对象，在形状（shape）这个参数传递一个 nil，会自动基于节点的几何形状生成一个物理学形状
        shapeNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        /// 施加作用力的作用点，产生两个随机数
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        /// 使用这两个随机数来生成一个代表力的向量
        let force = SCNVector3(x: randomX, y: randomY, z: 0)
        /// 生成了另外一个向量来代表力作用在物体上的位置。这个点和物体的中心点稍微有点偏离，这样可以产生一个旋转。
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        /// 在几何体节点的物体实体上调用 applyForce(_: atPosition: impulse) 这个方法，填入上面生成的参数，来给物体施加力的作用
        shapeNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
        /// 创建了一个粒子系统并把它关联到了 shapeNode 上
        let trailProjector = createTrail(color: color, shape: shape)
        shapeNode.addParticleSystem(trailProjector)
        /// 给几何体标识名字
        if color == UIColor.black {
            shapeNode.name = "Bad"
        } else {
            shapeNode.name = "Good"
        }
        scnScene.rootNode.addChildNode(shapeNode)
    }
    
    /// 清理不在场景中的节点
    func clearScene() {
        for node in scnScene.rootNode.childNodes {
            /// 为了得到动画中物体真正的位置，使用 presentationNode 这个属性
            if node.presentation.position.y < -2 {
                node.removeFromParentNode()
            }
        }
    }
    
    /// 创建掉下来效果 SCNParticleSystem 的对象
    func createTrail(color: UIColor, shape: SCNGeometry) -> SCNParticleSystem {
        /// 把之前我们建立的粒子系统加载进来
        let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        /// 根据参数给定的颜色来调整粒子的基础色
        trail.particleColor = color
        /// 使用 shape 这个参数来指定发射器的形状
        trail.emitterShape = shape
        return trail
    }
    
    /// 创建爆炸效果 SCNParticleSystem 的对象
    func createExplosion(color: UIColor, shape: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
        let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
        explosion.emitterShape = shape
        explosion.particleColor = color
        explosion.birthLocation = .surface
        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let positionMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, positionMatrix)
        scnScene.addParticleSystem(explosion, transform: transformMatrix)
    }
    
    /// 使用预先编好的代码库中的 hudNode，设置了它的位置然后把它加入到了场景中
    func createHUD() {
        game.hudNode.position = SCNVector3(x: 0.0, y: 10.0, z: 0.0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }
    
    /// 在知道用户点击了哪个几何体之后使用的点击处理机
    func handleTap(node: SCNNode) {
        if node.name == "Good" {
            game.score += 1
            /// 使用 presentationNode 这个属性来获得节点的位置 position 和旋转 rotation，然后调用 createExplosion 这个方法
            /// 这里使用 presentationNode 的原因是因为当前模拟器还在移动节点。
            createExplosion(color: node.geometry!.firstMaterial?.diffuse.contents as! UIColor, shape: node.geometry!, position: node.presentation.position, rotation: node.presentation.rotation)
            node.removeFromParentNode()
        } else if node.name == "Bad" {
            game.lives -= 1
            createExplosion(color: node.geometry!.firstMaterial?.diffuse.contents as! UIColor, shape: node.geometry!, position: node.presentation.position, rotation: node.presentation.rotation)
            node.removeFromParentNode()
        }
    }
    
    /// 玩家每一次点击屏幕的时候，touchesBegan(_: withEvent:) 这个方法都会被调用，使用这个方法来捕捉用户的点击动作
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /// 拿到第一个可用的点击
        let touch = touches.first!
        /// 点击的位置转换成相对于 scnView 的本地坐标系
        let position = touch.location(in: scnView)
        /// hitTest(_: options:) 这个方法会返回一系列的 SCNHitTestResult 对象。这些对象包含了与用户触摸位置发出的射线相交的任何物体的信息
        let testResult = scnView.hitTest(position, options: nil)
        /// 检查是否有返回的结果
        if testResult.count > 0 {
            /// 如果有，那么拿到返回序列的第一个对象
            let realResult = testResult.first!
            /// 把这个对象传送到我们的点击处理方法
            handleTap(node: realResult.node)
        }
    }
    
    override var shouldAutorotate: Bool { return true }
    
    override var prefersStatusBarHidden: Bool { return true }
}

//这些渲染的步骤组成了渲染循环，我们可以把游戏的逻辑代码准确地加入到需要的地方，因为这些步骤总是按照下面的顺序运行：
//
//更新: 视图在代理上调用 renderer(_: updateAtTime:) 这个方法。这里是我们放入游戏场景更新的逻辑代码的好时机。
//执行动作和动画：Scene Kit 会执行场景中所有节点上关联的动作和动画效果。
//完成动画：视图会在代理上调用 renderer(_: didApplyAnimationsAtTime:) 这个方法。在这时，所有的节点都完成了这一帧需要完成的动画。
//物理模拟：Scene Kit 开始在场景中所有的节点上施加物理模拟的影响。
//完成物理模拟：视图会在代理上调用 renderer(_: didSimulatePhysicsAtTime:) 这个方法。在这时，所有的节点都完成了这一帧需要完成的物理模拟。
//计算约束：Scene Kit 将计算并实施约束。所谓约束，就是我们告诉 Scene Kit 的一些参数，用来决定如何变换节点来适配。
//开始渲染：视图会在代理上调用 renderer(_: willRenderScene: atTime:) 这个方法。在这时，视图马上要开始渲染场景了，所以任何需要放到最后的改变都应该放在这里。
//渲染：Scene Kit 渲染视图中的场景。
//完成渲染：循环的最后一步是调用 renderer(_: didRenderScene: atTime:)。这标志着一次渲染循环的结束；我们可以把任何需要在下一次循环开始前执行的代码放在这里。

extension GameViewController: SCNSceneRendererDelegate {
    /// 添加了协议方法 renderer(_: updateAtTime:) 的一个实现
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime currentTime: TimeInterval) {
        /// 首先检查当前时间是否大于重生时间。如果是，那么就生成一个新的几何体
        if currentTime > rebirthTime {
            /// 清理掉那些没用的几何体
            clearScene()
            /// 生成几何体
            generateShape()
            /// 更新重生时间为下一次生成新几何体的时间
            rebirthTime = currentTime + TimeInterval(Float.random(min: 0.2, max: 1.5))
            /// 更新 HUD
            game.updateHUD()
        }
    }
}
