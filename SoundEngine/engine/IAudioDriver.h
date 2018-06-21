/*
 * IAudioDriver.h
 *
 * Copyright (c) PSJDC 2012
 *
 * 07/03/2012 RJR
 * 09/18/2012 modified by lhs
 * 10/31/2012 modified by lhs. Add AudioParameterInfo.micOn
 *
 * 오디오 드라이버 인터페이스
 *
 */
#pragma once

enum {
    kAudioListnerTypeInterruption = 0
    , kAudioListnerTypeProperty
};

typedef int (*AudioCallback)(const void* inData, void* outData, unsigned long numSamples);
typedef int (*AudioListner)(int type, unsigned long data1, unsigned long data2, const void* data3);

struct AudioParameterInfo {
	int channel;
	int sampleRate;
	int samplesPerFrame;
    int micOn;
    AudioListner listner;
	int numPacket;
};

class IAudioDriver {
public:
	virtual ~IAudioDriver() {}
    
	virtual int  open(const AudioParameterInfo* paramInfo, AudioCallback callback) = 0;
	virtual void close() = 0;
	virtual bool isOpened() = 0;
};
