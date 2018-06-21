#pragma once

#include "FFT.h"
#include <vector>
#include "DetectingData.h"

typedef void (*LPFUNC_RECORDING)(void*, int, int);

#define MAX_FREQ_CNT 10

class CDetectMgr
{
public:
	CDetectMgr(int p_nSamplingFreq, int p_nFrameLen);
	~CDetectMgr(void);

    void RecordStart(const char* lpszFilePath, LPFUNC_RECORDING lpFuncRecording, void* p_obj);
    void RecordStop();
    bool IsRecording();
    bool IsRecordingOrPreparing();
    
    bool Process(float* p_fData, int p_nFrameLen, int p_nFreqFrame, int p_nThreshold, float* p_fFreqs, float* p_fVals);
	void ClearFftValues();
    
    void SetDetectSmokeAlarmOnly(bool bEnable);
    
    void initFreqVal(int cnt);
    void terminateFreqVal();
    
private:

	bool CheckMatched(CDetectingData* p_DetectData, bool bMachineSound, float p_fMatchThreshold = -1.0f);
  
	int GetMatchedCount(float* p_fVals, std::vector<AmpInfo>* p_lstDetectAmpInfos, float p_fThreshold, bool bMachineSound);
    
    void Recording(float* pVals);
    
    void ResetFrameInfo();
    
public:
    float *m_fMaxFreqs[MAX_FREQ_CNT];
    float *m_fMaxVals[MAX_FREQ_CNT];
    float* m_pRealValsToDraw;
    
    /** max, min amplitude for silent frames */
    float m_fMaxAmpForSilent;
    float m_fMinAmpForSilent;

    float m_fMaxValue;

private:
//    AppDelegate *delegate;
	FFT* fft;
	std::vector<float*> m_vecFftVals;

	int minIdx;
	int maxIdx;
    
    bool m_bDetectSmokeAlarmOnly;

	int m_nDetectedFrames;

	float* m_fGroupAvgAmps;
    
    bool m_bRecording;
    FILE* m_pFileRecording;
    int m_nRecordingFrames;
    
    LPFUNC_RECORDING m_lpFuncRecording;
    void* m_pObj;
    
    /** Universal Engine Varaibles */
    int m_nUnivEngineFrameCnt;
    int m_nUnivEngineInvalidCnt;
    int m_nUnivEngineRepeatCnt;
    
    /** For drawing graph */
    int* m_pFreqIndicesToDraw;
    
};

