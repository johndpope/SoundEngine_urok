/** 
   
   Copyright (c) 2011 PSJDC.
   
   @file RWBuffer.h
   
   @date 2011-5-9
   
   @author LMC(mizilmc@hotmail.com) 
   
   @brief
   
    읽기쓰기 완충기
*/

#pragma once
#include "ulib_criticalsection.h"

class RWBuffer
{
public:
	RWBuffer(void)
	{
		m_pcBuffer = NULL;
		m_pfBuffer = NULL;

		m_nBufSize = 0;
		m_nWritePos = m_nReadPos = 0;
		m_pSync = &m_Sysn;
		m_externalMode = false;
	}

	~RWBuffer(void)
	{
		if(m_externalMode == false && m_pcBuffer)
		{
			delete m_pcBuffer;
		}
		m_pcBuffer = NULL;
		m_pfBuffer = NULL;
	}

	/**
	  @breif 완충기 바이트수를 지정하여 초기화
	*/
	bool Init( int p_nBufSize )
	{
		// 외부완충기를 리용하는 방식으로 이미 초기화된 경우에는 실패
		if(m_externalMode == true)
			return false;

		if(m_pSync) m_pSync->Enter();

		if (m_pcBuffer)
		{
			delete m_pcBuffer;
		}
		m_pcBuffer = new char[p_nBufSize];
		m_pfBuffer = (float*)m_pcBuffer;
		m_nBufSize = p_nBufSize;
		m_nReadPos = m_nWritePos = 0;

		if(m_pSync) m_pSync->Leave();

		return true;
	}

	/**
	  @breif 외부에서 정보를 모두 지정하여 초기화
	  외부에서 완충기를 지적하여 링버퍼를 구현할때 사용할수 있다.
	  주의: 이 함수를 사용하여 초기화한후에 완충기 크기만을 지정하여 
	  초기화하는 함수를 호출하면 실패한다.
	*/
	bool Init( char* p_buf, int p_bufSize, int p_readPos, int p_writePos )
	{
		m_pcBuffer = p_buf;
		m_pfBuffer = (float*)m_pcBuffer;
		m_nBufSize = p_bufSize;
		m_nReadPos = p_readPos;
		m_nWritePos = p_writePos;
		m_pSync = nullptr;

		m_externalMode = true;
		return false;
	}
	void GetCurPosition(int* p_readPos, int* p_writePos)
	{
		if(m_pSync) m_pSync->Enter();
		*p_readPos = m_nReadPos;
		*p_writePos = m_nWritePos;
		if(m_pSync) m_pSync->Leave();
	}

	/**
	  @breif 읽기 위치와 쓰기 위치의 초기화
	  전공간이 쓰기 가능한 공간으로되며 읽기공간은 0으로 된다.
	*/
	void Reset()
	{
		if(m_pSync) m_pSync->Enter();

		m_nReadPos = m_nWritePos = 0;

		if(m_pSync) m_pSync->Leave();
	}

	/**
	   완충기에 자료를 쓴다.
   
	   @param p_pData - 쓰려는 자료. NULL이면 지적한 바이트수만큼 0을 쓴다.
	   @param p_nBytes - 쓰려는 자료바이트수
	   @return true/false
	   @warning 
	*/
	bool WriteData( void* p_pData, int p_nBytes )
	{
		if(GetWriteSpace() < p_nBytes)
		{
			return false;
		}

		if(m_pSync) m_pSync->Enter();

		if (true || m_nWritePos >= m_nReadPos)
		{
			int nRemain = m_nBufSize - m_nWritePos;
			if(nRemain >= p_nBytes)
			{
				// 현재 쓰기 위치로부터 완충기의 끝까지 령역이 충분하다.
				if(p_pData)
					memcpy(m_pcBuffer + m_nWritePos, p_pData, p_nBytes);
				else
					memset(m_pcBuffer + m_nWritePos, 0, p_nBytes);
				m_nWritePos = (m_nWritePos + p_nBytes) % m_nBufSize;
			}
			else
			{
				// 완충기의 마지막까지 쓰고 시작부분에 더 써야 하는 상태
				if(p_pData)
					memcpy(m_pcBuffer + m_nWritePos, p_pData, nRemain);
				else
					memset(m_pcBuffer + m_nWritePos, 0, nRemain);

				p_nBytes -= nRemain;

				if(p_pData)
					memcpy(m_pcBuffer, (unsigned char*)p_pData+nRemain, p_nBytes);
				else
					memset(m_pcBuffer, 0, p_nBytes);

				m_nWritePos = p_nBytes;
			}
		}
		else
		{
			// 현재 쓰기 위치로부터 읽기 위치 전까지 령역이 충분하다.
			if(p_pData)
				memcpy(m_pcBuffer + m_nWritePos, p_pData, p_nBytes);
			else
				memset(m_pcBuffer + m_nWritePos, 0, p_nBytes);
			m_nWritePos += p_nBytes;
		}

		if(m_pSync) m_pSync->Leave();

		return true;
	}

	/**
	   완충기에서 자료를 읽는다.
   
	   @param p_pData - 자료를 읽어낼 완충기.
	   @param p_nBytes - 읽으려는 자료바이트수
	   @return true/false
	   @warning 
	*/
	bool ReadData( void* p_pData, int p_nBytes )
	{
		if(GetReadSpace() < p_nBytes)
		{
			return false;
		}

		if(m_pSync) m_pSync->Enter();

		if (false && m_nWritePos >= m_nReadPos)
		{
			// 현재 읽기 위치로부터 쓰기위치 전까지 령역이 충분하다.
			if(p_pData)
			{
				memcpy(p_pData, m_pcBuffer + m_nReadPos, p_nBytes);
			}
			m_nReadPos += p_nBytes;
		}
		else
		{
			int nRemain = m_nBufSize - m_nReadPos;
			if(nRemain >= p_nBytes)
			{
				// 현재 쓰기 위치로부터 완충기의 끝까지 령역이 충분하다.
				if(p_pData)
				{
					memcpy(p_pData, m_pcBuffer + m_nReadPos, p_nBytes);
				}
				m_nReadPos = (m_nReadPos + p_nBytes) % m_nBufSize;
			}
			else
			{
				// 완충기의 마지막까지 읽고 시작부분에서 더 읽어야 하는 상태
				if(p_pData)
				{
					memcpy(p_pData, m_pcBuffer + m_nReadPos, nRemain);
				}
				p_nBytes -= nRemain;

				if(p_pData)
				{
					memcpy((unsigned char*)p_pData + nRemain, m_pcBuffer, p_nBytes); // 2011.11.21 수정! zc
				}
				m_nReadPos = p_nBytes;
			}
		}

		if(m_pSync) m_pSync->Leave();

		return true;
	}

	/**
	   쓰기 가능한 빈 공간의 바이트수를 얻는다.
	   읽기 위치와 쓰기위치가 동일한 경우 완충기크기 만큼이 쓸수 있는 공간으로 된다.
   
	   @return 쓰기 가능한 빈 공간의 바이트수
	   @warning 
	*/
	int GetWriteSpace()
	{
		int nSize;
		if(m_pSync) m_pSync->Enter();

		if (m_nWritePos >= m_nReadPos)
		{
			nSize = m_nBufSize - m_nWritePos + m_nReadPos;
		}
		else
		{
			nSize = m_nReadPos - m_nWritePos;
		}

		if(m_pSync) m_pSync->Leave();

		return nSize;
	}

	/**
	   읽기 가능한 자료의 바이트수를 얻는다.
	   읽기 위치와 쓰기위치가 동일한 경우 0을 귀환
   
	   @return 읽기 가능한 자료의 바이트수
	   @warning 
	*/
	int GetReadSpace()
	{
		return m_nBufSize - GetWriteSpace();
	}
	int getNumSamples()
	{
		return GetBufSize()/sizeof(float);
	}
	float* getSampleData(int, int)
	{
		return m_pfBuffer;
	}

	int GetBufSize(){ return m_nBufSize; }

	void EmptyBack(int p_nBytes)
	{
		if(GetReadSpace() > p_nBytes)
		{
			if(m_pSync) m_pSync->Enter();

			m_nWritePos -= p_nBytes;
			if (m_nWritePos < 0)
			{
				m_nWritePos += m_nBufSize;
			}

			if(m_pSync) m_pSync->Leave();
		}
		else
		{
			Reset();
		}
	}

private:

	int		m_nReadPos;
	int		m_nWritePos;

	char*	m_pcBuffer;
	float*	m_pfBuffer;
	int		m_nBufSize;

	bool	m_externalMode;

	Sync::CriticalSection	m_Sysn;
	Sync::CriticalSection*	m_pSync;
};
