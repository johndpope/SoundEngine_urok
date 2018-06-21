#pragma once
#import "FourierTransform.h"
//#import "BraciPro-Swift.h"
//#import "AppDelegate.h"


class FFT :
	public FourierTransform
{
public:
	FFT(int timeSize, float sampleRate);
	virtual ~FFT(void);

	virtual void init();

	virtual void allocateArrays();
	virtual void scaleBand(int i, float s);
	virtual void setBand(int i, float a);

	void forward(float* buffer, int buffer_len);
	virtual void forward(float* buffer, int buffer_len, int startAt);
	void forward(float* buffReal, int buffReal_len, float* buffImag, int buffImag_len);
	virtual void inverse(float* buffer, int buffer_len);

private:
	void fft();
	void buildReverseTable();
	void bitReverseSamples(float* samples, int samples_len, int startAt);
	void bitReverseComplex();

	float Sin(int i);
	float Cos(int i);
	void buildTrigTables();

private:
	int* reverse;
	int reverse_len;

	float* sinlookup;
	int sinlookup_len;
	float* coslookup;
	int coslookup_len;
};

