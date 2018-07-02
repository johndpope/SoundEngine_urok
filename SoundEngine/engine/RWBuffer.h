/** 
   
   Copyright (c) 2011 PSJDC.
   
   @file RWBuffer.h
   
   @date 2011-5-9
   
   @author LMC(mizilmc@hotmail.com) 
   
   @brief
   
    Read/Write Buffer
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
	  @breif Initialize buffer with its size
	*/
	bool Init( int p_nBufSize )
	{
		// if external buffer mode, fails.
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


	void GetCurPosition(int* p_readPos, int* p_writePos)
	{
		if(m_pSync) m_pSync->Enter();
		*p_readPos = m_nReadPos;
		*p_writePos = m_nWritePos;
		if(m_pSync) m_pSync->Leave();
	}

	/**
	  @breif Reset read and write position
	  All buffer will be writable.
	*/
	void Reset()
	{
		if(m_pSync) m_pSync->Enter();

		m_nReadPos = m_nWritePos = 0;

		if(m_pSync) m_pSync->Leave();
	}

	/**
	   Write data to the buffer.
   
	   @param p_pData - data to write,  if it is null, fill zero with count of bytes indicated as a parameter
	   @param p_nBytes - Count of bytes
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
				// enable to write whole data once
				if(p_pData)
					memcpy(m_pcBuffer + m_nWritePos, p_pData, p_nBytes);
				else
					memset(m_pcBuffer + m_nWritePos, 0, p_nBytes);
				m_nWritePos = (m_nWritePos + p_nBytes) % m_nBufSize;
			}
			else
			{
				// write some data to the end, and write remainted data from the start.
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
			// enable to write whole data once
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
	   Read data from the buffer
   
	   @param p_pData - data container to read buffer.
	   @param p_nBytes - count of bytes
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
			// enable to read whole data once
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
				// enable to read whole data once
				if(p_pData)
				{
					memcpy(p_pData, m_pcBuffer + m_nReadPos, p_nBytes);
				}
				m_nReadPos = (m_nReadPos + p_nBytes) % m_nBufSize;
			}
			else
			{
				// read some data to the end, and read remained data from the start
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
	   Get count of bytes which is writable
       When read position equals with write position, all buffer will be writable.
   
	   @return count of bytes to write
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
	   Get count of bytes which is readable
	   When read position equals with write position, return 0
   
	   @return count of bytes to read
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
