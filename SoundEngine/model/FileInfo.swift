//
//  FileInfo.swift
//  SoundEngine
//
//  Created by Snow on 17/5/2018.
//  Copyright © 2018 Snow. All rights reserved.
//

import Foundation

class FileInfo: NSObject {
    
    var recorded = false
    var file_url: URL!
    var file_name: String!
    var histogram = [Float]() // histogram
    var strong_freq = 0
    var long_freq = 0
    var max_amplitude = 0
    var max_freq_val_data = [[[Int]]]() // freq graph
    var freq_data = [[Int]]()
    
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
    
}
