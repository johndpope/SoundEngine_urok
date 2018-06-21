#include "ProcessData.h"
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include "globals.h"


const float MIN_THRESHOLD_AMP_RATE = 0.06f;  
using namespace std;

CProcessData::CProcessData(void)
{
	m_listFreqVals = NULL;
	m_minIdx = 0;
	m_maxIdx = 0;

	m_fMaxAmp = 0;  // max amplitude in recorded data
	m_fMaxFreq = 0; // the frequency of max amplitude
	nMaxAmpIdx = 0;
}


CProcessData::~CProcessData(void)
{
	if (m_listFreqVals != nullptr) 
	{
		for (int i = 0; i < m_listFreqVals->size(); i++)
		{
			float* pVals = m_listFreqVals->at(i);
			delete[] pVals;
		}
		m_listFreqVals->clear();
		delete m_listFreqVals;
		m_listFreqVals = nullptr;
	}
}

bool CProcessData::ProcessFile(const char* p_strFilePath)
{
	std::string strLine;
	ifstream infile;
	infile.open(p_strFilePath);

	if (infile.eof())
		return false;

	m_minIdx = 0;
	m_maxIdx = 0;
	vector<float*>* listFreqVals = NULL;

	getline(infile, strLine);
	sscanf(strLine.c_str(), "%d\t%d", &m_minIdx, &m_maxIdx);
	if (m_minIdx == 0 || m_minIdx >= m_maxIdx)
		return false;

	std::string delimiter1 = "\t";
	std::string delimiter2 = "|";

	listFreqVals = new vector<float*>();
	int nValCntForLine = m_maxIdx - m_minIdx + 1;
    
    m_fMaxAmp = 0.0f;

	while(!infile.eof()) 
	{
		getline(infile, strLine);
        if (strLine.empty())
            break;
		float* pVals = new float[nValCntForLine];
		vector<string> arr = split(strLine, delimiter1);
		for (unsigned int i = 0; i < arr.size() - 1; i++)
		{
			pVals[i] = atof(arr[i + 1].c_str());
            
            if (m_fMaxAmp < pVals[i])
            {
                m_fMaxAmp = pVals[i];
                nMaxAmpIdx = i;
            }
		}
		listFreqVals->push_back(pVals);

	}

	infile.close();

	if (listFreqVals->size() == 0) {
		delete listFreqVals;
		return false;
	}

	float fThreshold = m_fMaxAmp * MIN_THRESHOLD_AMP_RATE;

	// remove front space moments
	vector<float*>::iterator iter = listFreqVals->begin();
	vector<float*>::iterator iterLast;
	while (iter != listFreqVals->end()) 
	{
		float* fVals = listFreqVals->at(0);
		if (fVals[nMaxAmpIdx] >= fThreshold) 
			break;

		listFreqVals->erase(iter);
        iter = listFreqVals->begin();
	}

	iter = listFreqVals->begin();
	// remove noises
	for (int i = 0; i < listFreqVals->size(); i++) {
		float* fVals = listFreqVals->at(i);

		for (int j = 0; j < nValCntForLine; j++) {
			if (fVals[j] < fThreshold)
				fVals[j] = 0;
			else
				fVals[j] = fVals[j] / m_fMaxAmp;
		}
	}

	// remove end space moments
	for (int i = (int)listFreqVals->size() - 1; i >= 0; i--) {
		float* fVals = listFreqVals->at(i);

		bool bLineRemovable = true;
		for (int j = 0; j < nValCntForLine; j++) {
			if (fVals[j] != 0) {
				bLineRemovable = false;
				break;
			}
		}

		if (bLineRemovable) {
			listFreqVals->pop_back();
		} else {
			break;
		}
	}

	if (listFreqVals->size() == 0)
    {
        
		delete listFreqVals;
		return false;
    }

    m_listFreqVals = listFreqVals;
	return true;
}