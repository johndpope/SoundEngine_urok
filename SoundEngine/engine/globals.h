#pragma once
#include <vector>
#include <string>
#include "RWBuffer.h"

class CDetectingData;
class CDetectMgr;

enum RecordSoundType {
    RST_Doorbell=0,
    RST_BackDoorbell,
    RST_SmokeAlarm,
    RST_Linephone,
    RST_Intercom,
    RST_CO2,
    RST_AlarmClock,
    RST_Theft,
    RST_Microwave,
    RST_AmplicomDoorbell,
    RST_BellmanAlarmClock,
    RST_BellmanAlarmClock2,
     RST_BellmanAlarmClock3,
     RST_BellmanBabyCrying,
      RST_BellmanDoorbell,
     RST_BellmanSmokeAlarm,
      RST_BellmanLandline,
      RST_ByronDoorbell,
     RST_ByronDoorbell2,
     RST_ByronDoorbell3,
     RST_ByronDoorbell4,
     RST_ByronDoorbell5,
     RST_ByronDoorbell6,
     RST_ByronDoorbell7,
     RST_ByronDoorbell8,
    RST_ByronDoorbell9,
    RST_ByronDoorbell10,
    RST_ByronDoorbell11,
    RST_ByronDoorbell12,
    RST_ByronDoorbell13,
    RST_ByronDoorbell14,
    RST_ByronDoorbell15,
    RST_ByronDoorbell16,
    RST_EchoAlarmClock,
    RST_EchoDoorbel,
    RST_EchoDoorbel2,
    RST_EchoDoorbel3,
    RST_EchoDoorbel4,
    RST_EchoDoorbel5,
    RST_EchoDoorbel6,
    RST_EchoDoorbel7,
    RST_EchoDoorbel8,
    RST_EchoDoorbel9,
    RST_EchoDoorbel10,
    RST_EchoDoorbel11,
    RST_EchoDoorbel12,
    RST_EchoDoorbel13,
    RST_EchoDoorbel14,
    RST_EchoDoorbel15,
    RST_EchoDoorbel16,
    RST_EchoDoorbel17,
    RST_EchoDoorbel18,
    RST_EchoDoorbel19,
    RST_EchoDoorbel20,
    RST_EchoDoorbel21,
    RST_EchoDoorbel22,
    RST_EchoDoorbel23,
    RST_EchoDoorbel24,
    RST_EchoDoorbel25,
    RST_EchoDoorbel26,
    RST_EchoDoorbel27,
    RST_EchoDoorbel28,
    RST_EchoDoorbel29,
    RST_EchoDoorbel30,
    RST_EchoDoorbel31,
    RST_EchoDoorbel32,
    RST_EchoDoorbel33,
    RST_EchoDoorbel34,
    RST_EchoDoorbel35,
    RST_EchoDoorbel36,
    RST_EchoDoorbel37,
    RST_EchoDoorbel38,
    RST_EchoTelephone,
     RST_FriedLandEvoDoorbell,
     RST_FriedLandEvoDoorbell2,
     RST_FriedLandEvoDoorbell3,
     RST_FriedLandEvoDoorbell4,
     RST_FriedLandEvoDoorbell5,
     RST_FriedLandEvoDoorbell6,
    RST_FriedLandLibraDoorbell,
    RST_FriedLandLibraDoorbell2,
    RST_FriedLandLibraDoorbell3,
    RST_FriedLandLibraDoorbell4,
    RST_FriedLandLibraDoorbell5,
    RST_FriedLandLibraDoorbell6,
    RST_FriedLandLibraTelephone,
    RST_FriedLandPluginDoorbell,
    RST_FriedLandPluginDoorbell2,
    RST_FriedLandPluginDoorbell3,
    RST_FriedLandPluginDoorbell4,
    RST_FriedLandPluginDoorbell5,
    RST_FriedLandPluginDoorbell6,
    RST_GreenMarkAmplicallLandline,
    RST_GreenMarkCL1Landline,
     RST_GreenMarkCL2Landline,
     RST_GreenGreenBrookDoorbell,
     RST_GreenGreenBrookDoorbell1,
     RST_GreenGreenBrookDoorbell2,
    RST_SOS,
    RST_MealTime,
    RST_BedTime,
    RST_Yes,
    RST_No,
    RST_WakeUp,
    RST_LocateMe,
    RST_COUNT,
};

enum DoorbellType {
	DT_GENERAL = 0,
	DT_DingDong,
	DT_MetalBell,
	DT_Buzzer,
	DT_Melody,
	DT_COUNT,
};

static const int MAX_MATCH_FRAME_CNT = 45;
static const int MAX_FIRE_SOUND_CNT = 45;
static const int SAMPLE_FREQ = 44100;
static const int FRAME_LEN = 4096;
static const int MAX_RECORD_TIMES = 1;

static const int BAND_CNT = 20;

static const int MAX_INTERCOM_FRAME_CNT = 25;   // 2.5 secs
static const int MAX_TELEPHONE_FRAME_CNT = 45;  // 4.5 secs
static const int MAX_SMOKE_FRAME_CNT = 45;      // 4.5 secs
static const int MAX_METABELL_FRAME_CNT = 20;   // 2 secs

static const int SOUND_GENERAL = 0;
static const int SOUND_DINGDONG = 1;
static const int SOUND_METABELL = 2;
static const int SOUND_BUZZER = 3;
static const int SOUND_MELODY = 4;


static const int RECORDING_PROGRESS = 1;
static const int RECORD_STOP = 2;

extern const int MAX_RECORD_FRAMES[RST_COUNT];
extern float MATCH_RATE_THRESHOLD;
extern int MAX_RECORD_FILECNT;

extern RecordSoundType g_recordSoundType;
extern DoorbellType g_doorbellType;

extern const char* g_strDoorbellTypes[DT_COUNT];

extern const float RECORD_START_THRESHOLD;

extern CDetectMgr* g_pDetectMgr;

class AudioParameterInfo;
extern AudioParameterInfo* g_audioInfo;

std::vector<std::string> split(std::string str, std::string sep);

extern RWBuffer	g_RecOutBuffer;
extern float*	g_fBufData;

int audioCallback(const void* inData, void* outData, unsigned long numSamples);

extern float*   g_fRecBuf;
extern int      g_nRecTotalSize;
extern int      g_nRecPos;

extern const char* g_strRecordingTitles[RST_COUNT];
extern const char* g_strRecordGuide3[RST_COUNT];
extern const char* g_strRecordGuide4[RST_COUNT];

extern const char* PEBBLE_UUID;

extern float DOORBELLS_THRESHOLD[DT_COUNT];
extern float RECORDED_SOUND_THRESHOLD[RST_COUNT];

extern int UNIVERSAL_THRESHOLD_DELTA;
extern float MATCHING_RATE_THRESHOLD_DELTAS[RST_COUNT];

extern bool IS_BACKGROUND;

extern bool g_isEngineTerminated;
extern bool g_bDetecting;
extern bool g_bDetected;

extern int UNIVERSAL_THRESHOLDS;

extern int UNIVERSAL_MIN_FREQ;
extern int UNIVERSAL_MAX_FREQ;
extern int UNIVERSAL_MIN_PERIOD_FRAMES;
extern int UNIVERSAL_MAX_STOP_FRAMES;
extern int UNIVERSAL_MAX_PERIOD_FRAMES;
extern int UNIVERSAL_MIN_STOP_FRAMES;
extern int UNIVERSAL_MIN_REPEATS;
extern int UNIVERSAL_DETECT_PERIOD_FRAMES;

extern char g_strSoundObjectID[1024];
extern const char* g_szDetectedTitle[RST_COUNT];
