/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#if os(macOS)
    import Cocoa
    import SceneKit
    
let NSColorList:[NSColor] = [
    NSColor.black,
    NSColor.white,
    NSColor.red,
    NSColor.lime,
    NSColor.blue,
    NSColor.yellow,
    NSColor.cyan,
    NSColor.silver,
    NSColor.gray,
    NSColor.maroon,
    NSColor.olive,
    NSColor.brown,
    NSColor.green,
    NSColor.lightGray,
    NSColor.magenta,
    NSColor.orange,
    NSColor.purple,
    NSColor.teal
]
    
    extension NSColor {
        
        public static func random() -> NSColor {
            let maxValue = NSColorList.count
            let rand = Int(arc4random_uniform(UInt32(maxValue)))
            return NSColorList[rand]
        }
        
        public static var lime: NSColor {
            return NSColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        }
        
        public static var silver: NSColor {
            return NSColor(red: 192/255, green: 192/255, blue: 192/255, alpha: 1.0)
        }
        
        public static var maroon: NSColor {
            return NSColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
        }
        
        public static var olive: NSColor {
            return NSColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 1.0)
        }
        
        public static var teal: NSColor {
            return NSColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0)
        }
        
        public static var navy: NSColor {
            return NSColor(red: 0.0, green: 0.0, blue: 128, alpha: 1.0)
        }
    }
#endif
