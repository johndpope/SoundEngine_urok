#include "FourierTransform.h"
#include <math.h>
#include<string.h>
/**
 * Construct a FourierTransform that will analyze sample buffers that are
 * <code>ts</code> samples long and contain samples with a <code>sr</code>
 * sample rate.
 * 
 * @param ts
 *          the length of the buffers that will be analyzed
 * @param sr
 *          the sample rate of the samples that will be analyzed
 */
FourierTransform::FourierTransform(int ts, float sr)
{
	_timeSize = 0;
	sampleRate = 0;
	bandWidth = 0;
	real = NULL;
	imag = NULL;
	spectrum = NULL;
	averages = NULL;
	real_len = 0;
	imag_len = 0;
	spectrum_len = 0;
	averages_len = 0;

	whichAverage = 0;
	octaves = 0;
	avgPerOctave = 0;

	_timeSize = ts;
	sampleRate = (int)sr;
	bandWidth = (2.f / _timeSize) * ((float)sampleRate / 2.f);
}


FourierTransform::~FourierTransform(void)
{
	if (real != NULL)
		delete[] real;
	if (imag != NULL)
		delete[] imag;
	if (spectrum != NULL)
		delete[] spectrum;
	if (averages != NULL)
		delete[] averages;
}


void FourierTransform::init()
{
	noAverages();
	allocateArrays();
}


void FourierTransform::setComplex(float* r, int r_len, float* i, int i_len)
{
	if (real_len != r_len && imag_len != i_len)
	{
	}
	else
	{
		memcpy(real, r, r_len);
		memcpy(imag, i, i_len);
	}
}

// fill the spectrum array with the amps of the data in real and imag
// used so that this class can handle creating the average array
// and also do spectrum shaping if necessary
void FourierTransform::fillSpectrum()
{
	for (int i = 0; i < spectrum_len; i++)
	{
		spectrum[i] = (float) sqrt(real[i] * real[i] + imag[i] * imag[i]);
	}

	if (whichAverage == LINAVG)
	{
		int avgWidth = (int) spectrum_len / averages_len;
		for (int i = 0; i < averages_len; i++)
		{
			float avg = 0;
			int j;
			for (j = 0; j < avgWidth; j++)
			{
				int offset = j + i * avgWidth;
				if (offset < spectrum_len)
				{
					avg += spectrum[offset];
				}
				else
				{
					break;
				}
			}
			avg /= j + 1;
			averages[i] = avg;
		}
	}
	else if (whichAverage == LOGAVG)
	{
		for (int i = 0; i < octaves; i++)
		{
			float lowFreq, hiFreq, freqStep;
			if (i == 0)
			{
				lowFreq = 0;
			}
			else
			{
				lowFreq = (sampleRate / 2) / pow(2.f, octaves - i);
			}
			hiFreq = (sampleRate / 2) / pow(2.f, octaves - i - 1);
			freqStep = (hiFreq - lowFreq) / avgPerOctave;
			float f = lowFreq;
			for (int j = 0; j < avgPerOctave; j++)
			{
				int offset = j + i * avgPerOctave;
				averages[offset] = calcAvg(f, f + freqStep);
				f += freqStep;
			}
		}
	}
}

/**
 * Sets the object to not compute averages.
 * 
 */
void FourierTransform::noAverages()
{
	averages = NULL;
	averages_len = 0;
	whichAverage = NOAVG;
}

/**
 * Sets the number of averages used when computing the spectrum and spaces the
 * averages in a linear manner. In other words, each average band will be
 * <code>specSize() / numAvg</code> bands wide.
 * 
 * @param numAvg
 *          how many averages to compute
 */
void FourierTransform::linAverages(int numAvg)
{
	if (numAvg > spectrum_len / 2)
	{
		return;
	}
	else
	{
		averages = new float[numAvg];
		averages_len = numAvg;
	}
	whichAverage = LINAVG;
}

/**
 * Sets the number of averages used when computing the spectrum based on the
 * minimum bandwidth for an octave and the number of bands per octave. For
 * example, with audio that has a sample rate of 44100 Hz,
 * <code>logAverages(11, 1)</code> will result in 12 averages, each
 * corresponding to an octave, the first spanning 0 to 11 Hz. To ensure that
 * each octave band is a full octave, the number of octaves is computed by
 * dividing the Nyquist frequency by two, and then the result of that by two,
 * and so on. This means that the actual bandwidth of the lowest octave may
 * not be exactly the value specified.
 * 
 * @param minBandwidth
 *          the minimum bandwidth used for an octave
 * @param bandsPerOctave
 *          how many bands to split each octave into
 */
void FourierTransform::logAverages(int minBandwidth, int bandsPerOctave)
{
	float nyq = (float) sampleRate / 2.f;
	octaves = 1;
	while ((nyq /= 2) > minBandwidth)
	{
		octaves++;
	}
	avgPerOctave = bandsPerOctave;
	averages = new float[octaves * bandsPerOctave];
	averages_len = octaves * bandsPerOctave;
	whichAverage = LOGAVG;
}

/**
 * Returns the length of the time domain signal expected by this transform.
 * 
 * @return the length of the time domain signal expected by this transform
 */
int FourierTransform::timeSize()
{
	return _timeSize;
}

/**
 * Returns the size of the spectrum created by this transform. In other words,
 * the number of frequency bands produced by this transform. This is typically
 * equal to <code>timeSize()/2 + 1</code>, see above for an explanation.
 * 
 * @return the size of the spectrum
 */
int FourierTransform::specSize()
{
	return spectrum_len;
}

/**
 * Returns the amplitude of the requested frequency band.
 * 
 * @param i
 *          the index of a frequency band
 * @return the amplitude of the requested frequency band
*/
float FourierTransform::getBand(int i)
{
	if (i < 0) i = 0;
	if (i > spectrum_len - 1) i = spectrum_len - 1;
	return spectrum[i];
}

/**
 * Returns the width of each frequency band in the spectrum (in Hz). It should
 * be noted that the bandwidth of the first and last frequency bands is half
 * as large as the value returned by this function.
 * 
 * @return the width of each frequency band in Hz.
 */
float FourierTransform::getBandWidth()
{
	return bandWidth;
}

/**
 * Returns the bandwidth of the requested average band. Using this information 
 * and the return value of getAverageCenterFrequency you can determine the 
 * lower and upper frequency of any average band.
 * 
 * @see #getAverageCenterFrequency(int)
 * @related getAverageCenterFrequency ( )
 */
float FourierTransform::getAverageBandWidth(int averageIndex)
{
	if ( whichAverage == LINAVG )
	{
		// an average represents a certain number of bands in the spectrum
		int avgWidth = (int) spectrum_len / averages_len;
		return avgWidth * getBandWidth();
	}
	else if ( whichAverage == LOGAVG )
	{
		// which "octave" is this index in?
		int octave = averageIndex / avgPerOctave;
		float lowFreq, hiFreq, freqStep;
		// figure out the low frequency for this octave
		if (octave == 0)
		{
			lowFreq = 0;
		}
		else
		{
			lowFreq = (sampleRate / 2) / (float) pow(2.f, octaves - octave);
		}
		// and the high frequency for this octave
		hiFreq = (sampleRate / 2) / (float) pow(2.f, octaves - octave - 1);
		// each average band within the octave will be this big
		freqStep = (hiFreq - lowFreq) / avgPerOctave;

		return freqStep;
	}

	return 0;
}

/**
 * Returns the index of the frequency band that contains the requested
 * frequency.
 * 
 * @param freq
 *          the frequency you want the index for (in Hz)
 * @return the index of the frequency band that contains freq
 */
int FourierTransform::freqToIndex(float freq)
{
	// special case: freq is lower than the bandwidth of spectrum[0]
	if (freq < getBandWidth() / 2) return 0;
	// special case: freq is within the bandwidth of spectrum[spectrum_len - 1]
	if (freq > sampleRate / 2 - getBandWidth() / 2) return spectrum_len - 1;
	// all other cases
	float fraction = freq / (float) sampleRate;
	int i = (int)(_timeSize * fraction + 0.5);
	return i;
}

/**
 * Returns the middle frequency of the i<sup>th</sup> band.
 * @param i
 *        the index of the band you want to middle frequency of
 */
float FourierTransform::indexToFreq(int i)
{
	float bw = getBandWidth();
	// special case: the width of the first bin is half that of the others.
	//               so the center frequency is a quarter of the way.
	if ( i == 0 ) return bw * 0.25f;
	// special case: the width of the last bin is half that of the others.
	if ( i == spectrum_len - 1 ) 
	{
		float lastBinBeginFreq = (sampleRate / 2) - (bw / 2);
		float binHalfWidth = bw * 0.25f;
		return lastBinBeginFreq + binHalfWidth;
	}
	// the center frequency of the ith band is simply i*bw
	// because the first band is half the width of all others.
	// treating it as if it wasn't offsets us to the middle 
	// of the band.
	return i*bw;
}

/**
 * Returns the center frequency of the i<sup>th</sup> average band.
 * 
 * @param i
 *     which average band you want the center frequency of.
 */
float FourierTransform::getAverageCenterFrequency(int i)
{
	if ( whichAverage == LINAVG )
	{
		// an average represents a certain number of bands in the spectrum
		int avgWidth = (int) spectrum_len / averages_len;
		// the "center" bin of the average, this is fudgy.
		int centerBinIndex = i*avgWidth + avgWidth/2;
		return indexToFreq(centerBinIndex);

	}
	else if ( whichAverage == LOGAVG )
	{
		// which "octave" is this index in?
		int octave = i / avgPerOctave;
		// which band within that octave is this?
		int offset = i % avgPerOctave;
		float lowFreq, hiFreq, freqStep;
		// figure out the low frequency for this octave
		if (octave == 0)
		{
			lowFreq = 0;
		}
		else
		{
			lowFreq = (sampleRate / 2) / (float) pow(2.f, octaves - octave);
		}
		// and the high frequency for this octave
		hiFreq = (sampleRate / 2) / (float) pow(2.f, octaves - octave - 1);
		// each average band within the octave will be this big
		freqStep = (hiFreq - lowFreq) / avgPerOctave;
		// figure out the low frequency of the band we care about
		float f = lowFreq + offset*freqStep;
		// the center of the band will be the low plus half the width
		return f + freqStep/2;
	}

	return 0;
}

/**
 * Gets the amplitude of the requested frequency in the spectrum.
 * 
 * @param freq
 *          the frequency in Hz
 * @return the amplitude of the frequency in the spectrum
 */
float FourierTransform::getFreq(float freq)
{
	return getBand(freqToIndex(freq));
}

/**
 * Sets the amplitude of the requested frequency in the spectrum to
 * <code>a</code>.
 * 
 * @param freq
 *          the frequency in Hz
 * @param a
 *          the new amplitude
 */
void FourierTransform::setFreq(float freq, float a)
{
	setBand(freqToIndex(freq), a);
}

/**
 * Scales the amplitude of the requested frequency by <code>a</code>.
 * 
 * @param freq
 *          the frequency in Hz
 * @param s
 *          the scaling factor
 */
void FourierTransform::scaleFreq(float freq, float s)
{
	scaleBand(freqToIndex(freq), s);
}

/**
 * Returns the number of averages currently being calculated.
 * 
 * @return the length of the averages array
 */
int FourierTransform::avgSize()
{
	return averages_len;
}

/**
 * Gets the value of the <code>i<sup>th</sup></code> average.
 * 
 * @param i
 *          the average you want the value of
 * @return the value of the requested average band
 */
float FourierTransform::getAvg(int i)
{
	float ret;
	if (averages_len > 0)
		ret = averages[i];
	else
		ret = 0;
	return ret;
}

/**
 * Calculate the average amplitude of the frequency band bounded by
 * <code>lowFreq</code> and <code>hiFreq</code>, inclusive.
 * 
 * @param lowFreq
 *          the lower bound of the band
 * @param hiFreq
 *          the upper bound of the band
 * @return the average of all spectrum values within the bounds
 */
float FourierTransform::calcAvg(float lowFreq, float hiFreq)
{
	int lowBound = freqToIndex(lowFreq);
	int hiBound = freqToIndex(hiFreq);
	float avg = 0;
	for (int i = lowBound; i <= hiBound; i++)
	{
		avg += spectrum[i];
	}
	avg /= (hiBound - lowBound + 1);
	return avg;
}

/**
 * Get the Real part of the Complex representation of the spectrum.
 */
float* FourierTransform::getSpectrumReal(int &nLen)
{
	nLen = real_len;
	return real;
}

/**
 * Get the Imaginary part of the Complex representation of the spectrum.
 */
float* FourierTransform::getSpectrumImaginary(int &nLen)
{
	nLen = imag_len;
	return imag;
}

/**
 * Performs a forward transform on values in <code>buffer</code>.
 * 
 * @param buffer
 *          the buffer of samples
 * @param startAt
 *          the index to start at in the buffer. there must be at least timeSize() samples
 *          between the starting index and the end of the buffer. If there aren't, an
 *          error will be issued and the operation will not be performed.
 *          
 */
void FourierTransform::forward(float* buffer, int buffer_len, int startAt)
{
	if ( buffer_len - startAt < _timeSize )
	{
		return;
	}

	// copy the section of samples we want to analyze
	float* section = new float[_timeSize];
	int section_len = _timeSize;
	memcpy(section, buffer + startAt, section_len);
	forward(section, section_len);
}

void FourierTransform::inverse(float* freqReal, int freqReal_len, float* freqImag, int freqImag_len, float* buffer, int buffer_len)
{
	setComplex(freqReal, freqReal_len, freqImag, freqImag_len);
	inverse(buffer, buffer_len);
}

