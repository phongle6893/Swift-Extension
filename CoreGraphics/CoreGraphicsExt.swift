//
//  CoreGraphicsExt.swift
//  Swift Extension
//
//  Created by Phong Le on 10/9/19.
//

import CoreGraphics

// MARK: - CGRect extension
extension CGRect {
    init(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
        self = CGRect(x: x, y: y, width: width, height: height)
    }
    
    var center: CGPoint { CGPoint(midX, midY) }
}

// MARK: - CGSize extension
extension CGSize {
    init(_ width: CGFloat, _ height: CGFloat) {
        self = CGSize(width: width, height: height)
    }
    var isSixteenNine: Bool {
        (width * 9 == height * 16) ||
        (width * 16 == height * 9)
    }
    
    var isPortrait: Bool {
        width < height
    }
    
    var isLandscape: Bool {
        width > height
    }
    
    var isSquare: Bool {
        width == height
    }
}

// MARK: - CGPoint extension
extension CGPoint {
    init(_ x: CGFloat, _ y: CGFloat) {
        self = CGPoint(x: x, y: y)
    }
    
    func distanceToPoint(_ p: CGPoint) -> CGFloat {
        return sqrt(pow((p.x - x), 2) + pow((p.y - y), 2))
    }
    
    func angle(with centerPoint: CGPoint) -> CGFloat {
        let deltaY = centerPoint.y - self.y
        let deltaX = self.x - centerPoint.x
        let angle = atan2(deltaX, deltaY)
        return angle
    }
}

// MARK: - CGFloat extension
extension CGFloat {
    var floatValue: Float { Float(self) }
    var intValue: Int { Int(self) }
}

extension CGPath {
    func scale(_ scale: CGFloat) -> CGPath {
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let benzierPath = UIBezierPath(cgPath: self)
        benzierPath.apply(transform)
        return benzierPath.cgPath
    }
    
    func exportImage(with fillColor: CGColor?, in size: CGSize) -> UIImage? {
        CLLogInfo("exportImage: size:\(size), boundingBox: \(self.boundingBox), boundingBoxOfPath: \(self.boundingBoxOfPath)")
        // Prepare to draw
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        let flipTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height)
        context?.concatenate(flipTransform)
        
        // Drawing
        context?.addPath(self)
        if let fillColor = fillColor {
            context?.setFillColor(fillColor)
            context?.fillPath()
        }
        
        // Export
        let exportImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return exportImage
    }
}
