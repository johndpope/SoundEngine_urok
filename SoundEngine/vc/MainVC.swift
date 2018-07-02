//
//  MainVC.swift
//  SoundEngine
//
//  Created by Snow on 16/5/2018.
//  Copyright © 2018 Snow. All rights reserved.
//

import Cocoa
import AudioKit

enum EGraphType {
    case impulse, frequency, histogram
}

let IS_UROK_APP = true

class MainVC: NSViewController, AVAudioPlayerDelegate {
    
    let MAX_FREQ_ORDER = 10
    
    @IBOutlet weak var vwBlock1: NSView!
    @IBOutlet weak var vwBlock2: NSView!
    @IBOutlet weak var vwBlock3: NSView!
    
    @IBOutlet var btnImport: NSButton!
    @IBOutlet var btnMic: NSButton!
    
    @IBOutlet var tfMicTime: NSTextField!
    @IBOutlet var tfMicThreshold: NSTextField!
    @IBOutlet var cbSoundType: NSComboBox!
    
    @IBOutlet var tfAnalysisSecs: NSTextField!
    
    @IBOutlet var tfRate: NSTextField!
    @IBOutlet var tfBuffer: NSTextField!
    @IBOutlet var tfFreqFrame: NSTextField!
    @IBOutlet var tfThreshold: NSTextField!
    @IBOutlet var tfBand: NSTextField!
    @IBOutlet var tfRepeat: NSTextField!
    
    @IBOutlet var tvList: NSTableView!
    
    // Exporting data
    @IBOutlet weak var chkLabelName: NSButton!
    @IBOutlet weak var chkFrame: NSButton!
    @IBOutlet weak var chkFrequency: NSButton!
    @IBOutlet weak var chkAmplitude: NSButton!
    @IBOutlet weak var tfFrequencyOrder: NSTextField!
    
    // Download Graphs as PNG format
    @IBOutlet weak var chkFFTGraph: NSButton!
    @IBOutlet weak var chkAnalogGraph: NSButton!
    @IBOutlet weak var chkIndividualGraphs: NSButton!
    @IBOutlet weak var chkAllGraphs: NSButton!
    
    // For SoundEngine UROK
    @IBOutlet weak var vwSoundType: NSStackView!
    
    
    var mMicTime = 0
    var mMicThreshold = 0
    var mSoundType = ESoundType.doorbell
    
    var mAnalysisPeriod : Float = 3
    
    var mRate = 0
    var mBuffer = 0
    var mFreqFrame = 0
    var mThreshold = 0
    var mBandWidth = 0
    var mRepeatCnt = 0
    
    // Exporing CSV data environment
    var mCsvLabelName = true
    var mCsvFrame = true
    var mCsvFrquency = true
    var mCsvAmplitude = true
    var mFrequencyOrder = 3
    var mMaxFrameCnt = 0
    
    var mList = [FileInfo]()
    
    var mTimer: Timer!
    
    let strLabels : [String] = [/*0th*/"th", /*1st*/"st", /*2nd*/"nd", /*3rd*/"rd", /*4th*/"th",
                                       /*5th*/"th", /*6th*/"th", /*7th*/"th", /*8th*/"th", /*9th*/"th"]
    
    
    enum ERecMode: Int {
        case real_time, saved_data
    }
    
    enum ESoundType: Int {
        case doorbell, microwave_beeps, oven_timer_beeps, smoke_alarms, telephone_ringing
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initVC()
        
        if (IS_UROK_APP) {
            vwSoundType.isHidden = true
        }

        Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateHeaderUI), userInfo: nil, repeats: false)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()

    }

    //////////////////////////////////////////////////////////////////////
    // MARK: - Helper
    //////////////////////////////////////////////////////////////////////
    
    func initVC() {
        if (IS_UROK_APP) {
            mSoundType = .telephone_ringing
        } else {
            mSoundType = .doorbell
        }
        cbSoundType.selectItem(at: mSoundType.rawValue)
        
        tvList.delegate = self
        tvList.dataSource = self
        
    }
    
    @objc func updateHeaderUI() {
        if (IS_UROK_APP) {
            self.view.window!.title = "Sound Engine UROK"
        }

        vwBlock1.layer?.borderColor = CGColor.black
        vwBlock1.layer?.borderWidth = 1
        vwBlock2.layer?.borderColor = CGColor.black
        vwBlock2.layer?.borderWidth = 1
        vwBlock3.layer?.borderColor = CGColor.black
        vwBlock3.layer?.borderWidth = 1
    }
    
    func setStatus() {
        mAnalysisPeriod = tfAnalysisSecs.floatValue
        mRate = Int(tfRate.intValue)
        mMicTime = Int(tfMicTime.intValue)
        mMicThreshold = Int(tfMicThreshold.intValue)
        
        if (!IS_UROK_APP) {
            mSoundType = ESoundType(rawValue: cbSoundType.indexOfSelectedItem)!
        }
        mBuffer = Int(tfBuffer.intValue)
        mFreqFrame = Int(tfFreqFrame.intValue)
        if (mFreqFrame > MAX_FREQ_ORDER) {
            mFreqFrame = MAX_FREQ_ORDER
            tfFreqFrame.intValue = Int32(mFreqFrame)
        }
        mThreshold = Int(tfThreshold.intValue)
        mBandWidth = Int(tfBand.intValue)
        mRepeatCnt = Int(tfRepeat.intValue)
        
        mFrequencyOrder = Int(tfFrequencyOrder.intValue)
        if mFrequencyOrder <= 0 {
            mFrequencyOrder = 1
        } else if mFrequencyOrder > MAX_FREQ_ORDER {
            mFrequencyOrder = MAX_FREQ_ORDER
        }
    }
    
    func processAudio(_ dic : [[Int]], info: FileInfo, max_len : Int) {
        var long_frame = 0
        var long_freq = 0
        var max_freq = 0, min_freq = 0
        
        for item in dic {
            if long_frame < item[1] {
                long_frame = item[1]
                long_freq = item[0]
            }
            
            max_freq = max(max_freq, item[0])
            min_freq = min_freq == 0 ? item[0] : min(min_freq, item[0])
        }
        
        let dic_max = bridgeClass.get_max_freqs_vals(0, Int32(max_len / self.mBuffer)) as! [[Int]]
        
        var strong_freq = 0, max_amp_of_freq = 0
        for item in dic_max {
            if max_amp_of_freq < item[1] {
                strong_freq = item[0]
                max_amp_of_freq = item[1]
            }
        }
        
        info.strong_freq = strong_freq
        info.long_freq = long_freq
        info.max_amp_of_freq = max_amp_of_freq
        
        info.max_freq_val_data.removeAll()
        info.max_freq_val_data.append(dic_max)
        for idx in 1..<MAX_FREQ_ORDER {
            let dic_max1 = bridgeClass.get_max_freqs_vals(Int32(idx), Int32(max_len / self.mBuffer)) as! [[Int]]
            info.max_freq_val_data.append(dic_max1)
        }
        
        info.freq_data = dic
        
        info.total_frames = 0
        
        for i in 0..<info.freq_data.count {
            let repeat_val = info.freq_data[i][1]
            info.total_frames += repeat_val
        }
        
        info.freq_order_visible.removeAll()
        for i in 0..<mFreqFrame {
            info.freq_order_visible.append(true)
        }
        
        if mSoundType == .doorbell { //. ding & dong
            var ding_freq = 0, ding_start = 0, ding_end = 0, ding_frames = 0, ding_prev_amp = 0, ding_dec = 0 // false: nono/inc - No, true: dec - Yes
            var dong_freq = 0, dong_start = 0, dong_end = 0, dong_frames = 0, dong_prev_amp = 0, dong_dec = 0 // false: inc - No, true: dec - Yes
            var max_dong_freq = 0, max_dong_frames = 0, max_dong_dec = 0
            
            for i in 0..<dic_max.count {
                let item = dic_max[i]
                let freq = item[0]
                let amp = item[1]
                
                
                if dong_freq != 0 && (freq == 0 || i == dic_max.count - 1 || abs(freq - dong_freq) > mBandWidth) {
                    if max_dong_frames < dong_frames {
                        max_dong_frames = dong_frames
                        max_dong_freq = dong_freq
                        max_dong_dec = dong_dec
                    }
                } else if (freq == 0) {
                    continue;
                }
                
                // if dic_max[i+1][0] != 0 && freq != dic_max[i+1][0] { continue }
                
                if ding_freq == 0 || (ding_frames <= 1 && abs(freq - ding_freq) > mBandWidth) {
                    ding_freq = freq
                    ding_start = i
                    ding_dec = 0
                    ding_prev_amp = amp
                    ding_frames = 1
                } else if ding_freq == freq {
                    ding_end = i
                    ding_frames = ding_end - ding_start + 1
                    ding_dec = ding_dec + ((ding_prev_amp >= amp) ? 1 : 0)
                    ding_prev_amp = amp
                } else if dong_freq == 0 || abs(freq - dong_freq) > mBandWidth {
//                    ding_end = i
//                    ding_frames = ding_end - ding_start
                    dong_freq = freq
                    dong_start = i
                    dong_dec = 0
                    dong_prev_amp = amp
                    dong_frames = 1
                } else if abs(freq - dong_freq) <= mBandWidth {
                    dong_end = i
                    dong_frames = dong_end - dong_start + 1
                    dong_dec = dong_dec + ((dong_prev_amp >= amp) ? 1 : 0)
                    dong_prev_amp = amp
                }
            }
            
            let delta = 6
            if ding_freq > 0 && max_dong_freq == 0 {
                max_dong_freq = ding_freq
                max_dong_frames = ding_frames - delta
                ding_frames = delta
                max_dong_dec = max_dong_frames
            }
            
            info.ding_freq = ding_freq; info.ding_frames = ding_frames; info.ding_dec = ding_dec >= (ding_frames - 2)
            info.dong_freq = max_dong_freq; info.dong_frames = max_dong_frames; info.dong_dec = max_dong_dec >= (max_dong_frames - 2)
        } else { //. max amplitude & beep & silent & telephone ringing
            var min_amplitude = 0
            let chk_cnt = 2
            var chk_ok = false, continue_ok = false
            var zero_cnt = 0, set_zero = true, start_zero = 0, end_zero = 0
            var nonzero_cnt = 0, set_nonzero = false, start_nonzero = 0, end_nonzero = 0
            
            for i in 0..<dic_max.count {
                let item = dic_max[i]
                
                if item[1] > 0 {
                    min_amplitude = min_amplitude == 0 ? item[1] : min(min_amplitude, item[1])
                }
                
                var isValid = false
                
                if (item[1] == 0) {
                    isValid = false
                } else if (item[1] >= info.max_amp_of_freq * 20 / 100) {
                    isValid = true
                } else {
                    for i in 0..<info.freq_data.count {
                        let freq_val = info.freq_data[i][0]
                        let repeat_val = info.freq_data[i][1]
                        
                        if (repeat_val >= info.total_frames * 2 / 10) {
                            if abs(item[0] - freq_val) <= mBandWidth {
                                isValid = true
                                break
                            }
                        }
                    }
                }
                
                if !isValid {
                    if set_nonzero {
                        set_nonzero = false
                        end_nonzero = i
                        set_zero = true
                        zero_cnt += 1
                        start_zero = i
                    } else if !set_zero {
                        set_zero = true
                        zero_cnt += 1
                        start_zero = i
                    }
                } else {
                    if set_zero {
                        set_zero = false
                        end_zero = i
                        set_nonzero = true
                        nonzero_cnt += 1
                        
                        if nonzero_cnt == chk_cnt {
                            chk_ok = true
                            break
                        }

                        start_nonzero = i
                    } else if i == dic_max.count - 1 && set_nonzero {
                        continue_ok = true
                        end_nonzero = i
                    }
                }
            }
            
            var beep_frames = 0, silent_frames = 0, continue_beep_times = Float(0)
            if chk_ok {
                beep_frames = end_nonzero - start_nonzero
                silent_frames = end_zero - start_zero
            } else if nonzero_cnt == 1 { //. continuous beep
                continue_ok = true
                continue_beep_times = Float(end_nonzero - start_nonzero) * Float(self.mBuffer) / Float(max_len)
            }
            
            //. telephone ring
            var instability = 0
            if mSoundType == .telephone_ringing {
                var tel_start = 0, tel_end = 0, total_amp = 0, avg_amp = Float(0)
                for i in 0..<dic_max.count {
                    let amp = dic_max[i][1]
                    if amp > 0 {
                        if total_amp == 0 {
                            tel_start = i
                            total_amp += amp
                        } else {
                            tel_end = i
                            total_amp += amp
                        }
                    } else if total_amp > 0 {
                        tel_end = i
                        break
                    }
                }
                
                if tel_start < tel_end {
                    avg_amp = Float(total_amp) / Float(tel_end - tel_start)
                    for i in tel_start..<tel_end - 1 {
                        let amp = dic_max[i][1]
                        let amp1 = dic_max[i + 1][1]
                        if (Float(amp) > avg_amp && Float(amp1) < avg_amp) ||
                            (Float(amp) < avg_amp && Float(amp1) > avg_amp) {
                            instability += 1
                        }
                    }
                }
            }
            
            info.max_freq = max_freq
            info.min_freq = min_freq
            info.min_amplitude = min_amplitude
            info.continue_ok = continue_ok
            info.beep_frames = beep_frames
            info.silent_frames = silent_frames
            info.continue_beep_times = continue_beep_times
            info.instability = instability
        }
        
        let results = bridgeClass.get_other_results();
        info.min_amp_for_silent = (results![0] as! NSNumber).floatValue
        info.max_amp_for_silent = (results![1] as! NSNumber).floatValue
        info.max_value = (results![2] as! NSNumber).floatValue

    }
    
    func analyseAudio(_ info: FileInfo, new: Bool = false) {
        guard !info.recorded else { return }
        
//            let file1 = EZAudioFile(url: info.file_url)
        let file = try? AKAudioFile(forReading: info.file_url)
        let data = file!.pcmBuffer.floatChannelData!
        
        var max_len = Int(file!.pcmBuffer.frameLength)
        if (mAnalysisPeriod > 0) {
            let analysisLen = Int(mAnalysisPeriod * file!.sampleRate)
            if (analysisLen < max_len) {
                max_len = analysisLen;
            }
        }
        
        bridgeClass.set_g_pDetectMgr_SAMPLE_FREQ(Int32(file!.sampleRate), Int32(self.mBuffer))
        
        let dic = bridgeClass.get_g_pDetectMgr_ProcessFile(
            data[0], Int32(max_len), Int32(self.mBuffer), Int32(mFreqFrame),
            Int32(self.mThreshold), Int32(self.mBandWidth), Int32(self.mRepeatCnt))! as! [[Int]]
        
        processAudio(dic, info: info, max_len: max_len)
        
        //. histogram
        var histogram_data = [Float](repeating: 0, count: max_len)
        for i in 0..<max_len {
            histogram_data[i] = data[0][i]
        }
        
        info.histogram = histogram_data
        if new {
            self.mList.append(info)
        }
        self.tvList.reloadData()
    
        bridgeClass.terminateEngine();
    }
    
    
    @objc func updateRecInfo() {
        let max_len = mRate * mMicTime
        let dic = bridgeClass.get_g_pDetectMgr_ProcessRec()! as! [[Int]]
        
        let dic_impulse = bridgeClass.get_impulse_vals() as! [Int]
//        let graph = Graph(frame: vwImpuls.bounds)
//        graph.band_width = mBandWidth
//        graph.mType = .impulse
//        graph.mImpluse = dic_impulse
//        vwImpuls.addSubview(graph)
        
        var info: FileInfo
        let exist = mList.count > 0 && mList[0].recorded
        if exist {
            info = mList[0]
        } else {
            info = FileInfo()
            info.recorded = true
            info.file_name = "Recording..."
        }
        
        processAudio(dic, info: info, max_len: max_len)
        
        //. histogram
        var histogram_data = [Float](repeating: 0, count: max_len)
        let tmp = bridgeClass.get_g_fRecBuf()!
        for i in 0..<max_len {
            histogram_data[i] = tmp[i]
        }
        info.histogram = histogram_data
        
        if exist {
            tvList.reloadData(forRowIndexes: IndexSet(integer: 0), columnIndexes: IndexSet(integer: 0))
            tvList.reloadData(forRowIndexes: IndexSet(integer: mList.count), columnIndexes: IndexSet(integer: 0))
        } else {
            mList.insert(info, at: 0)
            tvList.reloadData()
        }
    }
    
    func makeCSV(_ info: FileInfo) -> String {
        // Make CSV String From sound file
        var strResult : String = ""
        
        let file = try? AKAudioFile(forReading: info.file_url)
        let data = file!.pcmBuffer.floatChannelData!
        
        var max_len = Int(file!.pcmBuffer.frameLength)
        if (mAnalysisPeriod > 0) {
            let analysisLen = Int(mAnalysisPeriod * file!.sampleRate)
            if (analysisLen < max_len) {
                max_len = analysisLen;
            }
        }
        
        bridgeClass.set_g_pDetectMgr_SAMPLE_FREQ(Int32(file!.sampleRate), Int32(self.mBuffer))
        let dic = bridgeClass.get_g_pDetectMgr_ProcessFile(
            data[0], Int32(max_len), Int32(self.mBuffer), Int32(self.mFrequencyOrder),
            Int32(self.mThreshold), Int32(self.mBandWidth), Int32(self.mRepeatCnt))! as! [[Int]]

        var frameCnt = max_len / self.mBuffer
        
        var dic_maxs : [[[Int]]] = []
        var startIdx = frameCnt - 1
        var endIdx = 0
        
        for order in 0..<mFrequencyOrder {
            var dic_max = bridgeClass.get_max_freqs_vals(Int32(order), Int32(frameCnt)) as! [[Int]]

            // Remove unnecessary frequencies
            for i in 0..<frameCnt {
                var bFound = false
                let freq = dic_max[i][0]
                for j in 0..<dic.count {
                    if abs(freq - dic[j][0]) < mBandWidth {
                        bFound = true
                        break
                    }
                }
                if (!bFound) {
                    dic_max[i][0] = 0
                    dic_max[i][1] = 0
                }
            }
            
            dic_maxs.append(dic_max)
            
            // get start index
            for i in 0..<frameCnt {
                if dic_max[i][0] != 0 {
                    if (i < startIdx) {
                        startIdx = i
                    }
                    break;
                }
            }

            // get end index
            for i in 0..<frameCnt {
                let idx = frameCnt - 1 - i
                if dic_max[idx][0] != 0 {
                    if (idx > endIdx) {
                        endIdx = idx
                    }
                    break;
                }
            }
        }
        
        if (startIdx > endIdx) {
            return "\n"
        }
        
        frameCnt = endIdx-startIdx+1
        
        if (mAnalysisPeriod > 0) {
            let analysisLen = Int(mAnalysisPeriod * file!.sampleRate)
            if (analysisLen < frameCnt) {
                frameCnt = analysisLen;
            }
        }
        
        if frameCnt > mMaxFrameCnt {
            mMaxFrameCnt = frameCnt
        }

        for order in 0..<mFrequencyOrder {
            let dic_max = dic_maxs[order]
            var strLineFreq = ""
            var strLineAmp = ""
            
            // Make Line for each order frequency
            for i in 0...frameCnt{
                if (i == 0) {
                    if mCsvLabelName {
                        if (order == 0) {
                            if mCsvFrquency {
                                strLineFreq = info.file_name!
                            } else if mCsvAmplitude {
                                strLineAmp = info.file_name!
                            }
                        }
                        strLineFreq = strLineFreq + ","
                        strLineAmp = strLineAmp + ","
                    }
                } else {
                    strLineFreq = strLineFreq + String(dic_max[i-1+startIdx][0]) + ","
                    strLineAmp = strLineAmp + String(dic_max[i-1+startIdx][1]) + ","
                }
            }
            
            if (mCsvFrquency) {
                strResult = strResult + strLineFreq + "\n"
            }
            if (mCsvAmplitude) {
                strResult = strResult + strLineAmp + "\n"
            }
        }
        return strResult
    }
    
    func exportGraphToPng(info : FileInfo, dirUrl : URL) {
        
        let data = FileInfo()
        data.file_url = info.file_url
        data.file_name = info.file_name
        
        let file = try? AKAudioFile(forReading: data.file_url)
        let soundData = file!.pcmBuffer.floatChannelData!
        
        var max_len = Int(file!.pcmBuffer.frameLength)
        if (mAnalysisPeriod > 0) {
            let analysisLen = Int(mAnalysisPeriod * file!.sampleRate)
            if (analysisLen < max_len) {
                max_len = analysisLen;
            }
        }
        
        bridgeClass.set_g_pDetectMgr_SAMPLE_FREQ(Int32(file!.sampleRate), Int32(self.mBuffer))
        
        let dic = bridgeClass.get_g_pDetectMgr_ProcessFile(
            soundData[0], Int32(max_len), Int32(self.mBuffer), Int32(mFrequencyOrder),
            Int32(self.mThreshold), Int32(self.mBandWidth), Int32(self.mRepeatCnt))! as! [[Int]]
        
        processAudio(dic, info: data, max_len: max_len)
        
        bridgeClass.terminateEngine();

        
        if self.chkFFTGraph.state == .on {
            
            let rc = NSRect(x: 0, y: 0, width: 1000, height: 210)
            let graph = Graph(frame: rc)
            
            graph.band_width = mBandWidth
            graph.mType = .frequency
            graph.mFreqs = data.max_freq_val_data
            graph.freq_data_to_show = data.freq_data
            
            var checked_list : [Bool] = []
            for i in 0..<mFrequencyOrder {
                checked_list.append(false)
            }
            
            if chkIndividualGraphs.state == .on {
                // Export individual graph for each frequency order
                for i in 0..<mFrequencyOrder {
                    
                    for j in 0..<mFrequencyOrder {
                        checked_list[j] = false
                    }
                    checked_list[i] = true
                    
                    graph.checkedList = checked_list
                    
                    let grass = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(rc.width), pixelsHigh: Int(rc.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
                    var ctx = NSGraphicsContext(bitmapImageRep: grass!)
                    NSGraphicsContext.current = ctx
                    graph.draw(rc)
                    let imgData = graph.imgData()
                    let url = dirUrl.appendingPathComponent(data.file_name + "_fft_" + String(i+1) + ".png")
                    do {
                        try imgData.write(to: url)
                    } catch let error {
                        NSLog(error.localizedDescription)
                    }
                }
            }
            
            if chkAllGraphs.state == .on {
                
                for j in 0..<mFrequencyOrder {
                    checked_list[j] = true
                }
                
                graph.checkedList = checked_list
                
                let grass = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(rc.width), pixelsHigh: Int(rc.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
                var ctx = NSGraphicsContext(bitmapImageRep: grass!)
                NSGraphicsContext.current = ctx
                graph.draw(rc)
                let imgData = graph.imgData()
                let url = dirUrl.appendingPathComponent(data.file_name + "_fft_all.png")
                do {
                    try imgData.write(to: url)
                } catch let error {
                    NSLog(error.localizedDescription)
                }
            }
        }
        
        if self.chkAnalogGraph.state == .on {
        
            let rc2 = NSRect(x: 0, y: 0, width: 678, height: 225)
            let graph2 = Graph(frame:rc2)
            graph2.mType = .histogram
            graph2.mHistogram = info.histogram
            
            let grass2 = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(rc2.width), pixelsHigh: Int(rc2.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
            var ctx2 = NSGraphicsContext(bitmapImageRep: grass2!)
            NSGraphicsContext.current = ctx2
            
            graph2.draw(rc2)
            let imgData2 = graph2.imgData()
            let url2 = dirUrl.appendingPathComponent(info.file_name + "_analog.png")
            do {
                try imgData2.write(to: url2)
            } catch let error {
                NSLog(error.localizedDescription)
            }
        }
    }
    
    //////////////////////////////////////////////////////////////////////
    // MARK: - Action
    //////////////////////////////////////////////////////////////////////
    
    @IBAction func importAction(_ sender: Any) {
        setStatus()
        
        let window = NSApplication.shared.windows[0]
        //let type = NSImage.imageTypes
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.message = "Import one or more wav & mp3 files"
        panel.allowedFileTypes = ["wav", "mp3"]
        panel.beginSheetModal(for: window) { (res) in
            if res == NSApplication.ModalResponse.OK {
                for url in panel.urls {
                    let name = url.lastPathComponent
                    
                    let info = FileInfo()
                    info.recorded = false
                    info.file_url = url
                    info.file_name = name
                    
                    self.analyseAudio(info, new: true)
                }
            }
        }
    }
    
    @IBAction func micAction(_ sender: Any) {
        if tfRate.stringValue.isEmpty {
            let alert = NSAlert()
            alert.messageText = "Please insert the Sampling rate!!"
            alert.informativeText = "Information Text"
            alert.addButton(withTitle: "Close")
            alert.runModal()
            return
        }
        
        setStatus()
        
        if (btnImport.isEnabled) {
            // TODO: set button status
            btnImport.isEnabled = false
            btnMic.title = "Stop"
            
            bridgeClass.set_g_pDetectMgr_SAMPLE_FREQ(Int32(mRate), Int32(mBuffer))
            // bridgeClass.recStart(Int32(mMicTime), Int32(mMicThreshold), 0, Int32(mFreqFrame), Int32(mThreshold), Int32(mBandWidth), Int32(mRepeatCnt))
            bridgeClass.recStart(Int32(mMicTime), Int32(mMicThreshold), 0, Int32(mFreqFrame), Int32(mMicThreshold), Int32(mBandWidth), Int32(mRepeatCnt))
            
            mTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateRecInfo), userInfo: nil, repeats: true)
        } else {
            if mTimer != nil {
                mTimer.invalidate()
                mTimer = nil
            }
            bridgeClass.terminateEngine();
            
            btnImport.isEnabled = true
            btnMic.title = "Listen via Mic"
        }
    }
    
    @IBAction func refreshAction(_ sender: Any) {
        setStatus()
        
        for item in mList {
            analyseAudio(item)
        }
    }
    
    @IBAction func closeAllAction(_ sender: NSButton) {
        mList.removeAll()
        tvList.reloadData()
    }
    
    @IBAction func onExportCSV(_ sender: Any) {
        
        setStatus()
        
        if mList.count == 0 {
            showAlert(message: "There is no data to export.")
            return;
        }
        
        mCsvLabelName = chkLabelName.state == .on
        mCsvFrame = chkFrame.state == .on
        mCsvFrquency = chkFrequency.state == .on
        mCsvAmplitude = chkAmplitude.state == .on
        
        let panel = NSSavePanel()
        panel.message = "Export CSV Format file"
        panel.nameFieldLabel = "CSV File"
        panel.canCreateDirectories = false
        panel.allowedFileTypes = ["csv"]
        if panel.runModal() == NSApplication.ModalResponse.OK, let url = panel.url {
            do {
                var content = ""
                
                mMaxFrameCnt = 0
                
                for item in mList {
                    content = content + self.makeCSV(item)
                }
                
                var strLine = ""
                if mCsvFrame {
                    for i in 0...mMaxFrameCnt {
                        if (i == 0) {
                            if mCsvLabelName {
                                strLine = strLine + "Label name,"
                            }
                        } else {
                            strLine = strLine + String(i) + ","
                        }
                    }
                    content = strLine + "\n" + content
                }
                
                try content.write(to: url, atomically: true, encoding: String.Encoding.utf8)
                
                showAlert(message: "Done!")
            } catch let err {
                showAlert(message:err.localizedDescription)
            }
        }
    }
    
    @IBAction func onDownloadGraphsPNG(_ sender: Any) {
        setStatus()
        
        let window = NSApplication.shared.windows[0]
        //let type = NSImage.imageTypes
        
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Save graphs"
        panel.allowsMultipleSelection = false
        panel.beginSheetModal(for: window) { (res) in
            if res == NSApplication.ModalResponse.OK {
                let url = panel.directoryURL
                for item in self.mList {
                    self.exportGraphToPng(info: item, dirUrl: url!)
                }
                
                self.showAlert(message: "Images has been saved in\n" + (url?.absoluteString)!)
            }
        }
    }
    
    @IBAction func closeAction(_ sender: NSButton) {
        let idx = sender.tag
        mList.remove(at: idx)
        tvList.reloadData()
    }
    
    var player: AVAudioPlayer!
    var file_url : String?
    var playing_idx : Int = -1
    
    @IBAction func playAction(_ sender: NSButton) {
        let data = mList[sender.tag]
        playing_idx = sender.tag
        do {
            if player != nil && player.isPlaying {
                player.stop()
            }
            
            if file_url == nil || file_url! != data.file_url.absoluteString {
                player = try AVAudioPlayer(contentsOf: data.file_url) //data.file_url
                player.delegate = self
                player.prepareToPlay()
                player.play()
                
                file_url = data.file_url.absoluteString
            } else {
                file_url = nil
            }
            
            tvList.reloadData(forRowIndexes: [sender.tag], columnIndexes: [0])
//            tvList.reloadData()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if (flag) {
            file_url = nil
            
            tvList.reloadData(forRowIndexes: [playing_idx], columnIndexes: [0])
            // tvList.reloadData()
        }
    }
    
    func showAlert(message : String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.runModal()
    }
}

extension MainVC: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return mList.count + (mList.count > 0 ? 1 : 0)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cell: NSView!
        if row == mList.count {
            cell = cellForAlgorithm(tableView, viewFor: tableColumn, row: row)
        } else {
            cell = cellForMain(tableView, viewFor: tableColumn, row: row)
        }
        return cell
    }
    
    func getDB(amp : Float) -> Float {
        return roundf(20 * (log10f(amp)));
    }
    
    func cellForMain(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MainCell"), owner: self) as! MainCell
        
        let data = mList[row]
        
        var freq = ""
        var repeatation = ""
        var freq_list = [Int]()
        var repeat_list = [Int]()
        
        for i in 0..<data.freq_data.count {
            let freq_val = data.freq_data[i][0]
            let repeat_val = data.freq_data[i][1]
            
            freq_list.append(freq_val)
            repeat_list.append(repeat_val)
            freq += String(format: "Frequency (%d) = %d Hz\n", i + 1, freq_val)
            repeatation += String(format: "Frequency (%d) = %d times\n", i + 1, repeat_val)
        }
        freq = String(freq.dropLast())
        repeatation = String(repeatation.dropLast())
        
        cell.data = data
        
        cell.lbFile.stringValue = data.file_name
        cell.lbFreq.stringValue = freq
        cell.lbRepeat.stringValue = repeatation
        cell.lbTotal.stringValue = String(format: "%d Frames", data.total_frames)
        cell.lbStrong.stringValue = String(format: "%d Hz", data.strong_freq)
        cell.lbLong.stringValue = String(format: "%d Hz", data.long_freq)
        cell.lbMaxAmp.stringValue = data.max_amp_of_freq > 0 ? String(format: "%d, %d dB", data.max_amp_of_freq, Int(getDB(amp: data.max_value))) : ""
        
        var etc_info = ""
        if mSoundType == .doorbell {
            etc_info = String(format: "> Ding Frames %@ Dong Frames\n\n" +
                "> Ding Decreasing Amplitude = %@\n" +
                "> Dong Decreasing Amplitude = %@",
                              data.ding_frames > data.dong_freq ? ">" : "<",
                              data.ding_dec ? "Yes" : "No",
                              data.dong_dec ? "Yes" : "No"
            )
        } else if mSoundType == .telephone_ringing {
            etc_info = String(format: "> Instability in this sound = %@\n\n" +
                "> Instability number = %d",
                              data.instability >= 12 ? "Yes" : "No", data.instability
            )
        }
        
        var universal_engine : String = "\n"
        
        if (mSoundType == .telephone_ringing) {
            var valid_freq_cnt = 0
            let totalFrames = data.beep_frames
            
            for i in 0..<data.freq_data.count {
                let freq_val = data.freq_data[i][0]
                let repeat_val = data.freq_data[i][1]
                
                if (repeat_val >= data.total_frames * 2 / 10) {
                    //universal_engine += "\n"
                    universal_engine += String(format: "> %d%@ Frequency value = %d Hz\n", valid_freq_cnt + 1, strLabels[(valid_freq_cnt+1)%10], freq_val)
                    universal_engine += String(format: "> Number of frames %d%@ Freq. = (%d-%d)=%d frames\n", valid_freq_cnt + 1, strLabels[(valid_freq_cnt+1)%10], repeat_val, repeat_val / 10, repeat_val - repeat_val / 10)
                    universal_engine += String(format: "> Bandwidth %d%@ Frequency = %d Hz\n", valid_freq_cnt + 1, strLabels[(valid_freq_cnt+1)%10], mBandWidth)
                    valid_freq_cnt = valid_freq_cnt + 1
                }
            }
            
            universal_engine += String(format: "> Silent frames between beeps = %d Frames\n\n", data.silent_frames)
            
        } else if (mSoundType == .microwave_beeps || mSoundType == .oven_timer_beeps || mSoundType == .smoke_alarms) {
            
            universal_engine += String(format: ">Frequency value = %d Hz\n" +
                "> Bandwidth = %d Hz\n" +
                "> eep frame = %d Frames\n" +
                "> Silent frames = %d Frames\n\n", data.strong_freq, mBandWidth, data.beep_frames, data.silent_frames)
        }
        
        
        cell.lbEtc.stringValue = etc_info + "\n" + universal_engine
        
        for item in cell.vwGraph1.subviews {
            item.removeFromSuperview()
        }
        
        let graph = Graph(frame: cell.vwGraph1.bounds)
        graph.band_width = mBandWidth
        graph.mType = .frequency
        graph.mFreqs = data.max_freq_val_data
        graph.freq_data_to_show = data.freq_data
        graph.checkedList = data.freq_order_visible
        cell.graph1 = graph
        cell.vwGraph1.addSubview(graph)
        
        for item in cell.vwGraph2.subviews {
            item.removeFromSuperview()
        }
        let graph2 = Graph(frame: cell.vwGraph2.bounds)
        graph2.mType = .histogram
        graph2.mHistogram = data.histogram
        cell.vwGraph2.addSubview(graph2)
        
        cell.btnClose.target = self
        cell.btnClose.tag = row
        cell.btnClose.action = #selector(closeAction)
        
        cell.btnPlay.target = self
        cell.btnPlay.tag = row
        cell.btnPlay.action = #selector(playAction)
        if file_url != nil && file_url! == data.file_url.absoluteString {
            cell.btnPlay.title = "Stop"
        } else {
            cell.btnPlay.title = "Play"
        }

        cell.refresh()
        
        return cell
    }
    
    func cellForAlgorithm(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AlgorithmCell"), owner: self) as! AlgorithmCell
        
        var min_ding_freq = 0, max_ding_freq = 0
        var min_ding_frames = 0, max_ding_frames = 0
        var min_dong_freq = 0, max_dong_freq = 0
        var min_dong_frames = 0, max_dong_frames = 0
        
        for item in mList {
            min_ding_freq = min_ding_freq == 0 ? item.ding_freq : min(min_ding_freq, item.ding_freq)
            max_ding_freq = max_ding_freq == 0 ? item.ding_freq : max(max_ding_freq, item.ding_freq)
            min_ding_frames = min_ding_frames == 0 ? item.ding_frames : min(min_ding_frames, item.ding_frames)
            max_ding_frames = max_ding_frames == 0 ? item.ding_frames : max(max_ding_frames, item.ding_frames)
            
            min_dong_freq = min_dong_freq == 0 ? item.dong_freq : min(min_dong_freq, item.dong_freq)
            max_dong_freq = max_dong_freq == 0 ? item.dong_freq : max(max_dong_freq, item.dong_freq)
            min_dong_frames = min_dong_frames == 0 ? item.dong_frames : min(min_dong_frames, item.dong_frames)
            max_dong_frames = max_dong_frames == 0 ? item.dong_frames : max(max_dong_frames, item.dong_frames)
        }
        
        var min_freq = 0
        var max_freq = 0
        var total_amplitude_beeps = 0
        var min_beeps_frame = 0
        var max_beeps_frame = 0
        var total_continue_beep = Float(0)
        var total_continue_cnt = 0
        var min_silent_frame = 0
        var max_silent_frame = 0
        var min_amplitude_silent = Float(0)
        var max_amplitude_silent = Float(0)
        
        var idx = 0
        for item in mList {
            if mSoundType == .microwave_beeps || mSoundType == .oven_timer_beeps || mSoundType == .smoke_alarms {
                min_freq = min_freq == 0 ? item.long_freq : min(min_freq, item.long_freq)
                max_freq = max_freq == 0 ? item.long_freq : max(max_freq, item.long_freq)
            } else {
                min_freq = min_freq == 0 ? item.min_freq : min(min_freq, item.min_freq)
                max_freq = max_freq == 0 ? item.max_freq : max(max_freq, item.max_freq)
            }
            
            total_amplitude_beeps += item.max_amp_of_freq
            if item.continue_ok {
                total_continue_beep += item.continue_beep_times
                total_continue_cnt += 1
            } else {
                min_beeps_frame = min_beeps_frame == 0 ? item.beep_frames : min(min_beeps_frame, item.beep_frames)
                max_beeps_frame = max(max_beeps_frame, item.beep_frames)
                min_silent_frame = min_silent_frame == 0 ? item.silent_frames : min(min_silent_frame, item.silent_frames)
                max_silent_frame = max(max_silent_frame, item.silent_frames)
                min_amplitude_silent = min_amplitude_silent == 0 ? item.min_amp_for_silent : min(min_amplitude_silent, item.min_amp_for_silent)
                max_amplitude_silent = max(max_amplitude_silent, item.max_amp_for_silent)
            }
            
            idx = idx + 1
        }
        
        
        let amplitude_beeps = Int(total_amplitude_beeps / mList.count / 2)
        let continue_beep = total_continue_cnt != 0 ? total_continue_beep / Float(total_continue_cnt) : 0
        
        switch mSoundType {
        case .doorbell:
            cell.lbInfo1.stringValue = String(format:
                "> Min Ding Frequency = %d Hz\n" +
                "> Max Ding Frequency = %d Hz\n\n" +
                "> Min Dong Frequency = %d Hz\n" +
                "> Max Dong Frequency = %d Hz\n\n" +
                "> Min. Ding Frames = %d frames\n" +
                "> Max. Ding Frames = %d frames\n\n" +
                "> Min. Dong Frames = %d frames\n" +
                "> Max. Dong Frames = %d frames",
                                              min_ding_freq, max_ding_freq, min_dong_freq, max_dong_freq,
                                              min_ding_frames, max_ding_frames, min_dong_frames, max_dong_frames
            )
            
            cell.lbInfo2.stringValue = ""
            
        case .microwave_beeps, .oven_timer_beeps, .smoke_alarms:
            cell.lbInfo1.stringValue = String(format:
                "> Amplitude for beeps = %d\n\n" +
                "> Min beep frames = %d frames\n" +
                "> Max beep frames = %d frames\n\n" +
                "> Continues beep = %.1f sec", amplitude_beeps, min_beeps_frame, max_beeps_frame, continue_beep)
            
            cell.lbInfo2.stringValue = String(format:
                "> Min silent frames (between beeps) = %d frames\n" +
                "> Max silent frames (between beeps) = %d frames\n\n" +
                "> Min Amplitude for silent frame = %.2f\n" +
                "> Max Amplitude for silent frame = %.2f\n\n" +
                "> Repeat beeps = 3 times (by default)\n\n" +
                "> Frequency Bandwidth = (+/-)100 Hz (by default value)\n" +
                "> Frame Bandwidth = (+/-)4 frames (by default value)",
                                              min_silent_frame, max_silent_frame, min_amplitude_silent, max_amplitude_silent
            )
            
        case .telephone_ringing:
            cell.lbInfo1.stringValue = String(format:
                "> Min beep frames = %d frames\n" +
                "> Max beep frames = %d frames\n\n" +
                "> Continues beep = %.1f sec\n\n" +
                "> Min silent frames (between beeps) = %d frames\n" +
                "> Max silent frames (between beeps) = %d frames\n\n", min_beeps_frame, max_beeps_frame, continue_beep, min_silent_frame, max_silent_frame)
            
            cell.lbInfo2.stringValue = String(format:
                "> Min Amplitude for silent frame = %d\n" +
                "> Max Amplitude for silent frame = %d\n\n" +
                "> Repeat beeps = 3 times (by default)\n\n" +
                "> Frequency Bandwidth = (+/-)100 Hz (by default value)\n" +
                "> Frame Bandwidth = (+/-)4 frames (by default value)",
                   min_amplitude_silent, max_amplitude_silent
            )
        }
        
        return cell
    }
    
}
