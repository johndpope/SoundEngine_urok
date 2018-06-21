#pragma once

#include <vector>

class CProcessData
{
public:
	CProcessData(void);
	~CProcessData(void);

	bool ProcessFile(const char* p_strFilePath);

public:
	std::vector<float*>* m_listFreqVals;
	int m_minIdx;
	int m_maxIdx;

	float m_fMaxAmp;  // max amplitude in recorded data
	float m_fMaxFreq; // the frequency of max amplitude
	int nMaxAmpIdx;

};

