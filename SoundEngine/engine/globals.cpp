#include "globals.h"
#include "DetectMgr.h"
#include "IAudioDriver.h"

float MATCH_RATE_THRESHOLD = 0.90f;
int MAX_RECORD_FILECNT = 51;

RecordSoundType g_recordSoundType;
DoorbellType g_doorbellType;

std::vector<CDetectingData*> g_DetectData[RST_COUNT];



const int MAX_RECORD_FRAMES[RST_COUNT] = {
    40960 * 5, /* Doorbell Max Frames */
    40960 * 5, /* BackDoorbell Max Frames */
    40960 * 5, /* Smoke Max Frames */
    
    40960 * 5, /* Telephone Max Frames */
    40960 * 5, /* Intercom Max Frames */
    40960 * 5, /* CO2 Max Frames */
    40960 * 5, /* AlarmClock Max Frames */
    40960 * 5, /* Theft Max Frames */
    40960 * 5, /* Microwave Max Frames */
    40960 * 4,/*AmplicomDoorbell*/
    40960 * 4,/*Bellman AlarmClock*/
     40960 * 4,/*Bellman AlarmClock*/
      40960 * 4,/*Bellman AlarmClock*/
     40960 * 4,/*Bellman Baby Crying*/
    40960 * 4,/*Bellman Doorbell*/
    40960 * 4,/*Bellman Smoke Alarm*/
     40960 * 6, /* Telephone Max Frames */
     40960 * 4,/*Byron Doorbell*/
      40960 * 4,/*Byron Doorbell*/
      40960 * 4,/*Byron Doorbell*/
      40960 * 4,/*Byron Doorbell*/
      40960 * 4,/*Byron Doorbell*/
      40960 * 4,/*Byron Doorbell*/
      40960 * 4,/*Byron Doorbell*/
      40960 * 4,/*Byron Doorbell*/
     40960 * 4,/*Byron Doorbell*/
     40960 * 4,/*Byron Doorbell*/
     40960 * 4,/*Byron Doorbell*/
     40960 * 4,/*Byron Doorbell*/
     40960 * 4,/*Byron Doorbell*/
     40960 * 4,/*Byron Doorbell*/
     40960 * 4,/*Byron Doorbell*/
     40960 * 4,/*Byron Doorbell*/
    40960 * 4,/*Echo AlarmClock*/
    40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 4, /*Echo Doorbell  */
     40960 * 6, /* Echo Telephone Max Frames */
     40960 * 4, /*FriedLandEvo Doorbell  */
    40960 * 4, /*FriedLandEvo Doorbell  */
    40960 * 4, /*FriedLandEvo Doorbell  */
    40960 * 4, /*FriedLandEvo Doorbell  */
    40960 * 4, /*FriedLandEvo Doorbell  */
    40960 * 4, /*FriedLandEvo Doorbell  */
    
    40960 * 4, /*FriedLandLibra Doorbell  */
    40960 * 4, /*FriedLandLibra Doorbell  */
    40960 * 4, /*FriedLandLibra Doorbell  */
    40960 * 4, /*FriedLandLibra Doorbell  */
    40960 * 4, /*FriedLandLibra Doorbell  */
    40960 * 4, /*FriedLandLibra Doorbell  */
     40960 * 6, /* FriedLandLibra Telephone Max Frames */
     40960 * 4, /*FriedLandPlugin Doorbell  */
    40960 * 4, /*FriedLandPlugin Doorbell  */
    40960 * 4, /*FriedLandPlugin Doorbell  */
    40960 * 4, /*FriedLandPlugin Doorbell  */
    40960 * 4, /*FriedLandPlugin Doorbell  */
    40960 * 4, /*FriedLandPlugin Doorbell  */
     40960 * 6, /* GreenMarkAmplicall Telephone Max Frames */
     40960 * 6, /* GreenMarkCL1 Telephone Max Frames */
     40960 * 6, /* GreenMarkCL2 Telephone Max Frames */
     40960 * 4, /*GreenBrook Doorbell  */
     40960 * 4, /*GreenBrook Doorbell  */
     40960 * 4, /*GreenBrook Doorbell  */
};


const char* g_strDoorbellTypes[DT_COUNT] = {"General", "DingDong", "MetalBell",
	"Buzzer", "Melody"};

const char* PEBBLE_UUID = "69721c7e-69ef-40eb-a687-5649124ab141";


const float RECORD_START_THRESHOLD = 1.0f;

bool g_isEngineTerminated = true;
bool g_bDetecting = false;
bool g_bDetected = false;


const char* g_strRecordingTitles[RST_COUNT] =
        {"Doorbell",
         "Back Doorbell",
         "Smoke Alarm",
         "Landline",
         "Intercom",
         "CO2",
         "Alarm Clock",
         "Theft Alarm",
         "Microwave",
         "Amplicom Doorbell",
          "Bellman AlarmClock",
           "Bellman AlarmClock",
           "Bellman AlarmClock",
             "Bellman BabyzCrying ",
            "Bellman Doorbell ",
              "Bellman Smoke Alarm ",
             "Bellman Landline ",
              "Byron doorbell ",
             "Byron doorbell ",
             "Byron doorbell ",
             "Byron doorbell ",
             "Byron doorbell ",
             "Byron doorbell ",
             "Byron doorbell ",
             "Byron doorbell ",
            "Byron doorbell ",
            "Byron doorbell ",
            "Byron doorbell ",
            "Byron doorbell ",
            "Byron doorbell ",
            "Byron doorbell ",
            "Byron doorbell ",
            "Byron doorbell ",
            "Echo alarmclock ",
             "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
            "Echo doorbell ",
             "Echo Telephone Ringing ",
           "FriedLandEvo doorbell ",
             "FriedLandEvo doorbell ",
             "FriedLandEvo doorbell ",
             "FriedLandEvo doorbell ",
             "FriedLandEvo doorbell ",
             "FriedLandEvo doorbell ",
            
            "FriedLandLibra doorbell ",
            "FriedLandLibra doorbell ",
            "FriedLandLibra doorbell ",
            "FriedLandLibra doorbell ",
            "FriedLandLibra doorbell ",
            "FriedLandLibra doorbell ",
            "FriedLandLibra Telephone Ringing ",
             "FriedLandPlugin doorbell ",
             "FriedLandPlugin doorbell ",
             "FriedLandPlugin doorbell ",
             "FriedLandPlugin doorbell ",
             "FriedLandPlugin doorbell",
             "FriedLandPlugin doorbell ",
             "GreenMarkAmplicall Landline ",
            "GreenMarkCL1 Landline ",
             "GreenMarkCL2 Landline ",
             "GreenBrook Doorbell ",
            "GreenBrook Doorbell ",
            "GreenBrook Doorbell ",
         };

const char* g_strRecordGuide3[RST_COUNT] =
    {"Go to your doorbell button and be ready to press it.",
      "Go to your backdoorbell button and be ready to press it.",
        
     "Please go to your Smoke Alarm and be ready to press the test button."
        "Please go to your phone and be ready to call it.",
    "Please be ready to press the intercom button.",
         "Please be ready to for CO2 recording.",
         "Please be ready to for AlarmClock recording.",
          "Please be ready to for Theft recording.",
          "Please be ready to for Microwave recording.",
         "Please be ready to for Amplicom Doorbell recording.",
         "Please be ready to for Bellman AlarmClock recording.",
         "Please be ready to for Bellman AlarmClock recording.",
         "Please be ready to for Bellman AlarmClock recording.",
        "Please be ready to for Bellman BabyCrying recording.",
         "Please be ready to for Bellman Doorbell recording.",
         "Please be ready to for Bellman smoke alarm recording.",
         "Please be ready to for Bellman landline recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
        "Please be ready to for Byron doorbell recording.",
        "Please be ready to for Byron doorbell recording.",
        "Please be ready to for Byron doorbell recording.",
        "Please be ready to for Byron doorbell recording.",
        "Please be ready to for Byron doorbell recording.",
        "Please be ready to for Byron doorbell recording.",
        "Please be ready to for Byron doorbell recording.",
        "Please be ready to for Byron doorbell recording.",
        "Please be ready to for Echo AlarmClock recording.",
         "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
          "Please be ready to for Echo Doorbell recording.",
         "Please be ready to for Echo landline recording.",
        "Please be ready to for FriedLandEvo Doorbell recording.",
        "Please be ready to for FriedLandEvo Doorbell recording.",
        "Please be ready to for FriedLandEvo Doorbell recording.",
        "Please be ready to for FriedLandEvo Doorbell recording.",
        "Please be ready to for FriedLandEvo Doorbell recording.",
        "Please be ready to for FriedLandEvo Doorbell recording.",
        
        "Please be ready to for FriedLandLibra Doorbell recording.",
        "Please be ready to for FriedLandLibra Doorbell recording.",
        "Please be ready to for FriedLandLibra Doorbell recording.",
        "Please be ready to for FriedLandLibra Doorbell recording.",
        "Please be ready to for FriedLandLibra Doorbell recording.",
        "Please be ready to for FriedLandLibra Doorbell recording.",
        "Please be ready to for FriedLandLibra landline recording.",
         "Please be ready to for FriedLandPlugin Doorbell recording.",
         "Please be ready to for FriedLandPlugin Doorbell recording.",
         "Please be ready to for FriedLandPlugin Doorbell recording.",
         "Please be ready to for FriedLandPlugin Doorbell recording.",
         "Please be ready to for FriedLandPlugin Doorbell recording.",
         "Please be ready to for FriedLandPlugin Doorbell recording.",
         "Please be ready to for GreenMarkAmplicall Landline  recording.",
        "Please be ready to for GreenMarkCL1 Landline  recording.",
         "Please be ready to for GreenMarkCL2 Landline  recording.",
          "Please be ready to for GreenBrook doorbell  recording.",
          "Please be ready to for GreenBrook doorbell  recording.",
          "Please be ready to for GreenBrook doorbell  recording.",
   };

const char* g_strRecordGuide4[RST_COUNT] =
    {
        "Go to your doorbell button and be ready to press it.",
        "Go to your backdoorbell button and be ready to press it.",
        
        "Please go to your Smoke Alarm and be ready to press the test button."
        "Please go to your phone and be ready to call it.",
        "Please be ready to press the intercom button.",
        "Please be ready to for CO2 recording.",
        "Please be ready to for AlarmClock recording.",
        "Please be ready to for Theft recording.",
        "Please be ready to for Microwave recording.",
         "Please be ready to for Amplicom Doorbell recording.",
         "Please be ready to for Bellman AlarmClock recording.",
         "Please be ready to for Bellman AlarmClock recording.",
         "Please be ready to for Bellman AlarmClock recording.",
         "Please be ready to for Bellman BabyCrying recording.",
         "Please be ready to for Bellman doorbell recording.",
          "Please be ready to for Bellman smoke alarm recording.",
         "Please be ready to for Bellman landline recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
         "Please be ready to for Byron doorbell recording.",
        "Please be ready to for Echo AlarmClock recording.",
         "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
          "Please be ready to for Echo doorbell recording.",
         "Please be ready to for Echo landline recording.",
        "Please be ready to for FriedLandEvo Doorbell recording.",
        "Please be ready to for FriedLandEvo Doorbell recording.",
        "Please be ready to for FriedLandEvo Doorbell recording.",
        "Please be ready to for FriedLandEvo Doorbell recording.",
        "Please be ready to for FriedLandEvo Doorbell recording.",
        "Please be ready to for FriedLandEvo Doorbell recording.",
        "Please be ready to for FriedLandLibra Doorbell recording.",
        "Please be ready to for FriedLandLibra Doorbell recording.",
        "Please be ready to for FriedLandLibra Doorbell recording.",
        "Please be ready to for FriedLandLibra Doorbell recording.",
        "Please be ready to for FriedLandLibra Doorbell recording.",
        "Please be ready to for FriedLandLibra Doorbell recording.",
         "Please be ready to for FriedLandLibra landline recording.",
        "Please be ready to for FriedLandPlugin Doorbell recording.",
        "Please be ready to for FriedLandPlugin Doorbell recording.",
        "Please be ready to for FriedLandPlugin Doorbell recording.",
        "Please be ready to for FriedLandPlugin Doorbell recording.",
        "Please be ready to for FriedLandPlugin Doorbell recording.",
        "Please be ready to for FriedLandPlugin Doorbell recording.",
         "Please be ready to for GreenMarkAmplicall Landline  recording.",
         "Please be ready to for GreenMarkCL1 Landline  recording.",
        "Please be ready to for GreenMarkCL2 Landline  recording.",
        "Please be ready to for GreenBrook doorbell  recording.",
        "Please be ready to for GreenBrook doorbell  recording.",
        "Please be ready to for GreenBrook doorbell  recording.",
        
        };

float DOORBELLS_THRESHOLD[DT_COUNT] =
{
	/* None */0.90f,
	/* Ding-Dong */0.85f,
	/* Meta-Bell */0.70f,
	/* Buzzer */0.80f,
	/* Melody */0.70f
};




int UNIVERSAL_THRESHOLD_DELTA = 0;
float MATCHING_RATE_THRESHOLD_DELTAS[RST_COUNT] = {0};

float RECORDED_SOUND_THRESHOLD[RST_COUNT] =
{   /* Doorbell */ 0.80f,
   /* BackDoorbell */ 0.80f,
    /* SmokeAlarm */ 0.80f,
    /* Telephone */ 0.80f,
	/* Intercom */ 0.80f,
	/* CO2 */ 0.80f,
	/* AlarmClock */ 0.80f,
    /* Theft */ 0.80f,
    /* Microwave */ 0.80f,
    /* Amplicom Doorbell*/ 0.80f,
    /* Bellman AlarmClock*/ 0.80f,
    /* Bellman AlarmClock*/ 0.80f,
     /* Bellman AlarmClock*/ 0.80f,
     /* Bellman BabyCrying*/ 0.80f,
     /* Bellman doorbell*/ 0.80f,
     /* Bellman smoke alarm*/ 0.80f,
    /* Bellman landline*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
     /* Byron doorbell*/ 0.80f,
    /* Echo AlarmClock*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
     /* Echo doorbell*/ 0.80f,
    /* Echo Telephone */ 0.80f,
     /* FriedLandEvo doorbell*/ 0.80f,
      /* FriedLandEvo doorbell*/ 0.80f,
      /* FriedLandEvo doorbell*/ 0.80f,
      /* FriedLandEvo doorbell*/ 0.80f,
      /* FriedLandEvo doorbell*/ 0.80f,
      /* FriedLandEvo doorbell*/ 0.80f,
    
    /* FriedLandLibra doorbell*/ 0.80f,
    /* FriedLandLibra doorbell*/ 0.80f,
    /* FriedLandLibra doorbell*/ 0.80f,
    /* FriedLandLibra doorbell*/ 0.80f,
    /* FriedLandLibra doorbell*/ 0.80f,
    /* FriedLandLibra doorbell*/ 0.80f,
     /* FriedLandLibra Telephone */ 0.80f,
    /* FriedLandPlugin doorbell*/ 0.80f,
    /* FriedLandPlugin doorbell*/ 0.80f,
    /* FriedLandPlugin doorbell*/ 0.80f,
    /* FriedLandPlugin doorbell*/ 0.80f,
    /* FriedLandPlugin doorbell*/ 0.80f,
    /* FriedLandPlugin doorbell*/ 0.80f,
     /* GreenMarkAmplicall Telephone */ 0.80f,
     /* GreenMarkCL1 Telephone */ 0.80f,
     /* GreenMarkCL2 Telephone */ 0.80f,
     /* GreenBrook doorbell*/ 0.80f,
     /* GreenBrook doorbell*/ 0.80f,
     /* GreenBrook doorbell*/ 0.80f,
};

bool IS_BACKGROUND = false;
CDetectMgr* g_pDetectMgr;
AudioParameterInfo* g_audioInfo = nullptr;

std::vector<std::string> split(std::string str, std::string sep)
{
    char* cstr=const_cast<char*>(str.c_str());
    char* current;
    std::vector<std::string> arr;
    current=strtok(cstr, sep.c_str());
    while(current!=NULL){
        arr.push_back(current);
        current=strtok(NULL,sep.c_str());
    }
    
    return arr;
}

RWBuffer    g_RecOutBuffer;
float*	    g_fBufData;

float*      g_fRecBuf = nullptr;
int         g_nRecTotalSize = 0;
int         g_nRecPos = 0;

// Standard Values


//int UNIVERSAL_THRESHOLDS = 20;
int UNIVERSAL_THRESHOLDS = 100;

int UNIVERSAL_MIN_FREQ = 1320;
int UNIVERSAL_MAX_FREQ = 3650;
int UNIVERSAL_MIN_PERIOD_FRAMES = 5;
int UNIVERSAL_MAX_PERIOD_FRAMES = 10;
int UNIVERSAL_MIN_STOP_FRAMES = 5;
int UNIVERSAL_MAX_STOP_FRAMES = 15;
int UNIVERSAL_MIN_REPEATS = 3;
int UNIVERSAL_DETECT_PERIOD_FRAMES = 40;


/*
//Previous Values (Testing values)
int UNIVERSAL_THRESHOLDS = 30;

int UNIVERSAL_MIN_FREQ = 500;
int UNIVERSAL_MAX_FREQ = 5000;
int UNIVERSAL_MIN_PERIOD_FRAMES = 5;
int UNIVERSAL_MAX_STOP_FRAMES = 20;
int UNIVERSAL_MAX_PERIOD_FRAMES = 30;
int UNIVERSAL_MIN_STOP_FRAMES = 10;
int UNIVERSAL_MIN_REPEATS = 2;
int UNIVERSAL_DETECT_PERIOD_FRAMES = 40;
*/


int audioCallback(const void* inData, void* outData, unsigned long numSamples) {
    
    //long samples = numSamples;
   
    
    float **in = (float **)inData;
    
    if (g_RecOutBuffer.GetWriteSpace() < (int)(numSamples * sizeof(float)))
    { 
        //... 록음자료를 출력할 빈 령역이 부족한 상태
    }
    else
    {
        
        g_RecOutBuffer.WriteData(in[0], (int)numSamples*sizeof(float));
    }
    
    return 0;
}

char g_strSoundObjectID[1024] = {0};

const char* g_szDetectedTitle[RST_COUNT] = {
    
    "Doorbell Detected",
    "Back Doorbell Detected",
    "Smoke Alarm Detected",
    "Landline Ringing",
    "Intercom Detected",
    "CO2 Detected",
    "Alarm Clock Detected",
    "Theft Alarm Detected",
    "Microwave Finished",
    "AmplicomDoorbell",
    "Bellman AlarmClock",
    "Bellman AlarmClock",
    "Bellman AlarmClock",
    "Bellman BabyCrying",
    "Bellman Doorbell",
    "Bellman SmokeAlarm",
    "Bellman LandLine",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Byron doorbell",
    "Echo alarmclock",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo doorbell",
    "Echo landline",
    "FriedLandEvo doorbell",
    "FriedLandEvo doorbell",
    "FriedLandEvo doorbell",
    "FriedLandEvo doorbell",
    "FriedLandEvo doorbell",
    "FriedLandEvo doorbell",
    "FriedLandLibra doorbell",
    "FriedLandLibra doorbell",
    "FriedLandLibra doorbell",
    "FriedLandLibra doorbell",
    "FriedLandLibra doorbell",
    "FriedLandLibra doorbell",
    "FriedLandLibra landline",
    "FriedLandPlugin doorbell",
    "FriedLandPlugin doorbell",
    "FriedLandPlugin doorbell",
    "FriedLandPlugin doorbell",
    "FriedLandPlugin doorbell",
    "FriedLandPlugin doorbell",
    "GreenMarkAmplicall Landline",
    "GreenMarkCL1 Landline",
    "GreenMarkCL2 Landline",
    "GreenBrook doorbell",
    "GreenBrook doorbell",
    "GreenBrook doorbell",
    "SOS",
    "Meal Time",
    "Bed Time",
    "Yes",
    "No",
    "Wake Up",
    "Locate Me",
    
    
};
