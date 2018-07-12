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
    
    @IBOutlet var tvOrderList: NSTableView!
    
    
    var mBuffer : Int = 0
    var mBandWidth : Int = 0
    var mRepeatCnt : Int = 0
    
    var data : FileInfo!
    
    var graph1 : Graph?
    
    let strLabels : [String] = [/*0th*/"th", /*1st*/"st", /*2nd*/"nd", /*3rd*/"rd", /*4th*/"th",
        /*5th*/"th", /*6th*/"th", /*7th*/"th", /*8th*/"th", /*9th*/"th"]
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func refresh() {
        tvOrderList.reloadData()
    }
}

extension MainCell: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if (data == nil) {
            return 0
        }
        
        return data!.freq_order_visible.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cell: NSView!

        cell = cellForMain(tableView, viewFor: tableColumn, row: row)
        return cell
    }
    
    
    func cellForMain(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FreqOrderCell"), owner: self) as! FreqOrderCell
        
        cell.chkFreqOrder.title = String(row + 1) + strLabels[(row + 1) % 10] + "Frequency order:";
        cell.chkFreqOrder.state = data!.freq_order_visible[row] ? .on : .off
        
        cell.chkFreqOrder.target = self
        cell.chkFreqOrder.tag = row
        cell.chkFreqOrder.action = #selector(onFreqOrderChecked)
        return cell
    }
    
    @IBAction func onFreqOrderChecked(_ sender: NSButton) {
        let idx = sender.tag
        
        if data != nil {
            data!.freq_order_visible[idx] = sender.state == .on
        }
        
        let dic = data.getFrequencies(freqOrders: data.freq_order_visible, bufferSize: mBuffer, bandWidth: mBandWidth, repeatCnt: mRepeatCnt)
        
        var freq = "", repeatation = ""
        
        for i in 0..<dic.count {
            let freq_val = dic[i][0]
            let repeat_val = dic[i][1]
            
            freq += String(format: "Frequency (%d) = %d Hz\n", i + 1, freq_val)
            repeatation += String(format: "Frequency (%d) = %d times\n", i + 1, repeat_val)
        }
        freq = String(freq.dropLast())
        repeatation = String(repeatation.dropLast())
        
        lbFreq.stringValue = freq
        lbRepeat.stringValue = repeatation
        
        graph1!.checkedList = data!.freq_order_visible
        graph1!.freq_data_to_show = dic
        graph1!.display()

    }
    
}
