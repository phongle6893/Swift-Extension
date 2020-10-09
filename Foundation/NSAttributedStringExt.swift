//
//  CoreGraphicsExt.swift
//  Swift Extension
//
//  Created by Phong Le on 10/9/19.
//

import UIKit
import CoreGraphics

extension NSAttributedString {

    var font: UIFont? {
        let range = NSRange(location: 0, length: self.length)
        let fontData = self.attributes(at: range.location, longestEffectiveRange: nil, in: range)
        return fontData[.font] as? UIFont
    }
    
    var baseline: CGFloat {
        (font?.lineHeight ?? 0) - (font?.ascender ?? 0)
    }
    
    var cgPath: CGPath? {
        let textPath = CGMutablePath.init()
        let line = CTLineCreateWithAttributedString(self)
        guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else { return nil }
        for run in runs {
            guard let attributes = CTRunGetAttributes(run) as? [String: AnyObject], let font = attributes[kCTFontAttributeName as String] as? UIFont else {
                continue
            }
            let baseline = font.lineHeight - font.ascender
            let count = CTRunGetGlyphCount(run)
            for index in 0..<count {
                let range = CFRangeMake(index, 1)
                var glyph = CGGlyph()
                CTRunGetGlyphs(run, range, &glyph)
                var position = CGPoint()
                CTRunGetPositions(run, range, &position)
                guard let letterPath = CTFontCreatePathForGlyph(font, glyph, nil) else {
                    continue
                }
                let transform = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: position.x, ty: position.y + baseline)
                textPath.addPath(letterPath, transform: transform)
            }
        }
        return textPath
    }
    
    func export(in bounds: CGRect, angle: CGFloat, _ color: UIColor?, _ scale: CGFloat) -> UIImage? {
        let letterImage = self.extractImage(in: bounds, expect: scale)
        return letterImage
    }
    
    func extractPath (in bounds: CGRect, expect scale: CGFloat) -> CGMutablePath {
        let lettersPath = CGMutablePath.init()
                let path = CGPath(rect: CGRect(origin: .zero, size: CGSize(bounds.width, bounds.height * 2)), transform: nil)
                let frameSetter = CTFramesetterCreateWithAttributedString(self)
                let ctFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
                
                guard let lines = CTFrameGetLines(ctFrame) as? [CTLine] else { return lettersPath }
                let numLines = lines.count
                var points: Array<CGPoint> = Array.init(repeating: CGPoint.zero, count: numLines)
                CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), &points)
                
                /// foreach line
                for (lineIndex, line) in lines.reversed().enumerated() {
                    let range = CTLineGetStringRange(line)
                    var flushFactor = CGFloat.zero
                    var penOffset = CGFloat.zero
                    
                    if let paragraphStyleData = self.attribute(NSAttributedString.Key.paragraphStyle, at: range.location, effectiveRange: nil), let paragraphStyle = paragraphStyleData as? NSParagraphStyle {
                        let alignment = paragraphStyle.alignment
                        flushFactor = alignment.flushFactor
                        penOffset = CGFloat(CTLineGetPenOffsetForFlush(line, flushFactor, Double(bounds.width)))
                    }
                    guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else { continue }
                    
                    /// foreach run
                    for run in runs {
                        guard let attributes = CTRunGetAttributes(run) as? [String: AnyObject], let font = attributes[kCTFontAttributeName as String] as? UIFont else {
                            continue
                        }
                        let baseline = font.lineHeight - font.ascender
                        let numGlyph = CTRunGetGlyphCount(run)
                        let lineOffset = CGFloat(lineIndex) * font.lineHeight
                        
                        /// foreach glyph
                        for glyphIndex in 0..<numGlyph {
                            let glyphRange = CFRangeMake(glyphIndex, 1)
                            var glyph = CGGlyph()
                            var position = CGPoint()
                            
                            CTRunGetGlyphs(run, glyphRange, &glyph)
                            CTRunGetPositions(run, glyphRange, &position)
                            
                            position.y += lineOffset + baseline
                            position.x += penOffset
                            
                            if let letter = CTFontCreatePathForGlyph(font, glyph, nil) {
                                let transform = CGAffineTransform(translationX: position.x, y: position.y)
                                lettersPath.addPath(letter, transform: transform)
                            }
                        }
                    }
                }
                
                return lettersPath
    }
    
    func extractImage(in bounds: CGRect, expect scale: CGFloat) -> UIImage? {
        /// Get data to draw multiple line
        let path = CGPath(rect: CGRect(origin: .zero, size: CGSize(bounds.width, bounds.height * 2)), transform: nil)
        let frameSetter = CTFramesetterCreateWithAttributedString(self)
        let ctFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
        guard let lines = CTFrameGetLines(ctFrame) as? [CTLine] else { return nil }
        let numLines = lines.count
        var points: Array<CGPoint> = Array.init(repeating: CGPoint.zero, count: numLines)
        CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), &points)
        
        /// Prepare context
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        let flipVerticalTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: bounds.size.height * 2)
        context.concatenate(flipVerticalTransform)
        
        /// Draw
        CTFrameDraw(ctFrame, context)
        
        /// Export
        let letterImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return letterImage
    }
}

extension NSTextAlignment {
    var flushFactor: CGFloat {
        switch self {
        case .left:
            return 0
        case .center:
            return 0.5
        case .right:
            return 1
        default:
            return 0
        }
    }
}
