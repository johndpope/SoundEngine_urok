//
//  MainCell.swift
//  SoundEngine
//
//  Created by Snow on 17/5/2018.
//  Copyright © 2018 Snow. All rights reserved.
//

import Cocoa

class MainCell: NSTableCellView {
    
    @IBOutlet var lbFile: NSTextField!
    @IBOutlet var lbFreq: NSTextField!
    @IBOutlet var lbRepeat: NSTextField!
    @IBOutlet var lbTotal: NSTextField!
    @IBOutlet var lbStrong: NSTextField!
    @IBOutlet var lbLong: NSTextField!
    @IBOutlet var lbMaxAmp: NSTextField!
    @IBOutlet var lbEtc: NSTextField!
    @IBOutlet var vwGraph1: NSView!
    @IBOutlet var vwGraph2: NSView!
    @IBOutlet var btnClose: NSButton!
    @IBOutlet var btnPlay: NSButton!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
