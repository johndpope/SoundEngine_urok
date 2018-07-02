//
//  bridgeClass.h
//  BraciPro
//
//  Created by Rajat on 01/06/16.
//  Copyright © 2016 Solulab. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>
#import <Cocoa/Cocoa.h>

@interface bridgeClass : NSObject

+(void)globalsmethod;
+(bool)get_g_bDetecting;
+(bool)get_g_isEngineTerminated;
+(void)set_g_isEngineTerminated : (bool) value;
+(void)set_g_bDetecting : (bool) value;
+(float *)get_g_fBufData;
+(bool) get_ReadData : (float *) buffer : (int) frameLen;
+(bool)get_g_pDetectMgr_IsRecordingOrPreparing;
+(bool)get_g_pDetectMgr_isnill;

+(float *)get_g_fRecBuf;
+(int)get_recBuf_total_size;
+(int)get_recBuf_pos;
+(void)set_recBuf_pos: (int)pos;
+(void)RecStart : (int) p_micDetectionTime : (int) p_micThreshold : (int) p_recMode : (int) p_recFreqFrame : (int) p_recThreshold : (int) p_recBandWidth : (int) p_recRepeatCnt;
+(void)RecStop;

+(NSArray *)get_g_pDetectMgr_ProcessRec;
+(NSArray *)get_g_pDetectMgr_ProcessFile : (float *) buffData : (int) totalLen : (int) frameLen : (int) freqFrame : (int) threshold : (int) bandWidth : (int) repeatCnt;
+(NSArray *)get_max_freqs_vals :(int)idx : (int)cnt;
+(NSArray *)get_other_results;
+(NSArray *)get_impulse_vals;

+(void)set_SetDetectSmokeAlarmOnly : (bool) value;
+(const char *)globalsMethodVariable_get_PEBBLE_UUID;
+(int) get_SAMPLE_FREQ;
+(void) set_g_pDetectMgr_SAMPLE_FREQ;
+(void) set_g_pDetectMgr_SAMPLE_FREQ : (int) rate : (int) frameLen;
+(void) initEngine;
+(int) get_RST_COUNT;
+(void) set_MATCHING_RATE_THRESHOLD_DELTAS : (int) value : (NSString *) strKey;
+(void) set_UNIVERSAL_THRESHOLD_DELTA : (NSString *) strKey;
+(int) get_UNIVERSAL_THRESHOLD_DELTA;
+(void) initData : (NSString *) strDetectPath : (int32_t) soundType;
+(void)set_g_bDetected : (bool) value;
+(bool)set_pController;
+(bool)set_pController_isOpen;
+(void)set_pController_pause;
+(void)set_pController_play;
+(void)currentDetectionData;
+(void)g_pDetectMgr_RecordStart:(NSViewController *)controller :(NSString *)w_strRecordPath;
+(NSString*)getRecordPath:(int)p_idx;
+(const int)eg_recordSoundType;
+(void) saveRecordedData : (int) g_recordSoundType;
+(NSString*)getDetectPath1:(NSString*)mode recordSoundType:(int)p_soundType;
+(NSString*)getDetectRootPath:(NSString*)mode recordSoundType:(int)p_soundType;
+(bool) m_curDetecting_ExtractDetectingData;
+(int)globalsMethodVarible_get_g_pDetectMgr_alarmType;
+(BOOL)isDatFileExist:(int)type1;
+(void)deleteDatFile:(int)type1;
+(NSString *)getWevFile:(int)type1;
+(bool)APP_IS_BACKGROUND;
+(void)SET_APP_IS_BACKGROUND : (bool) value;
//+(void)SET_PHLightState : (PHBridgeResourcesCache *) cache : (PHBridgeSendAPI *) bridgeSendAPI;
+(void)SET_TorchLight : (BOOL) status;
+(void)terminateEngine;
+(void)restartEngine;

+(NSMutableArray *)setArray:(id)arr;
+(NSString *)findDetectionCount:(id)arr;
+(NSString *)saveDetectedSound : (id)result;
+(void)detectionConftimation:(id)arr : (NSString *)status;
+(void)updateDetectionCountBackendLess : (id)result : (NSString *)count;
+(void)removeDetectionCountBackendLess : (id)result : (NSString *)count;
+(void)globalsMethodVariable_get_PEBBLE_UUID_New;
//+(void)SendPebbleSignalsWhenDetect;
+(int)SendPebbleSignalsWhenDetect:(int)pebbleValue;
+(void)updateCompanyKeyStatus : (id)result;

+(NSString *)GetObjectIDDetectionRem : (id)result : (NSString *)count;

+(NSDictionary *)converNumberToUTF8 : (int)signal;


@end

