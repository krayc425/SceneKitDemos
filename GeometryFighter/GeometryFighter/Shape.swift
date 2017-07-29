//
//  Shape.swift
//  GeometryFighter
//
//  Created by 宋 奎熹 on 2017/7/29.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

import Foundation

public enum Shape: Int {
    
    case Box = 0
    case Sphere
    case Pyramid
    case Cone
    case Cylinder
    case Capsule
    case Tube
    case Torus
    
    static func randomShape() -> Shape {
        let maxValue = Torus.rawValue
        let random = arc4random_uniform(UInt32(maxValue+1))
        return Shape(rawValue: Int(random))!
    }
}
