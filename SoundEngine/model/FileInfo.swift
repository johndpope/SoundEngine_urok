//
//  FileInfo.swift
//  SoundEngine
//
//  Created by Snow on 17/5/2018.
//  Copyright © 2018 Snow. All rights reserved.
//

import Foundation

class FileInfo: NSObject {
    
    let MAX_FREQ_CNT = 10
    
    var sample_rate = 0
    var recorded = false
    var file_url: URL!
    var file_name: String!
    var histogram = [Float]() // histogram
    var strong_freq = 0
    var long_freq = 0
    var max_amp_of_freq = 0
    var max_freq_val_data = [[[Int]]]() // freq graph
    
    var max_len = 0
    
    // Frequency Values & Repeatitions
    var freq_data = [[Int]]()
    var total_frames = 0 // sum of repeatitions of each frequency
    
    var freq_order_visible = [Bool]()
    
    
    var ding_freq = 0, ding_frames = 0, ding_dec = false // false: nono/inc - No, true: dec - Yes
    var dong_freq = 0, dong_frames = 0, dong_dec = false // false: inc - No, true: dec - Yes
    
    var max_freq = 0
    var min_freq = 0
    var min_amplitude = 0
    var continue_ok = false
    var beep_frames = 0
    var silent_frames = 0
    var continue_beep_times = Float(0)
    var instability = 0
    
    // smoke, oven, fire
    var min_amp_for_silent = Float(0)
    var max_amp_for_silent = Float(0)
    var max_value = Float(1)
    
    override init() { }
    
    
    func getFrequencies(freqOrders : [Bool], bufferSize : Int, bandWidth : Int, repeatCnt : Int) -> [[Int]] {
        var arr : [[Int]] = []
    
        let nFrameCnt = max_len / bufferSize
    
        for i in 0..<nFrameCnt {

            var fMaxFreqs : [Float] = [];
            var fMaxVals : [Float] = [];
            
            for j in 0..<MAX_FREQ_CNT {
                fMaxFreqs.append(Float(max_freq_val_data[j][i][0]))
                fMaxVals.append(Float(max_freq_val_data[j][i][1]))
            }
    
            for j in 0..<(MAX_FREQ_CNT - 1) {
                let freq1 = fMaxFreqs[j]
    
                for k in (j + 1)..<MAX_FREQ_CNT {
                    let freq2 = fMaxFreqs[k]
    
                    if (abs(freq1 - freq2) <= Float(bandWidth)) {
                        fMaxFreqs[j] = (fMaxFreqs[j] + fMaxFreqs[k]) / 2;
                        fMaxFreqs[k] = 0;
                    }
                }
            }
    
            for j in 0..<freqOrders.count {
                if !freqOrders[j] {
                    continue
                }
        
                let freq = Int(fMaxFreqs[j])
                if freq == 0 {
                    continue
                }
        
                var bFound = false
                var idx = -1
                
                for k in 0..<arr.count {
                    var item_arr = arr[k]
                    var val = item_arr[0]
                    if (freq < val - bandWidth) {
                        break
                    } else if (freq > val + bandWidth) {
                        idx = k
                    } else {
                        var cnt = item_arr[1]
                        let freq1 = (item_arr[0] * cnt + freq) / (cnt + 1);
                        cnt = (cnt + 1)
        
                        item_arr.removeAll()
                        item_arr.append(freq1)
                        item_arr.append(cnt)
                        arr[k] = item_arr
                        
                        bFound = true
                        break
                    }
                }
        
                if (!bFound) {
                    var ele_arr : [Int] = []
                    ele_arr.append(freq)
                    ele_arr.append(1)
                    
                    arr.insert(ele_arr, at: idx + 1)
                }
            }
        }
    
    
        let count = arr.count
        for i in 0..<count {
            let idx = count - 1 - i
            let cnt = Int(arr[idx][1])
            if (cnt < repeatCnt) {
                arr.remove(at: idx)
            }
        }
    
        return arr
    }
    
}
