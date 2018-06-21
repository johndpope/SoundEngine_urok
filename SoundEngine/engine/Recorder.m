//
//  Recorder.m
//  SoundEngine
//
//  Created by Snow on 24/5/2018.
//  Copyright © 2018 Snow. All rights reserved.
//

#import "Recorder.h"
#import <AudioToolbox/AudioToolbox.h>
#import "bridgeClass.h"

#define kNumberRecordBuffers 3

#pragma mark - User Data Struct

struct MyRecorder;

typedef struct MyPlayer {
    AudioQueueRef playerQueue;
    SInt64 packetPosition;
    UInt32 numPacketsToRead;
    AudioStreamPacketDescription *packetDescs;
    Boolean isDone;
    struct MyRecorder *recorder;
} MyPlayer;

typedef struct MyRecorder {
    AudioQueueRef recordQueue;
    SInt64      recordPacket;
    Boolean     running;
    MyPlayer    *player;
} MyRecorder;


@implementation Recorder : NSObject

static void CheckError(OSStatus error, const char *operation) {
    if (error == noErr) return;
    
    char errorString[20];
    // See if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else {
        // No, format it as an integer
        NSLog(@"Was integer");
        sprintf(errorString, "%d",(int)error);
    }
    
    fprintf(stderr, "Error: %s (%s)\n",operation,errorString);
    exit(1);
}

OSStatus MyGetDefaultInputDeviceSampleRate(Float64 *outSampleRate) {
    OSStatus error;
    AudioDeviceID deviceID = 0;
    
    AudioObjectPropertyAddress propertyAddress;
    UInt32 propertySize;
    propertyAddress.mSelector = kAudioHardwarePropertyDefaultInputDevice;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = 0;
    propertySize = sizeof(AudioDeviceID);
    error = AudioHardwareServiceGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize, &deviceID);
    
    if (error) return error;
    
    propertyAddress.mSelector = kAudioDevicePropertyNominalSampleRate;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = 0;
    propertySize = sizeof(Float64);
    
    error = AudioHardwareServiceGetPropertyData(deviceID, &propertyAddress, 0, NULL, &propertySize, outSampleRate);
    return error;
}

// Recorder
//static void MyCopyEncoderCookieToFile(AudioQueueRef queue, AudioFileID theFile) {
//    OSStatus error;
//    UInt32 propertySize;
//    error = AudioQueueGetPropertySize(queue, kAudioConverterCompressionMagicCookie, &propertySize);
//
//    if (error == noErr && propertySize > 0) {
//        Byte *magicCookie = (Byte *)malloc(propertySize);
//        CheckError(AudioQueueGetProperty(queue, kAudioQueueProperty_MagicCookie, magicCookie, &propertySize), "Couldn't get audio queue's magic cookie");
//        CheckError(AudioFileSetProperty(theFile, kAudioFilePropertyMagicCookieData, propertySize, magicCookie), "Couldn't set audio file's magic cookie");
//        free(magicCookie);
//    }
//}

static int MyComputeRecordBufferSize(const AudioStreamBasicDescription *format, AudioQueueRef queue, float seconds) {
    int packets, frames, bytes;
    
    frames = (int)ceil(seconds * format->mSampleRate);
    
    if (format->mBytesPerFrame > 0) { // Not variable
        bytes = frames * format->mBytesPerFrame;
    } else { // variable bytes per frame
        UInt32 maxPacketSize;
        if (format->mBytesPerPacket > 0) {
            // Constant packet size
            maxPacketSize = format->mBytesPerPacket;
        } else {
            // Get the largest single packet size possible
            UInt32 propertySize = sizeof(maxPacketSize);
            CheckError(AudioQueueGetProperty(queue, kAudioConverterPropertyMaximumOutputPacketSize, &maxPacketSize, &propertySize), "Couldn't get queue's maximum output packet size");
        }
        
        if (format->mFramesPerPacket > 0) {
            packets = frames / format->mFramesPerPacket;
        } else {
            // Worst case scenario: 1 frame in a packet
            packets = frames;
        }
        
        // Sanity check
        if (packets == 0) {
            packets = 1;
        }
        
        bytes = packets * maxPacketSize;
    }
    
    return bytes;
}

void CalculateBytesForPlaythrough(AudioQueueRef queue,
                                  AudioStreamBasicDescription inDesc,
                                  Float64 inSeconds,
                                  UInt32 *outBufferSize,
                                  UInt32 *outNumPackets)
{
    UInt32 maxPacketSize;
    UInt32 propSize = sizeof(maxPacketSize);
    CheckError(AudioQueueGetProperty(queue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &propSize), "Couldn't get file's max packet size");
    
    static const int maxBufferSize = 0x10000;
    static const int minBufferSize = 0x4000;
    
    if (inDesc.mFramesPerPacket) {
        Float64 numPacketsForTime = inDesc.mSampleRate / inDesc.mFramesPerPacket * inSeconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    } else {
        *outBufferSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize;
    }
    
    if (*outBufferSize > maxBufferSize && *outBufferSize > maxPacketSize) {
        *outBufferSize = maxBufferSize;
    } else {
        if (*outBufferSize < minBufferSize) {
            *outBufferSize = minBufferSize;
        }
    }
    *outNumPackets = *outBufferSize / maxPacketSize;
}

#pragma mark - Record callback function

static void MyAQInputCallback(void *inUserData,
                              AudioQueueRef inQueue,
                              AudioQueueBufferRef inBuffer,
                              const AudioTimeStamp *inStartTime,
                              UInt32 inNumPackets,
                              const AudioStreamPacketDescription *inPacketDesc)
{
    //NSLog(@"Input callback");
    //NSLog(@"Input thread = %@",[NSThread currentThread]);
    MyRecorder *recorder = (MyRecorder *)inUserData;
    MyPlayer *player = recorder->player;
    
    
    
    if (inNumPackets > 0) {
        // Enqueue on the output Queue!
//        AudioQueueBufferRef outputBuffer;
//        CheckError(AudioQueueAllocateBuffer(player->playerQueue, inBuffer->mAudioDataBytesCapacity, &outputBuffer), "Input callback failed to allocate new output buffer");
//
//
//        memcpy(outputBuffer->mAudioData, inBuffer->mAudioData, inBuffer->mAudioDataByteSize);
//        outputBuffer->mAudioDataByteSize = inBuffer->mAudioDataByteSize;
//
//        //[NSData dataWithBytes:inBuffer->mAudioData length:inBuffer->mAudioDataByteSize];
//
//        // Assuming LPCM so no packet descriptions
//        CheckError(AudioQueueEnqueueBuffer(player->playerQueue, outputBuffer, 0, NULL), "Enqueing the buffer in input callback failed");
//        recorder->recordPacket += inNumPackets;
        
        float *buf = bridgeClass.get_g_fRecBuf;
        int total_size = bridgeClass.get_recBuf_total_size;
        int pos = bridgeClass.get_recBuf_pos;
        
        //bridgeClass.mu
        
        if (pos + inNumPackets > total_size) {
            int start = pos + inNumPackets - total_size;
            memcpy(buf, &buf[start], (pos - start) * sizeof(float));
            
            char* audioBuf = (char*)inBuffer->mAudioData;
            for (int i = 0; i < inNumPackets; i++) {
                short value = (short)(audioBuf[i*2] << 8 | audioBuf[i*2 + 1]);
                buf[pos - start + i] = value / 32768.0f;
            }
            [bridgeClass set_recBuf_pos:total_size];
        } else {
            char* audioBuf = (char*)inBuffer->mAudioData;
            for (int i = 0; i < inNumPackets; i++) {
                short value = (short)(audioBuf[i*2] << 8 | audioBuf[i*2 + 1]);
                buf[pos + i] = value / 32768.0f;
            }
            pos += inNumPackets;
            [bridgeClass set_recBuf_pos:pos];
        }
    }
    
    if (recorder->running) {
        CheckError(AudioQueueEnqueueBuffer(inQueue, inBuffer, 0, NULL), "AudioQueueEnqueueBuffer failed");
    }
}

static void MyAQOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer) {
    //NSLog(@"Output thread = %@",[NSThread currentThread]);
    //NSLog(@"Output callback");
    MyPlayer *aqp = (MyPlayer *)inUserData;
    MyRecorder *recorder = aqp->recorder;
    if (aqp->isDone) return;
}

+(void)stop {
    printf("Playing through, press <return> to stop:\n");
    getchar();
    
    printf("* done *\n");
//    recorder.running = FALSE;
//    player.isDone = true;
//    CheckError(AudioQueueStop(playbackQueue, false), "Failed to stop playback queue");
//    
//    CheckError(AudioQueueStop(queue, TRUE), "AudioQueueStop failed");
//    
//    AudioQueueDispose(playbackQueue, FALSE);
//    AudioQueueDispose(queue, TRUE);
}

+(void)record: (int)channelsPerFrame : (int)bitsPerChannel {
    @autoreleasepool {
    
    MyRecorder recorder = {0};
    MyPlayer player = {0};
    
    recorder.player = &player;
    player.recorder = &recorder;
    
    AudioStreamBasicDescription recordFormat;
    memset(&recordFormat, 0, sizeof(recordFormat));
    
    recordFormat.mFormatID = kAudioFormatLinearPCM;
    recordFormat.mChannelsPerFrame = channelsPerFrame; // 2 - stereo
    
    // Begin my changes to make LPCM work
    recordFormat.mBitsPerChannel = bitsPerChannel; // 16
    // Haven't checked if each of these flags is necessary, this is just what Chapter 2 used for LPCM.
    recordFormat.mFormatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    
    // end my changes
    
    MyGetDefaultInputDeviceSampleRate(&recordFormat.mSampleRate);
    
    
    UInt32 propSize = sizeof(recordFormat);
    CheckError(AudioFormatGetProperty(kAudioFormatProperty_FormatInfo,
                                      0,
                                      NULL,
                                      &propSize,
                                      &recordFormat), "AudioFormatGetProperty failed");
    
    AudioQueueRef queue = {0};
    
    CheckError(AudioQueueNewInput(&recordFormat, MyAQInputCallback, &recorder, NULL, NULL, 0, &queue), "AudioQueueNewInput failed");
    
    recorder.recordQueue = queue;
    
    // Fills in ABSD a little more
    UInt32 size = sizeof(recordFormat);
    CheckError(AudioQueueGetProperty(queue,
                                     kAudioConverterCurrentOutputStreamDescription,
                                     &recordFormat,
                                     &size), "Couldn't get queue's format");
    
    //MyCopyEncoderCookieToFile(queue, recorder.recordFile);
    
    int bufferByteSize = MyComputeRecordBufferSize(&recordFormat,queue,0.5);
    NSLog(@"%d",__LINE__);
    // Create and Enqueue buffers
    int bufferIndex;
    for (bufferIndex = 0;
         bufferIndex < kNumberRecordBuffers;
         ++bufferIndex) {
        AudioQueueBufferRef buffer;
        CheckError(AudioQueueAllocateBuffer(queue,
                                            bufferByteSize,
                                            &buffer), "AudioQueueBufferRef failed");
        CheckError(AudioQueueEnqueueBuffer(queue, buffer, 0, NULL), "AudioQueueEnqueueBuffer failed");
    }
    
    // PLAYBACK SETUP
    
    AudioQueueRef playbackQueue;
    CheckError(AudioQueueNewOutput(&recordFormat,
                                   MyAQOutputCallback,
                                   &player, NULL, NULL, 0,
                                   &playbackQueue), "AudioOutputNewQueue failed");
    player.playerQueue = playbackQueue;


    UInt32 playBufferByteSize;
    CalculateBytesForPlaythrough(queue, recordFormat, 0.1, &playBufferByteSize, &player.numPacketsToRead);

    bool isFormatVBR = (recordFormat.mBytesPerPacket == 0
                        || recordFormat.mFramesPerPacket == 0);
    if (isFormatVBR) {
        NSLog(@"Not supporting VBR");
        player.packetDescs = (AudioStreamPacketDescription*) malloc(sizeof(AudioStreamPacketDescription) * player.numPacketsToRead);
    } else {
        player.packetDescs = NULL;
    }
    
    // END PLAYBACK
    
    recorder.running = TRUE;
    player.isDone = false;
    
    CheckError(AudioQueueStart(playbackQueue, NULL), "AudioQueueStart failed");
    CheckError(AudioQueueStart(queue, NULL), "AudioQueueStart failed");
    
//    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10, TRUE);
    }
}

@end
