//
//  bridgeClass.m
//  BraciPro
//
//  Created by Rajat on 01/06/16.
//  Copyright © 2016 Solulab. All rights reserved.
//

#include <stdio.h>
#include <stdarg.h>
#include "bridgeClass.h"
//#include "IosAudioController.h"
#include "DetectingData.h"
#include "globals.h"
#include "RWBuffer.h"
#include "DetectMgr.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioServices.h>
#import <AVFoundation/AVFoundation.h>
//#import "AudioSessionManager.h"
#import "Recorder.h"
//#import <PebbleKit/PebbleKit.h>
//#import "BraciPro-Swift.h"
//#import "Sound_Alert-Swift.h"
#import <mutex>

std::mutex mtx;

@implementation bridgeClass

CDetectingData* m_curDetectingData;
int ReturnAlarmType;
bool APP_IS_BACKGROUND = IS_BACKGROUND;

+(void)globalsmethod{
//    AudioParameterInfo *tt;
//    tt->
}
+(bool)get_g_bDetecting{
    return g_bDetecting;
}
+(bool)get_g_isEngineTerminated{
    return g_isEngineTerminated;
}
+(bool)globalsMethodVarible_get_g_bDetected{
    return g_bDetected;
}

+(int)globalsMethodVarible_get_UNIVERSAL_THRESHOLDS{
    return UNIVERSAL_THRESHOLDS;
}
+(int)globalsMethodVarible_get_UNIVERSAL_MIN_FREQ{
    return UNIVERSAL_MIN_FREQ;
}
+(int)globalsMethodVarible_get_UNIVERSAL_MIN_PERIOD_FRAMES{
    return UNIVERSAL_MIN_PERIOD_FRAMES;
}
+(int)globalsMethodVarible_get_UNIVERSAL_MAX_STOP_FRAMES{
    return UNIVERSAL_MAX_STOP_FRAMES;
}
+(int)globalsMethodVarible_get_UNIVERSAL_MAX_PERIOD_FRAMES{
    return UNIVERSAL_MAX_PERIOD_FRAMES;
}
+(int)globalsMethodVarible_get_UNIVERSAL_UNIVERSAL_MIN_STOP_FRAMES{
    return UNIVERSAL_MIN_STOP_FRAMES;
}
+(int)globalsMethodVarible_get_UNIVERSAL_MIN_REPEATS{
    return UNIVERSAL_MIN_REPEATS;
}
+(int)globalsMethodVarible_get_UNIVERSAL_DETECT_PERIOD_FRAMES{
    return UNIVERSAL_DETECT_PERIOD_FRAMES;
}

+(void)set_g_isEngineTerminated : (bool) value{
    g_isEngineTerminated = value;
}
+(void)set_g_bDetecting : (bool) value{
    g_bDetecting = value;
}

+(CDetectMgr *)globalsMethod_get_g_pDetectMgr{
    CDetectMgr *g_pDetectMgr;
    return g_pDetectMgr;
}
+(float *)get_g_fBufData{
    return g_fBufData;
}

+(bool) get_ReadData : (float *) buffData : (int) frameLen
{
    return g_RecOutBuffer.ReadData(buffData, frameLen);
}
+(bool)get_g_pDetectMgr_IsRecordingOrPreparing{
    bool value = g_pDetectMgr->IsRecordingOrPreparing();
    return  value;
}

+(bool)get_g_pDetectMgr_isnill{
    if(g_pDetectMgr != nil)
        return YES;
    else
        return NO;
}

+(NSArray *)get_max_freqs_vals :(int)idx : (int)cnt {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < cnt ; i++) {
        [arr addObject:@[@((int)g_pDetectMgr->m_fMaxFreqs[idx][i]), @((int)g_pDetectMgr->m_fMaxVals[idx][i])]];
    }
    
    return arr;
}

+(NSArray *)get_impulse_vals {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < BAND_CNT ; i++) {
        [arr addObject:@((int)g_pDetectMgr->m_pRealValsToDraw[i])];
    }
    
    return arr;
}

+(NSArray *)get_other_results {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    // 0 : Min Amplitude for silent frame (for Smoke Alarm)
    // 1 : Max Amplitude for silent frame (for Smoke Alarm)
    [arr addObject:[NSNumber numberWithFloat:g_pDetectMgr->m_fMinAmpForSilent]];
    [arr addObject:[NSNumber numberWithFloat:g_pDetectMgr->m_fMaxAmpForSilent]];
    [arr addObject:[NSNumber numberWithFloat:g_pDetectMgr->m_fMaxValue]];
    
    return arr;
}


int recSampleRate = 0;
int recMicDetectionTime = 0;
int recMicThreshold = 0;
int recMode = 0;
int recBufferSize = 0;
int recFreqFrame = 0;
int recThreshold = 0;
int recBandWidth = 0;
int recRepeatCnt = 0;


+(float *)get_g_fRecBuf {
    return g_fRecBuf;
}

+(int)get_recBuf_total_size {
    return g_nRecTotalSize;
}

+(int)get_recBuf_pos {
    return g_nRecPos;
}

+(void)set_recBuf_pos: (int)pos {
    g_nRecPos = pos;
}

+(void)RecStart : (int) p_micDetectionTime : (int) p_micThreshold : (int) p_recMode : (int) p_recFreqFrame : (int) p_recThreshold : (int) p_recBandWidth : (int) p_recRepeatCnt {
    if (g_fRecBuf != nullptr) {
        delete g_fRecBuf;
        g_fRecBuf = nullptr;
    }
    
    recMicDetectionTime = p_micDetectionTime;
    recMicThreshold = p_micThreshold;
    recMode = p_recMode;
    recFreqFrame = p_recFreqFrame;
    recThreshold = p_recThreshold;
    recBandWidth = p_recBandWidth;
    recRepeatCnt = p_recRepeatCnt;
    
    g_nRecTotalSize = recSampleRate * recMicDetectionTime;
    g_nRecPos = 0;
    g_fRecBuf = new float[g_nRecTotalSize];
    memset(g_fRecBuf, 0x00, recSampleRate * recMicDetectionTime * sizeof(float));
    
    [Recorder record:1 :16];
}

+(void)RecStop {
    [Recorder stop];
    if (g_fRecBuf != nullptr) {
        delete g_fRecBuf;
        g_fRecBuf = nullptr;
    }
}
+(NSArray *)get_g_pDetectMgr_ProcessRec {
    return [bridgeClass get_g_pDetectMgr_ProcessFile:g_fRecBuf :g_nRecTotalSize :recBufferSize :recFreqFrame :recThreshold :recBandWidth :recRepeatCnt];
}

+(NSArray *)get_g_pDetectMgr_ProcessFile : (float *) buffData : (int) totalLen : (int) frameLen : (int) freqFrame : (int) threshold : (int) bandWidth : (int) repeatCnt {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    int nFrameCnt = totalLen / frameLen;
    g_pDetectMgr->initFreqVal(nFrameCnt);
    
    g_pDetectMgr->m_fMinAmpForSilent = 0;
    g_pDetectMgr->m_fMaxAmpForSilent = 0;
    
    float maxVal = 0;
    for (int i = 0; i < totalLen; i++) {
        if (buffData[i] > maxVal) {
            maxVal = buffData[i];
        }
    }
    
    g_pDetectMgr->m_fMaxValue = maxVal * (50000);
    
    
    for (int i = 0; i < nFrameCnt; i++) {
        float fMaxFreqs[MAX_FREQ_CNT] = {0};
        float fMaxVals[MAX_FREQ_CNT] = {0};
        
        //NSLog(@"Frame Number %d total = %d", i, nFrameCnt);
        g_pDetectMgr->Process(&buffData[i * frameLen], frameLen, freqFrame, threshold, fMaxFreqs, fMaxVals);
        
        for (int j = 0; j < freqFrame; j++) {
            g_pDetectMgr->m_fMaxFreqs[j][i] = fMaxFreqs[j];
            g_pDetectMgr->m_fMaxVals[j][i] = fMaxVals[j];
        }
        
        for (int j = 0; j < MAX_FREQ_CNT - 1; j++) {
            float freq1 = fMaxFreqs[j];
            
            for (int k = j + 1; k < MAX_FREQ_CNT; k++) {
                float freq2 = fMaxFreqs[k];
                
                if (freq1 >= freq2 - bandWidth && freq1 <= freq2 + bandWidth) {
                    fMaxFreqs[k] = (fMaxFreqs[j] + fMaxFreqs[k]) / 2;
                    fMaxFreqs[j] = 0;
                }
            }
        }
        
        for (int j = 0; j < MAX_FREQ_CNT; j++) {
            float freq = fMaxFreqs[j];
            if (freq == 0) continue;
            
            bool bFound = false;
            int idx = -1;
            for (int k = 0; k < arr.count; k++) {
                NSMutableArray* item_arr = arr[k];
                float val = [[item_arr objectAtIndex:0] floatValue];
                if (freq < val - bandWidth) {
                    break;
                } else if (freq > val + bandWidth) {
                    idx = k;
                } else {
                    int cnt = [[item_arr objectAtIndex:1] intValue];
                    int freq1 = ([[item_arr objectAtIndex:0] floatValue] * cnt + freq) / (cnt + 1);
                    cnt = (cnt + 1);
                    
                    [item_arr removeAllObjects];
                    [item_arr addObject:@(freq1)];
                    [item_arr addObject:@(cnt)];
                    
                    bFound = true;
                    break;
                }
            }
            
            if (!bFound) {
                [arr insertObject:[[NSMutableArray alloc] initWithArray:@[@((int)freq), @(1)]] atIndex:idx + 1];
            }
        }
    }
    
    for (int i = (int)arr.count - 1; i >= 0; i--) {
        int cnt = [[[arr objectAtIndex:i] objectAtIndex:1] intValue];
        if (cnt <= repeatCnt) {
            [arr removeObjectAtIndex:i];
        }
    }
    
    return arr;
}

+(int)globalsMethodVarible_get_g_pDetectMgr_alarmType {
    return ReturnAlarmType;
}



+(void)set_SetDetectSmokeAlarmOnly : (bool) value {
    return g_pDetectMgr->SetDetectSmokeAlarmOnly(value);
}
+(const char *)globalsMethodVariable_get_PEBBLE_UUID{
    return PEBBLE_UUID;
}
+(int) get_SAMPLE_FREQ{
    return SAMPLE_FREQ;
}
+(void) set_g_pDetectMgr_SAMPLE_FREQ{
    g_pDetectMgr = new CDetectMgr(SAMPLE_FREQ, FRAME_LEN);
}

+(void) set_g_pDetectMgr_SAMPLE_FREQ : (int) rate : (int) frameLen {
    recSampleRate = rate;
    recBufferSize = frameLen;
    g_pDetectMgr = new CDetectMgr(rate, frameLen);
}

+(void) initEngine{
    g_RecOutBuffer.Init(1 * SAMPLE_FREQ * 1 * sizeof(float));
    g_fBufData = new float[FRAME_LEN];

//    IosAudioController* pController = IosAudioController::getInstance();
//    g_audioInfo = new AudioParameterInfo();
//    g_audioInfo->channel = 1;
//    g_audioInfo->micOn = true;
//    g_audioInfo->sampleRate = SAMPLE_FREQ;
//    g_audioInfo->numPacket = 1;
//    g_audioInfo->samplesPerFrame = 512;
//    g_audioInfo->listner = nullptr;
//    pController->open(g_audioInfo, audioCallback);
}

+(int) get_RST_COUNT{
    return RST_COUNT;
}
+(void) set_MATCHING_RATE_THRESHOLD_DELTAS : (int) value : (NSString *) strKey{
    MATCHING_RATE_THRESHOLD_DELTAS[value] = [[NSUserDefaults standardUserDefaults] floatForKey:strKey];
}

+(void) set_UNIVERSAL_THRESHOLD_DELTA : (NSString *) strKey{
    UNIVERSAL_THRESHOLD_DELTA = (int)[[NSUserDefaults standardUserDefaults] integerForKey:strKey];
}

+(int) get_UNIVERSAL_THRESHOLD_DELTA{
    return UNIVERSAL_THRESHOLD_DELTA;
}


//+(void) globalsMethodVarible_set_MATCHING_RATE_THRESHOLD_DELTAS : (NSString *) strKey{
//    MATCHING_RATE_THRESHOLD_DELTAS = (float)[[NSUserDefaults standardUserDefaults] integerForKey:strKey];
//}
//
//+(float) globalsMethodVarible_get_MATCHING_RATE_THRESHOLD_DELTAS{
//    return MATCHING_RATE_THRESHOLD_DELTAS;
//}

+(void) initData : (NSString *) strDetectPath : (int32_t) soundType{
    CDetectingData* detectData = new CDetectingData();
    if (detectData->LoadDetectData([strDetectPath UTF8String])){
        g_DetectData[ soundType].push_back(detectData);
    }
    else{
        g_DetectData[soundType].clear();
    }
}

+(int)get_g_DetectData : (int) nTotalCnt : (int) i {
    nTotalCnt += g_DetectData[i].size();
    return  nTotalCnt;
}

+(void)set_g_bDetected : (bool) value{
    g_bDetected = value;
}
+(bool)set_pController{
//    IosAudioController* pController = IosAudioController::getInstance();
//    if (pController == nil){
//        return false;
//    }else{
        return true;
//    }
}
+(bool)set_pController_isOpen{
//    IosAudioController* pController = IosAudioController::getInstance();
//    bool value =  pController->isOpened();
//    if (value == FALSE){
//        return false;
//    }else{
        return true;
//    }
}
+(void)set_pController_pause{
//    IosAudioController* pController = IosAudioController::getInstance();
//    pController->pause();
}
+(void)set_pController_play{
//    IosAudioController* pController = IosAudioController::getInstance();
//    pController->play();
}

+(void)currentDetectionData{
    m_curDetectingData = new CDetectingData();
    if (g_recordSoundType == RST_Doorbell) {
        m_curDetectingData->SetSoundType(g_doorbellType);
    } else {
        m_curDetectingData->SetSoundType(DT_GENERAL);
    }
}

+(void)g_pDetectMgr_RecordStart:(NSViewController *)controller :(NSString *)w_strRecordPath{
    g_pDetectMgr->RecordStart((const char*)([w_strRecordPath UTF8String]), RecordingCallback, (__bridge void*)controller);

}
void RecordingCallback(void* p_obj, int p_nType, int p_nParam)
{
//    DoorBellActivateFlowViewController* obj = (__bridge DoorBellActivateFlowViewController*)p_obj;
//    if (p_nType == RECORDING_PROGRESS)
//    {
//        printf("param - %d",p_nParam);
//        printf("p_nType - %d",p_nType);
//
//        [obj recordingProgress:p_nParam];
//    }
//    else if (p_nType == RECORD_STOP)
//    {
//        printf("p_nType - %d",p_nType);
//
//        [obj recordStopped];
//    }
}



+(const int)eg_recordSoundType {
    return MAX_RECORD_FRAMES[g_recordSoundType];
}

+(NSString*)getRecordPath:(int)p_idx
{
    NSArray* w_pArrDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* w_pStrSoundDetectDir = [(NSString*)[w_pArrDirs objectAtIndex:0] stringByAppendingPathComponent:@"Braci"];
    
    NSError* error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:w_pStrSoundDetectDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:w_pStrSoundDetectDir withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    
    NSString* w_pRecordFilePath = [NSString stringWithFormat:@"%@/record%d.dat", w_pStrSoundDetectDir, p_idx];
    return w_pRecordFilePath;
}

+(bool) m_curDetectingData_AddProcessData : (NSString *)w_strRecordPath{
    bool bRecord = m_curDetectingData->AddProcessData((const char *)[w_strRecordPath UTF8String]);
    return bRecord;
}

+(void) saveRecordedData : (int) g_recordSoundType{
    NSString* strDetectPath = [self getDetectPath1:@"Home Mode" recordSoundType:g_recordSoundType];
    m_curDetectingData->SaveDetectData([strDetectPath UTF8String]);
    g_DetectData[ g_recordSoundType].push_back(m_curDetectingData);
}

+(NSString*)getDetectPath1:(NSString*)mode recordSoundType:(int)p_soundType
{
    NSArray* w_pArrDirs = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString* w_pStrSoundDetectDir = [(NSString*)[w_pArrDirs objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/Braci/%d",mode, p_soundType]];
    
    NSError* error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:w_pStrSoundDetectDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:w_pStrSoundDetectDir withIntermediateDirectories:YES attributes:nil error:&error]; //Create folder
    
    NSString* w_pRecordFilePath = [NSString stringWithFormat:@"%@/detect%d.dat", w_pStrSoundDetectDir, 0];
    return w_pRecordFilePath;
}

+(NSString*)getDetectRootPath:(NSString*)mode recordSoundType:(int)p_soundType
{
    NSArray* w_pArrDirs = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString* w_pStrSoundDetectDir = [(NSString*)[w_pArrDirs objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/Braci/%d",mode, p_soundType]];
    
    NSError* error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:w_pStrSoundDetectDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:w_pStrSoundDetectDir withIntermediateDirectories:YES attributes:nil error:&error]; //Create folder
    
    return w_pStrSoundDetectDir;
}

+(NSString *)getWevFile:(int)type1 {
    NSArray* w_pArrDirs = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString* w_pStrSoundDetectDir = [(NSString*)[w_pArrDirs objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"Home Mode/Braci/%d", type1]];
    NSError* error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:w_pStrSoundDetectDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:w_pStrSoundDetectDir withIntermediateDirectories:YES attributes:nil error:&error]; //Create folder
    return [NSString stringWithFormat:@"%@/detect%d.wav", w_pStrSoundDetectDir, 0];
}


+(bool) m_curDetecting_Data_GetRecordedCnt{
    if (m_curDetectingData->GetRecordedCnt() == MAX_RECORD_TIMES)
        return true;
    else
        return false;
}
+(bool) m_curDetecting_ExtractDetectingData{
    if (m_curDetectingData->ExtractDetectingData())
        return true;
    else
        return false;
}

+(BOOL)isDatFileExist:(int)type1{
    BOOL isFound=NO;
    NSArray* w_pArrDirs = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString* w_pStrSoundDetectDir = [(NSString*)[w_pArrDirs objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"Home Mode/Braci/%d", type1]];
    
    NSError* error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:w_pStrSoundDetectDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:w_pStrSoundDetectDir withIntermediateDirectories:YES attributes:nil error:&error]; //Create folder
    
    NSString* w_pRecordFilePath = [NSString stringWithFormat:@"%@/detect%d.dat", w_pStrSoundDetectDir, 0];
    if ([[NSFileManager defaultManager] fileExistsAtPath:w_pRecordFilePath]){
        isFound=YES;
    }
    NSString* w_pRecordFilePath1 = [NSString stringWithFormat:@"%@/detect%d.wav", w_pStrSoundDetectDir, 0];
    if ([[NSFileManager defaultManager] fileExistsAtPath:w_pRecordFilePath1]){
        isFound=YES;
    }
    return isFound;
}

+(void)removeFileSync {
    NSLog(@"\n============ Deleting file with the SYNC API ============");
    
//    @try {
//        id result = [backendless.fileService remove:@"myfiles/myhelloworld-sync.txt"];
//        NSLog(@"File has been removed: result = %@", result);
//    }
//    @catch (Fault *fault) {
//        NSLog(@"Server reported an error: %@", fault);
//    }
}

+(void)deleteDatFile:(int)type1{
    NSArray* w_pArrDirs = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString* w_pStrSoundDetectDir = [(NSString*)[w_pArrDirs objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"Home Mode/Braci/%d", type1]];
    NSError* error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:w_pStrSoundDetectDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:w_pStrSoundDetectDir withIntermediateDirectories:YES attributes:nil error:&error]; //Create folder
    NSString* w_pRecordFilePath = [NSString stringWithFormat:@"%@/detect%d.dat", w_pStrSoundDetectDir, 0];
    NSString* w_pRecordFilePath1 = [NSString stringWithFormat:@"%@/detect%d.wav", w_pStrSoundDetectDir, 0];

    if ([[NSFileManager defaultManager] fileExistsAtPath:w_pRecordFilePath] ){
        [[NSFileManager defaultManager]removeItemAtPath:w_pRecordFilePath error:nil];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:w_pRecordFilePath1] ){
        [[NSFileManager defaultManager]removeItemAtPath:w_pRecordFilePath1 error:nil];
    }
}

+(bool)APP_IS_BACKGROUND{
    return APP_IS_BACKGROUND;
}
+(void)SET_APP_IS_BACKGROUND : (bool) value{
    APP_IS_BACKGROUND = value;
}

+(void)SET_TorchLight : (BOOL) status{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        
        AVCaptureDevice *device = [captureDeviceClass defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        [device lockForConfiguration:nil];
        if ( [device hasTorch] ) {
            if ( status ) {
                [device setTorchMode:AVCaptureTorchModeOn];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
            }
        }
        [device unlockForConfiguration];
    }
}
+(void)terminateEngine{
//    IosAudioController* pController = IosAudioController::getInstance();
//    if (pController != nullptr && pController->isOpened())
//    {
//        pController->close();
//        pController = nullptr;
//    }
//
    if (g_pDetectMgr != nullptr)
    {
        delete g_pDetectMgr;
        g_pDetectMgr = nullptr;
    }
    
    if (g_fBufData != nullptr)
    {
        delete[] g_fBufData;
        g_fBufData = nullptr;
    }
    
    if (g_audioInfo != nullptr)
    {
        delete g_audioInfo;
        g_audioInfo = nullptr;
    }
}
+(void)restartEngine{
//    IosAudioController* pController = IosAudioController::getInstance();
//    if (pController != nullptr && pController->isOpened())
//    {
//        pController->close();
//    }
    
    int nRecordChannels = 1;
    g_RecOutBuffer.Init(1 * SAMPLE_FREQ * nRecordChannels * sizeof(float));
    
//    pController->open(g_audioInfo, audioCallback);

}
+(NSMutableArray *)setArray:(id)arr {
    
    NSMutableArray *arrNotificationObj = [NSMutableArray new];
    
    NSArray *arrnotification = (NSArray *)arr;
    for (int i = 0 ; i < arrnotification.count; i++) {
        NSMutableArray *arrTemp = [NSMutableArray new];
        [arrTemp addObject:[[arrnotification objectAtIndex:i] valueForKey:@"soundType"]];
        [arrTemp addObject:[[arrnotification objectAtIndex:i] valueForKey:@"time"]];
        [arrNotificationObj addObject:arrTemp];
    }
       return arrNotificationObj;
}
+(NSString *)findDetectionCount:(id)arr{
    NSString *strFindingCount = @"";
    NSArray *arrdetection = (NSArray *)arr;
    for (int i = 0 ; i < arrdetection.count; i++) {
        strFindingCount = [[arrdetection objectAtIndex:0] valueForKey:@"Detection"];
    }
    return strFindingCount;
}

+(NSString *)saveDetectedSound : (id)result{
    NSString *detectionSound = @"";
    detectionSound = [result valueForKey:@"objectId"];
    return detectionSound;
}


+(void)detectionConftimation:(id)arr : (NSString *)status {
    
    NSArray *arrnotification = (NSArray *)arr;
//    userNotificationLocal *notificationObj = [arrnotification objectAtIndex:0];
//    [notificationObj setValue:status forKey:@"status"];
//    Fault *error;
//    userNotificationLocal *result = [[[[Backendless sharedInstance] data] of:[userNotificationLocal class]] save:notificationObj];
}

+(void)updateDetectionCountBackendLess : (id)result : (NSString *)count{
    
    NSArray *arrnotification = (NSArray *)result;
//    userNotificationLocal *notificationObj = [arrnotification objectAtIndex:0];
//    [notificationObj setValue:count forKey:@"Detection"];
    
//    id<IDataStore> dataStore = [backendless.persistenceService of:[detectionRemLocal class]];
//    [dataStore save:notificationObj response:^(id) {
//    } error:^(Fault *error) {
//    }];
//    [dataStore save:notificationObj responder:responder];
}

+(void)removeDetectionCountBackendLess : (id)result : (NSString *)count{
    NSArray *arrnotification = (NSArray *)result;
//    detectionRemLocal *notificationObj = [arrnotification objectAtIndex:0];
//    id<IDataStore> dataStore = [backendless.persistenceService of:[detectionRemLocal class]];
//    [dataStore remove:notificationObj response:^(id) {
//    } error:^(Fault *error) {
//    }];
    
}
+(NSString *)GetObjectIDDetectionRem : (id)result : (NSString *)count{
    NSString *detectionSound = @"";
    detectionSound = [result valueForKey:@"objectId"];
    return detectionSound;
}

+(void)globalsMethodVariable_get_PEBBLE_UUID_New{
    uuid_t myAppUUIDbytes;
    //    NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:@"1418c10e-d59e-44b7-ae06-c9687d77b0b5"];
    NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:[NSString stringWithUTF8String:PEBBLE_UUID]];
    [myAppUUID getUUIDBytes:myAppUUIDbytes];
    
//    [[PBPebbleCentral defaultCentral] setAppUUID:[NSData dataWithBytes:myAppUUIDbytes length:16]];
    
    NSLog(@"Pebble Log  - Called Method Name - startPebbleApp - Pebble UUID - %s",PEBBLE_UUID);
}

+(void)updateCompanyKeyStatus : (id)result {
    
    NSArray *arrnotification = (NSArray *)result;
//    CompanyKeyLocal *statusKey = [CompanyKeyLocal alloc];
//    statusKey = [[arrnotification objectAtIndex:0] mutableCopy];
//    [statusKey setValue:@"Active" forKey:@"keyStatus"];
    
//    id<IDataStore> dataStore = [backendless.persistenceService of:[CompanyKeyLocal class]];
//    [dataStore save:statusKey response:^(id) {
//        [[NSUserDefaults standardUserDefaults] synchronize];
//
//    } error:^(Fault *error) {
//    }];
}
+(int)SendPebbleSignalsWhenDetect:(int)pebbleValue{
    __block int changeValue;
    
    changeValue = pebbleValue;

//    if (shareInstance.g_pebbleWatch != nil) {
//        uuid_t myAppUUIDbytes;
//        NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:[NSString stringWithUTF8String:PEBBLE_UUID]];
//        [myAppUUID getUUIDBytes:myAppUUIDbytes];
//
//        [shareInstance.g_pebbleWatch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update)
//         {
//             if (update == nil)
//                 return YES;
//             NSArray *values = [update allValues];
//             if ([values count] > 0) {
//                 NSNumber* value = [values objectAtIndex:0];
//                 if ([value intValue] == 1000)
//                 {
//                     [[NSNotificationCenter defaultCenter] postNotificationName:@"pebble_stopped" object:nil];
//                     changeValue = 111;
//                 } else {
//
//                 }
//             }
//
//             return YES;
//         } withUUID:[NSData dataWithBytes:myAppUUIDbytes length:16]];
//    }
    return changeValue;
}
+(NSDictionary *)converNumberToUTF8 : (int)signal{
    return @{ @(0): @0}; //[NSNumber numberWithUint8:signal]
}


@end


