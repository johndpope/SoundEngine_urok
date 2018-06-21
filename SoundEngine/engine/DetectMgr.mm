#include "DetectMgr.h"
#include "globals.h"
#import <math.h>
#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>
//#import <MessageUI/MessageUI.h>
//#import "Sound_Alert-Swift.h"
//#import "BraciPro-Swift.h"
//#import "Sound Alert-Bridging-Header.h"
#import <Cocoa/Cocoa.h>

using namespace std;
float minFreqToDraw = 1; //400; // min frequency to represent graphically
float maxFreqToDraw = 10000; //5000; // max frequency to represent

const int MAX_GROUP_CNT = 2000;
const float RELATED_RATE = 1.f;

const float fDeltaThreshold = 0.1f;

CDetectMgr::CDetectMgr(int p_nSamplingFreq, int p_nFrameLen)
{
    m_fGroupAvgAmps = new float[MAX_GROUP_CNT];
    
    fft = new FFT(p_nFrameLen, (float)p_nSamplingFreq); //m_wavReader.m_Info.SamplingFreq
    fft->init();
    
    if (maxFreqToDraw > p_nSamplingFreq / 2) {
        maxFreqToDraw = p_nSamplingFreq / 2;
    }
    minIdx = fft->freqToIndex(minFreqToDraw);
    maxIdx = fft->freqToIndex(maxFreqToDraw);
    
    m_nDetectedFrames = 0;
    
    m_bDetectSmokeAlarmOnly = false;
    
    m_pFileRecording = nullptr;
    m_nRecordingFrames = 0;
    
    m_lpFuncRecording = nullptr;
    m_pObj = nullptr;
    
    m_bRecording = false;
    
    ResetFrameInfo();
    
    //    delegate=(AppDelegate*)[[UIApplication sharedApplication]delegate];
    
    m_pFreqIndicesToDraw = nullptr;
    m_pRealValsToDraw = nullptr;
    
    m_fMaxAmpForSilent = 0;
    m_fMinAmpForSilent= 0;
    
    m_fMaxAmpForSilent = 0;
    
    for (int i = 0; i < MAX_FREQ_CNT; i++) {
        m_fMaxFreqs[i] = nullptr;
        m_fMaxVals[i] = nullptr;
    }
}


CDetectMgr::~CDetectMgr(void)
{
    if (m_pFileRecording != nullptr)
    {
        fclose(m_pFileRecording);
        m_pFileRecording = nullptr;
    }
    
    if (m_pFreqIndicesToDraw != nullptr) {
        delete [] m_pFreqIndicesToDraw;
        m_pFreqIndicesToDraw = nullptr;
    }
    
    if (m_pRealValsToDraw != nullptr) {
        delete [] m_pRealValsToDraw;
        m_pRealValsToDraw = nullptr;
    }
    
    terminateFreqVal();
    
    ClearFftValues();
    delete fft;
    delete[] m_fGroupAvgAmps;
}

void CDetectMgr::ResetFrameInfo()
{
    m_nUnivEngineFrameCnt = 0;
    m_nUnivEngineInvalidCnt = 0;
    m_nUnivEngineRepeatCnt = 0;
}

void CDetectMgr::SetDetectSmokeAlarmOnly(bool bEnabled)
{
    m_bDetectSmokeAlarmOnly = bEnabled;
}

void CDetectMgr::ClearFftValues()
{
    for (std::vector<float*>::iterator iter = m_vecFftVals.begin(); iter != m_vecFftVals.end(); iter++)
    {
        float* pVals = *iter;
        delete[] pVals;
    }
    m_vecFftVals.clear();
    
    m_nDetectedFrames = 0;
}

void CDetectMgr::RecordStart(const char* lpszFilePath, LPFUNC_RECORDING lpFuncRecording, void* pObj)
{
    m_pFileRecording = fopen(lpszFilePath, "wb");
    if (m_pFileRecording == nullptr)
        return;
    
    m_bRecording = false;
    
    m_lpFuncRecording = lpFuncRecording;
    m_pObj = pObj;
    
    fprintf(m_pFileRecording, "%d\t%d\n", minIdx, maxIdx);
    m_nRecordingFrames = 0;
}

void CDetectMgr::RecordStop()
{
    if (m_pFileRecording == nullptr)
        return;
    
    fclose(m_pFileRecording);
    m_pFileRecording = nullptr;
    
    m_bRecording = false;
    
    if (m_lpFuncRecording != nullptr)
        m_lpFuncRecording(m_pObj, RECORD_STOP, 0);
    m_lpFuncRecording = nullptr;
    
}

bool CDetectMgr::CheckMatched(CDetectingData* p_DetectData, bool bMachineSound, float p_fMatchThreshold)
{
    if (p_DetectData == nullptr || p_DetectData->m_vecCommonData == nullptr || p_DetectData->m_vecCommonData->size() == 0)
        return false;
    
    if (m_vecFftVals.size() < p_DetectData->m_vecCommonData->size())
        return false;
    
    float fThreshold = p_fMatchThreshold;
    
    if (fThreshold < 0) {
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"falseSoundAlerts"])
        {
            fThreshold = 0.93f;
        }
        else
        {
            fThreshold = MATCH_RATE_THRESHOLD;
        }
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"missingAlarmSound"])
        {
            fThreshold = 0.87f;
        }
        else
        {
            fThreshold = MATCH_RATE_THRESHOLD;
        }
        
    }
    
    unsigned long nDataIdx = m_vecFftVals.size() - 1;
    unsigned long nDetectIdx = p_DetectData->m_vecCommonData->size() - 1;
    int nTotalMatchedCnt = 0;
    
    for (unsigned int i = 0; i < p_DetectData->m_vecCommonData->size(); i++) {
        vector<AmpInfo>* pDetectAmpInfos = (vector<AmpInfo>*) p_DetectData->m_vecCommonData->at(nDetectIdx);
        float* fVals = m_vecFftVals.at(nDataIdx);
        nDetectIdx--;
        nDataIdx--;
        
        if (pDetectAmpInfos->size() == 0)
            continue;
        
        int nCnt = GetMatchedCount(fVals, pDetectAmpInfos, p_fMatchThreshold,
                                   bMachineSound);
        if (nCnt < 0){
            
            return false;
        }
        nTotalMatchedCnt += nCnt;
    }
    
    float matchRate = ((float) nTotalMatchedCnt) / p_DetectData->m_nTotalValidCnt;
    
    if (matchRate >= fThreshold)
        return true;
    
    return false;
}

int CDetectMgr::GetMatchedCount(float* p_fVals, vector<AmpInfo>* p_lstDetectAmpInfos, float p_fThreshold, bool bMachineSound)
{
    int SEARCH_WIDTH = 3;
    int nGroupIdx = 0;
    int nPreviousIdx = 0;
    float fExtraSum = 0;
    int nExtraCnt = 0;
    unsigned long nSize = p_lstDetectAmpInfos->size();
    for (int i = 0; i < nSize; i++)
    {
        int nFFTIdx = p_lstDetectAmpInfos->at(i).nFFtIdx;
        if (nFFTIdx - nPreviousIdx > 5 || i == nSize - 1)
        {
            if (nPreviousIdx > 0)
            {
                for (int j = 0; j < SEARCH_WIDTH; j++)
                {
                    int idx = nPreviousIdx + 1 + j;
                    if (idx < maxIdx)
                    {
                        fExtraSum += p_fVals[idx];
                        nExtraCnt++;
                    }
                }
                m_fGroupAvgAmps[nGroupIdx - 1] = fExtraSum / nExtraCnt;
            }
            
            fExtraSum = 0;
            nExtraCnt = 0;
            for (int j = 0; j < SEARCH_WIDTH; j++)
            {
                int idx = nFFTIdx - SEARCH_WIDTH + j;
                fExtraSum += p_fVals[idx];
                nExtraCnt++;
            }
            
            nGroupIdx++;
        }
        nPreviousIdx = nFFTIdx;
    }
    
    nPreviousIdx = 0;
    nGroupIdx = 0;
    int nMatchedCnt = 0;
    int nGroupCnt = 0;
    int nGroupMatchedCnt = 0;
    for (int i = 0; i < nSize; i++)
    {
        int nFFTIdx = p_lstDetectAmpInfos->at(i).nFFtIdx;
        float fMainValue = p_fVals[nFFTIdx];
        
        if (nPreviousIdx > 0 && nFFTIdx - nPreviousIdx > 5) {
            float fThreshold = 1; // nGroupCnt;
            // if (nGroupCnt > 3)
            // fThreshold = nGroupCnt * 2.0f / 3;
            if (nGroupMatchedCnt < fThreshold && !bMachineSound)
                return -1;
            nGroupCnt = 0;
            nGroupMatchedCnt = 0;
            
            nGroupIdx++;
        }
        
        if (fMainValue > (m_fGroupAvgAmps[nGroupIdx] * RELATED_RATE)
            && fMainValue > p_fThreshold)
        {
            nMatchedCnt++;
            nGroupMatchedCnt++;
        }
        else
        {
            if (p_lstDetectAmpInfos->at(i).fAmpVal >= 0.9f)
                return -1;
        }
        
        nGroupCnt++;
        
        nPreviousIdx = nFFTIdx;
    }
    
    if (nGroupCnt > 0) {
        float fThreshold = (float)nGroupCnt;
        // if (nGroupCnt > 3)
        // fThreshold = nGroupCnt * 2.0f / 3;
        if (nGroupMatchedCnt < fThreshold && !bMachineSound)
            return -1;
    }
    
    return nMatchedCnt;
}

bool CDetectMgr::IsRecording()
{
    return (m_pFileRecording != nullptr) && m_bRecording;
}

bool CDetectMgr::IsRecordingOrPreparing()
{
    return m_pFileRecording != nullptr;
}

void CDetectMgr::Recording(float* pVals)
{
    if (!m_bRecording || m_pFileRecording == nullptr || pVals == nullptr)
        return;
    
    fprintf(m_pFileRecording, "%d", m_nRecordingFrames);
    for (int i = minIdx; i <= maxIdx; i++)
    {
        fprintf(m_pFileRecording, "\t%f", pVals[i]);
    }
    fprintf(m_pFileRecording, "\n");
}

bool CDetectMgr::Process(float* p_fData, int p_nFrameLen, int p_nFreqFrame, int p_nThreshold, float* p_fFreqs, float* p_fVals)
{
    p_fData[0] = 0;
    
    fft->forward(p_fData, p_nFrameLen);
    float* pVals = new float[maxIdx + 1];
    memset(pVals, 0x00, sizeof(float) * (maxIdx + 1));
    
    float fMaxVals[MAX_FREQ_CNT] = {0.0f};
    float fMaxFreqs[MAX_FREQ_CNT] = {0.0f};
    
    float val = 0.0f;
    float prevVal = 0.0f;
    float dist = 0.0f;
    float preDist = 0.0f;
    
    int idx = 0;
    
    if (m_pFreqIndicesToDraw == nullptr) {
        
        double freqStart = 20;
        double fFreqStep = pow(SAMPLE_FREQ / 2 / freqStart, 1.0 / (BAND_CNT - 1));
        double freq = freqStart;
        m_pFreqIndicesToDraw = new int[BAND_CNT];
        for (int i = 0; i < BAND_CNT; i++) {
            m_pFreqIndicesToDraw[i] = fft->freqToIndex((float)freq);
            freq = freq * fFreqStep;
        }
    }
    
    if (m_pRealValsToDraw == nullptr) {
        m_pRealValsToDraw = new float[BAND_CNT];
    }
    for (int i = 0; i < BAND_CNT; i++) {
        m_pRealValsToDraw[i] = (log10(fft->getBand(m_pFreqIndicesToDraw[i])) + 2) * 10;
        if (m_pRealValsToDraw[i] < 0)
            m_pRealValsToDraw[i] = 0;
    }
    
    for (int i = 0; i < MAX_FREQ_CNT; i++)
    {
        fMaxVals[i] = 0.0f;
        fMaxFreqs[i] = 0.0f;
    }
    
    for (int i = minIdx; i <= maxIdx; i++)
    {
        val = fft->getBand(i);
        
        pVals[i] = val;
        
        dist = val - prevVal;
        if (preDist > 0 && dist < 0)
        {
            if (prevVal > fDeltaThreshold)
            {
                idx = 0;
                for (; idx < MAX_FREQ_CNT; idx++)
                {
                    if (fMaxVals[idx] == 0 || prevVal > fMaxVals[idx])
                        break;
                }
                
                float fFreq = fft->indexToFreq(i - 1);
                if (idx < MAX_FREQ_CNT)
                {
                    for (int j = MAX_FREQ_CNT - 1; j > idx; j--)
                    {
                        if (fMaxVals[j-1] == 0)
                            continue;
                        fMaxVals[j] = fMaxVals[j-1];
                        fMaxFreqs[j] = fMaxFreqs[j-1];
                    }
                    fMaxVals[idx] = prevVal;
                    fMaxFreqs[idx] = fFreq;
                }
            }
        }
        
        preDist = dist;
        prevVal = val;
    }
    
    for (int i = 0; i < MAX_FREQ_CNT; i++)
    {
        if (i < p_nFreqFrame && fMaxVals[i] >= p_nThreshold) {
            p_fFreqs[i] = fMaxFreqs[i];
            p_fVals[i] = fMaxVals[i];
        } else {
            break;
        }
    }
    
    if (fMaxVals[0] < p_nThreshold && fMaxVals[0] > 0) {
        m_fMinAmpForSilent = m_fMinAmpForSilent == 0 ? fMaxVals[0] : min(m_fMinAmpForSilent, fMaxVals[0]);
        m_fMaxAmpForSilent = m_fMaxAmpForSilent == 0 ? fMaxVals[0] : max(m_fMinAmpForSilent, fMaxVals[0]);
    }
    
    val = log10f(fMaxVals[0]);
    
    m_vecFftVals.push_back(pVals);
    
    if (m_vecFftVals.size() > MAX_MATCH_FRAME_CNT)
    {
        float* pVals1 = m_vecFftVals.at(0);
        delete[] pVals1;
        m_vecFftVals.erase(m_vecFftVals.begin());
    }
    
    return true;
}

void CDetectMgr::initFreqVal(int cnt) {
    terminateFreqVal();
    
    for (int i = 0; i < MAX_FREQ_CNT; i++) {
        m_fMaxFreqs[i] = new float[cnt];
        m_fMaxVals[i] = new float[cnt];
        for (int j = 0; j < cnt; j++) {
            m_fMaxFreqs[i][j] = 0;
            m_fMaxVals[i][j] = 0;
        }
    }
}

void CDetectMgr::terminateFreqVal() {
    for (int i = 0; i < MAX_FREQ_CNT; i++) {
        if (m_fMaxFreqs[i] != nullptr) {
            delete [] m_fMaxFreqs[i];
            m_fMaxFreqs[i] = nullptr;
        }
        
        if (m_fMaxVals[i] != nullptr) {
            delete [] m_fMaxVals[i];
            m_fMaxVals[i] = nullptr;
        }
    }
}
