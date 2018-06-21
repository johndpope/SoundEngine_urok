#include "globals.h"
#include "DetectingData.h"
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include "globals.h"
#include "DetectingData.h"
#include "ProcessData.h"

using namespace std;

CDetectingData::CDetectingData(void)
{
	m_vecCommonData = nullptr;
	m_nTotalValidCnt = 0;

	m_nFrameIdxOfMax = -1;
	m_nFreqIdxOfMax = -1;

	m_nSoundType = SOUND_GENERAL;
}


CDetectingData::~CDetectingData(void)
{
	Clear();
}


void CDetectingData::Clear()
{
	if (m_vecCommonData != nullptr) {
		for (unsigned int i = 0; i < m_vecCommonData->size(); i++) {
			vector<AmpInfo>* pinfo = (vector<AmpInfo>*)m_vecCommonData->at(i);
			pinfo->clear();
			delete pinfo;
		}

		m_vecCommonData->clear();
		delete m_vecCommonData;
		m_vecCommonData = nullptr;
	}
}

bool CDetectingData::LoadDetectData(const char* p_strFilePath)
{
	Clear();

	std::string strLine;
	ifstream infile;
	infile.open(p_strFilePath);

	if (infile.eof())
		return false;

	m_vecCommonData = new std::vector<void*>();

	int m_nMinidx, m_nMaxIdx;
	m_nMinidx = 0;
	m_nMaxIdx = 0;

	m_nTotalValidCnt = 0;

	getline(infile, strLine);
	sscanf(strLine.c_str(), "%d\t%d\t%d", &m_nMinidx, &m_nMaxIdx, &m_nSoundType);
	if (m_nMinidx == 0 || m_nMinidx >= m_nMaxIdx)
		return false;

	std::string delimiter1 = "\t";
	std::string delimiter2 = "|";
	while(!infile.eof()) {
		getline(infile, strLine);
		vector<AmpInfo>* ampInfos = new vector<AmpInfo>();
		vector<string> arr = split(strLine, delimiter1);
		for (unsigned int i = 1; i < arr.size(); i++)
		{
			vector<string> arr1 = split(arr[i], delimiter2);
			AmpInfo info;
			info.nFFtIdx = atoi(arr1[0].c_str());
            if (arr1.size() > 1) {
                info.fAmpVal = atof(arr1[1].c_str());
            }
            else {
                info.fAmpVal = 0;
            }
                
			
			ampInfos->push_back(info);
			m_nTotalValidCnt ++;
		}
		m_vecCommonData->push_back(ampInfos);

		if (m_vecCommonData->size() >= MAX_MATCH_FRAME_CNT)
			break;
	}

	infile.close();

	if (m_vecCommonData->size() == 0)
		return false;

	vector<void*>::iterator iter = m_vecCommonData->end();
	iter--;
	while(true) {
		vector<AmpInfo>* ampInfos = (vector<AmpInfo>*)*iter;
		if (ampInfos->size() > 0 || iter == m_vecCommonData->begin())
			break;
		
		delete ampInfos;
		vector<void*>::iterator iter1 = iter;
		iter--;
		m_vecCommonData->erase(iter1);
	}

	if (m_vecCommonData->size() == 0)
		return false;

	GetPositionOfMax();

	return true;
}

void CDetectingData::GetPositionOfMax()
{
	if (m_vecCommonData == NULL || m_vecCommonData->size() == 0)
		return;

	double fMax = 0;

	for (int i = 0; i < m_vecCommonData->size(); i++) 
	{
		vector<AmpInfo>* ampInfos = (vector<AmpInfo>*)m_vecCommonData->at(i);
		for (unsigned int j = 0; j < ampInfos->size(); j++)
		{
			AmpInfo ampInfo = ampInfos->at(j);
			if (ampInfo.fAmpVal > fMax) 
			{
				fMax = ampInfo.fAmpVal;
				m_nFrameIdxOfMax = i;
				m_nFreqIdxOfMax = ampInfo.nFFtIdx;
			}
		}
	}
}

void CDetectingData::ResetProcessData()
{
	Clear();
	
	for (int i = 0; i < m_vecProcessData.size(); i++)
	{
		CProcessData* processData = m_vecProcessData.at(i);
		delete processData;
	}
	m_vecProcessData.clear();
}

bool CDetectingData::AddProcessData(const char* p_lpwzFile)
{
	CProcessData* processData = new CProcessData();
	if (!processData->ProcessFile(p_lpwzFile))
		return false;
	m_vecProcessData.push_back(processData);
	return true;
}

bool CDetectingData::ExtractDetectingData()
{
	if (m_vecProcessData.size() < MAX_RECORD_TIMES)
		return false;

	m_nTotalValidCnt = 0;

	Clear();
	// check if all process data are valid
	int nFrameCnt = (int)m_vecProcessData[0]->m_listFreqVals->size();
	m_nMinIdx = m_vecProcessData[0]->m_minIdx;
	m_nMaxIdx = m_vecProcessData[0]->m_maxIdx;

	for (int i = 1; i < m_vecProcessData.size(); i++) {
		if (nFrameCnt > m_vecProcessData[i]->m_listFreqVals->size())
			nFrameCnt = (int)m_vecProcessData[i]->m_listFreqVals->size();

		if (m_nMinIdx != m_vecProcessData[i]->m_minIdx)
			return false;

		if (m_nMaxIdx != m_vecProcessData[i]->m_maxIdx)
			return false;			
	}

	m_vecCommonData = new std::vector<void*>();

	int nFreqCnt = m_nMaxIdx - m_nMinIdx + 1;
	float fVal = 0;
	int nValidCnt = 0;
	float fSum = 0;

	for (int nPos = 0; nPos < nFrameCnt; nPos++) {
		vector<AmpInfo>* ampInfos = new vector<AmpInfo>();
		for (int i = 0; i < nFreqCnt; i++) {
			fSum = 0; 
			nValidCnt = 0;
			for (int idx = 0; idx < m_vecProcessData.size(); idx++) {
				fVal = m_vecProcessData[idx]->m_listFreqVals->at(nPos)[i];
				if (fVal > 0) {
					fSum += fVal;
					nValidCnt++;
				}
			}

			if (nValidCnt > 0 && nValidCnt >= m_vecProcessData.size() * 2 / 3) {
				fSum = fSum / nValidCnt;
				AmpInfo ampInfo;
				ampInfo.fAmpVal = fSum;
				ampInfo.nFFtIdx = i + m_nMinIdx;
				ampInfos->push_back(ampInfo);
			}
		}
		m_vecCommonData->push_back(ampInfos);
	}

	// remove front space moments
	while(m_vecCommonData->size() > 0) {
		vector<AmpInfo>* ampInfos = (vector<AmpInfo>*)m_vecCommonData->at(0);
		if (ampInfos->size() > 0)
			break;

		delete ampInfos;
		m_vecCommonData->erase(m_vecCommonData->begin());
	}

	// remove back space moments
	while (m_vecCommonData->size() > 0) {
		vector<AmpInfo>* ampInfos = (vector<AmpInfo>*)m_vecCommonData->at(m_vecCommonData->size() - 1);
		if (ampInfos->size() > 0 && m_vecCommonData->size() < MAX_MATCH_FRAME_CNT)
			break;

		delete ampInfos;
		m_vecCommonData->pop_back();
	}

	if (m_vecCommonData->size() == 0) {
		delete m_vecCommonData;
		m_vecCommonData = nullptr;
		return false;
	}

    int nMaxFrameCnt = -1;
    if (g_recordSoundType == RST_Intercom) {
        nMaxFrameCnt = MAX_INTERCOM_FRAME_CNT;
    } else if (g_recordSoundType == RST_Linephone) {
        nMaxFrameCnt = MAX_TELEPHONE_FRAME_CNT;
    } else if (g_recordSoundType == RST_SmokeAlarm) {
        nMaxFrameCnt = MAX_SMOKE_FRAME_CNT;
    } else if (m_nSoundType == DT_MetalBell
               || m_nSoundType == DT_Buzzer) {
        nMaxFrameCnt = MAX_METABELL_FRAME_CNT;
    }
    
	// if soundtype is meta-bell or buzzer, then we just need about 1.5 secs.
	if (nMaxFrameCnt > 0) {
		while (m_vecCommonData->size() > nMaxFrameCnt) {
			vector<AmpInfo>* ampInfos = (vector<AmpInfo>*)m_vecCommonData->at(m_vecCommonData->size() - 1);
			delete ampInfos;
			m_vecCommonData->pop_back();
		}
	}

	for (int i = 0; i < m_vecCommonData->size(); i++) {
		vector<AmpInfo>* ampInfos = (vector<AmpInfo>*)m_vecCommonData->at(i);
		m_nTotalValidCnt += ampInfos->size();
	}

	GetPositionOfMax();
    return true;
}

void CDetectingData::SaveDetectData(const char* p_lpszFilePath)
{
	FILE* fp = fopen(p_lpszFilePath, "wb");
	if (fp == nullptr)
		return;

	fprintf(fp, "%d\t%d\t%d\n", m_nMinIdx, m_nMaxIdx, m_nSoundType);

	for (int i = 0; i < m_vecCommonData->size(); i++) {
		vector<AmpInfo>* ampInfos = (vector<AmpInfo>*)m_vecCommonData->at(i);
		fprintf(fp, "%d", i);
		for (int j = 0; j < ampInfos->size(); j++) {
			fprintf(fp, "\t%d|%f", ampInfos->at(j).nFFtIdx, ampInfos->at(j).fAmpVal);
		}
		fprintf(fp, "\n");
	}
	fclose(fp);
}

int CDetectingData::GetRecordedCnt()
{
    return (int)m_vecProcessData.size();
}

void CDetectingData::SetSoundType(int p_nType)
{
    m_nSoundType = p_nType;
}
