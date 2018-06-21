#pragma once

#define LINAVG 1
#define LOGAVG  2
#define NOAVG  3
#define TWO_PI (2*3.1415926535f)
#define PI (3.1415926535f)

class FourierTransform
{
public:
	FourierTransform(int ts, float sr);
	~FourierTransform(void);

	virtual void init();

protected:
	void setComplex(float* r, int r_len, float* i, int i_len);

	void fillSpectrum();

public:
	void noAverages();

	void linAverages(int numAvg);

	void logAverages(int minBandwidth, int bandsPerOctave);

	int timeSize();

	int specSize();

	float getBand(int i);

	float getBandWidth();

	float getAverageBandWidth( int averageIndex );

	int freqToIndex(float freq);

	float indexToFreq(int i);

	float getAverageCenterFrequency(int i);

	float getFreq(float freq);

	void setFreq(float freq, float a);

	void scaleFreq(float freq, float s);

	int avgSize();

	float getAvg(int i);

	float calcAvg(float lowFreq, float hiFreq);

	float* getSpectrumReal(int &nLen);

	float* getSpectrumImaginary(int &nLen);

	void forward(float* buffer, int buffer_len, int startAt);

	void inverse(float* freqReal, int freqReal_len, float* freqImag, int freqImag_len, float* buffer, int buffer_len);

	// allocating real, imag, and spectrum are the responsibility of derived
	// classes because the size of the arrays will depend on the implementation being used
	// this enforces that responsibility
	virtual void allocateArrays() = 0;

	/**
	 * Sets the amplitude of the <code>i<sup>th</sup></code> frequency band to
	 * <code>a</code>. You can use this to shape the spectrum before using
	 * <code>inverse()</code>.
	 * 
	 * @param i
	 *          the frequency band to modify
	 * @param a
	 *          the new amplitude
 	 */
	virtual void setBand(int i, float a) = 0;

	/**
	 * Scales the amplitude of the <code>i<sup>th</sup></code> frequency band
	 * by <code>s</code>. You can use this to shape the spectrum before using
	 * <code>inverse()</code>.
	 * 
	 * @param i
	 *          the frequency band to modify
	 * @param s
	 *          the scaling factor
	 */
	virtual void scaleBand(int i, float s) = 0;

	/**
	 * Performs a forward transform on <code>buffer</code>.
	 * 
	 * @param buffer
	 *          the buffer to analyze
 	 */
	virtual void forward(float* buffer, int buffer_len) = 0;

	/**
	 * Performs an inverse transform of the frequency spectrum and places the
	 * result in <code>buffer</code>.
	 * 
	 * @param buffer
	 *          the buffer to place the result of the inverse transform in
	 */
	virtual void inverse(float* buffer, int buffer_len) = 0;

protected:
	int _timeSize;
	int sampleRate;
	float bandWidth;
	float* real;
	int real_len;
	float* imag;
	int imag_len;
	float* spectrum;
	int spectrum_len;
	float* averages;
	int averages_len;
	int whichAverage;
	int octaves;
	int avgPerOctave;
};

