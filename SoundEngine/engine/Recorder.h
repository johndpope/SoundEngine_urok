//
//  Recorder.h
//  SoundEngine
//
//  Created by Snow on 24/5/2018.
//  Copyright © 2018 Snow. All rights reserved.
//

#ifndef Recorder_h
#define Recorder_h

#import <Foundation/Foundation.h>

@interface Recorder : NSObject

+(void)record: (int)channelsPerFrame : (int)bitsPerChannel;
+(void)stop;

@end

#endif /* Recorder_h */
