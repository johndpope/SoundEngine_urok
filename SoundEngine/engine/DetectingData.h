#pragma once

#include <vector>

struct AmpInfo
{
	int nFFtIdx;
	double fAmpVal;
};

class CProcessData;

class CDetectingData
{
public:
	CDetectingData(void);
	~CDetectingData(void);

	void Clear();
// Methods
public:
	bool LoadDetectData(const char* p_strFilePath);
	void GetPositionOfMax();

	void ResetProcessData();
	bool AddProcessData(const char* p_lpwzFile);
	bool ExtractDetectingData();
	void SaveDetectData(const char* p_lpwzFilePath);
    
    int GetRecordedCnt();
    
    void SetSoundType(int p_nType);
// Properties
public:
	std::vector<void*>* m_vecCommonData;
	int m_nTotalValidCnt;

	int m_nFrameIdxOfMax;
	int m_nFreqIdxOfMax;

	std::vector<CProcessData*> m_vecProcessData;
	int m_nMaxIdx;
	int m_nMinIdx;

	int m_nSoundType;
};

