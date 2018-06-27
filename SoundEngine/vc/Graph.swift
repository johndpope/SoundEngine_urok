//
//  Graph.swift
//  SoundEngine
//
//  Created by Snow on 19/5/2018.
//  Copyright © 2018 Snow. All rights reserved.
//

import Foundation
import Cocoa

class Graph: NSView {
    
    var mType = EGraphType.impulse
    
    //. impulse
    var mImpluse = [Int]()
    
    //. frequency graph
    var mFreqs = [[[Int]]]()
    
    //. histogram graph
    var mHistogram = [Float]()
    var mMaxLen = 0
    
    var band_width = 10
    
    var freq_data_to_show : [[Int]]?
    
    var checkedList : [Bool]?
    
    override func draw(_ rect: NSRect) {
        
        switch mType {
        case .impulse:
            drawImpulse(rect)
            
        case .frequency:
            drawFreq(rect)
            
        case .histogram:
            drawHistogram(rect)
        }
    }
    
    func drawImpulse(_ rect: NSRect) {
        let width = rect.width
        let height = rect.height
        let y0 = height / 2
        let lineWidth = CGFloat(2)
        
        NSColor.white.set()
        NSBezierPath.fill(rect)
        NSColor.black.set()
        
        let xform = NSAffineTransform()
        xform.translateX(by: 0, yBy: y0)
        //xform.rotate(byDegrees: 45)
        //xform.scaleX(by: 1, yBy: -1)
        xform.concat()
        
        //. center line
        let path = NSBezierPath()
        path.lineWidth = lineWidth
        path.move(to: CGPoint(x: 0, y: 0))
        path.line(to: CGPoint(x: width, y: 0))
        
        //. impulse
        let max = CGFloat(80)
        for i in 0..<mImpluse.count {
            let x = lineWidth / 2 + CGFloat(i) * (width - lineWidth) / CGFloat(mImpluse.count - 1)
            let y = CGFloat(mImpluse[i]) / max * y0
            path.move(to: CGPoint(x: x, y: y))
            path.line(to: CGPoint(x: x, y: -y))
        }
        path.stroke()
        
        xform.invert()
        xform.concat()
    }
    
    func imgData(using fileType: NSBitmapImageRep.FileType = .png, properties: [NSBitmapImageRep.PropertyKey : Any] = [:]) -> Data {
        let imageRepresentation = bitmapImageRepForCachingDisplay(in: bounds)!
        cacheDisplay(in: bounds, to: imageRepresentation)
        return imageRepresentation.representation(using: fileType, properties: properties)!
    }
    
    func drawFreq(_ rect: NSRect) {
        let left = CGFloat(40)
        let width = rect.width - left
        var height = rect.height
        let bottom = CGFloat(45)
        height -= bottom
        let right = CGFloat(90)
        let max_top = CGFloat(20)
        let scaleY = 5
        
        let xform = NSAffineTransform()
        xform.translateX(by: left, yBy: bottom)
        xform.concat()
        
        //. coordinate
        let path = NSBezierPath()
        path.lineWidth = 2
        path.move(to: CGPoint(x: 0, y: 0))
        path.line(to: CGPoint(x: width, y: 0))
        path.move(to: CGPoint(x: 0, y: 0))
        path.line(to: CGPoint(x: 0, y: height))
        path.stroke()
        
        let max_item = mFreqs[0].max(by: { (a, b) -> Bool in
            return a[1] < b[1]
        })
        let fMaxVal = max_item?[1] ?? 0
        
        let atts: [NSAttributedStringKey: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: NSColor.blue,
            //.underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
            //.backgroundColor: NSColor.green,
        ]
        
        for i in 0...scaleY {
            let str = String(format: "%d", fMaxVal * i / scaleY )
            str.draw(at: NSMakePoint(-5 - 5 * CGFloat(str.count), (height - max_top) * CGFloat(i) / CGFloat(scaleY) - 5), withAttributes: atts)
        }
        
        var freq_list = [Int]()
        var j = CGFloat(0)
        
        if checkedList == nil {
            return
        }
        
        for idx in 0..<checkedList!.count {
            
            if !checkedList![idx] {
                continue;
            }
            
            let mFreq = mFreqs[idx]
            
            //. graph & text
            let cnt = mFreq.count
            let lineWidth = (width - right) / CGFloat(cnt)
            var clr = randomColor(alpha: 1)
            var prev_freq = 0
            
            for i in 0..<cnt {
                var freq = mFreq[i][0]
                var amp = mFreq[i][1]
                
                if (freq_data_to_show != nil && freq > 0) {
                    var bFound = false
                    for j in 0..<freq_data_to_show!.count {
                        if abs(freq - freq_data_to_show![j][0]) < band_width {
                            bFound = true
                            break
                        }
                    }
                    
                    if (!bFound) {
                        continue
                    }
                }
                
                if freq > 0 && prev_freq != freq {
                    //print(String(format: "--- prev: %d,   freq: %d", prev_freq, freq))
                    prev_freq = freq
                    clr = randomColor(alpha: 1, val: freq)
                    
                    let xform1 = NSAffineTransform()
                    xform1.rotate(byDegrees: 90)
                    xform1.concat()
                    
                    let str = String(format: "%dHz", mFreq[i][0])
                    if (mFreq == mFreqs[0]) {
                        str.draw(at: NSMakePoint(-7 - 5 * CGFloat(str.count), -CGFloat(i) * lineWidth - 7), withAttributes: atts)
                    }
                    
                    xform1.invert()
                    xform1.concat()
                    
                    if freq_list.index(of: freq) == nil {
                        freq_list.append(freq)
                        let atts1: [NSAttributedStringKey: Any] = [
                            .font: NSFont.systemFont(ofSize: 11),
                            .foregroundColor: NSColor.blue,
                            //.underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
                            //.backgroundColor: NSColor.green,
                        ]
                        str.draw(at: NSMakePoint(width - right + 10, height - j * 15 - 12), withAttributes: atts1)
                        
                        clr.set()
                        NSBezierPath.fill(NSRect(x: width - 25, y: height - j * 15 - 11, width: 25, height: 12))
                        j += 1
                    }
                }
                
                clr.set()
                let x = CGFloat(1 + i * 2) * lineWidth / 2
                let y = fMaxVal != 0 ? CGFloat(amp) / CGFloat(fMaxVal) * (height - max_top) : 0
                let path1 = NSBezierPath()
                path1.lineWidth = ceil(lineWidth)
                path1.move(to: CGPoint(x: x, y: 0))
                path1.line(to: CGPoint(x: x, y: y))
                path1.stroke()
            }
        }
        
        xform.invert()
        xform.concat()
        NSColor.black.set()
    }
    
    func drawHistogram(_ rect: NSRect) {
        let maxX = mHistogram.count
        let maxY = 1.0
        let splitX = 6
        let splitY = 10
        
        let marginX = CGFloat(35)
        let marginY = CGFloat(30)
        let width = rect.width - marginX - 20
        let height = rect.height - marginY - 5
        let y0 = height / 2
        
        let xform = NSAffineTransform()
        xform.translateX(by: marginX, yBy: marginY)
        xform.concat()
        
        //. border
        let path = NSBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.line(to: CGPoint(x: width, y: 0))
        path.move(to: CGPoint(x: width, y: 0))
        path.line(to: CGPoint(x: width, y: height))
        path.move(to: CGPoint(x: width, y: height))
        path.line(to: CGPoint(x: 0, y: height))
        path.move(to: CGPoint(x: 0, y: height))
        path.line(to: CGPoint(x: 0, y: 0))
        
        var atts: [NSAttributedStringKey: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
        ]
        var str = "Time (Samples)"
        str.draw(at: NSMakePoint(width / 2 - 40, -30), withAttributes: atts)
        
        let xform1 = NSAffineTransform()
        xform1.rotate(byDegrees: 90)
        xform1.concat()
        
        str = "Amplitude"
        str.draw(at: NSMakePoint(height / 2 - 25, 25), withAttributes: atts)

        xform1.invert()
        xform1.concat()
        
        let delta = CGFloat(3)
        atts = [
            .font: NSFont.systemFont(ofSize: 8),
        ]
        for i in 0...splitX {
            let x = width * CGFloat(i) / CGFloat(splitX)
            path.move(to: CGPoint(x: x, y: 0))
            path.line(to: CGPoint(x: x, y: delta))
            path.move(to: CGPoint(x: x, y: height))
            path.line(to: CGPoint(x: x, y: height - delta))

            str = "\(i * maxX / splitX)"
            str.draw(at: NSMakePoint(x - 2.5 * CGFloat(str.count), -13), withAttributes: atts)
        }

        for i in 0...splitY {
            let y = height * CGFloat(i) / CGFloat(splitY)
            path.move(to: CGPoint(x: 0, y: y))
            path.line(to: CGPoint(x: delta, y: y))
            path.move(to: CGPoint(x: width, y: y))
            path.line(to: CGPoint(x: width - delta, y: y))

            str = "\(Double(i * 2 - splitY) * maxY / Double(splitY))"
            str.draw(at: NSMakePoint(-5 * CGFloat(str.count), y - 6), withAttributes: atts)
        }
        
        //. histogram
        let xform2 = NSAffineTransform()
        xform2.translateX(by: 0, yBy: y0)
        xform2.concat()
        
        NSColor.blue.set()
        let path1 = NSBezierPath()
        
        //. get max & min
        let _width = Int(width)
        let deltaT = Int(mHistogram.count / _width)
        var hist_list = [[Float]](repeating: [0, 0], count: _width)
        for i in 0..<_width {
            for j in 0..<deltaT {
                let idx = i * deltaT + j
                let v = mHistogram[idx]
                hist_list[i][0] = Float.maximum(hist_list[i][0], v)
                hist_list[i][1] = Float.minimum(hist_list[i][1], v)
            }
            hist_list[i][0] = hist_list[i][0] // powf(2, 15)
            hist_list[i][1] = hist_list[i][1] // powf(2, 15)
        }
        
        for i in 0..<hist_list.count {
            path1.move(to: CGPoint(x: CGFloat(i), y: CGFloat(hist_list[i][0]) * y0))
            path1.line(to: CGPoint(x: CGFloat(i), y: CGFloat(hist_list[i][1]) * y0))
        }
        path1.stroke()
        
        xform2.invert()
        xform2.concat()
        
        NSColor.black.set()
        path.stroke()
        
        xform.invert()
        xform.concat()
    }
    
    func randomColor(alpha: CGFloat = 1, val: Int = 0) -> NSColor {
        let red = CGFloat(((val / band_width) * band_width * 30) % 255) / 255 //CGFloat(drand48())
        let green = CGFloat(((val / band_width) * band_width * 50) % 255) / 255 //CGFloat(drand48())
        let blue = CGFloat(((val / band_width) * band_width * 90) % 255) / 255 //CGFloat(drand48())
        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
}
