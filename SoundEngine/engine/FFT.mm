#include "FFT.h"
#include <math.h>
#include <string.h>
#include <new>
/**
 * Constructs an FFT that will accept sample buffers that are
 * <code>timeSize</code> long and have been recorded with a sample rate of
 * <code>sampleRate</code>. <code>timeSize</code> <em>must</em> be a
 * power of two. This will throw an exception if it is not.
 *
 * @param timeSize
 *          the length of the sample buffers you will be analyzing
 * @param sampleRate
 *          the sample rate of the audio you will be analyzing
 */
FFT::FFT(int timeSize, float sampleRate)
: FourierTransform(timeSize, sampleRate)
{
    if ((_timeSize & (_timeSize - 1)) != 0)
        throw new std::new_handler(); // "FFT: timeSize must be a power of two.";
    
    reverse = NULL;
    reverse_len = 0;
    
    sinlookup = NULL;
    sinlookup_len = 0;
    coslookup = NULL;
    coslookup_len = 0;
}

FFT::~FFT(void)
{
    if (sinlookup != NULL)
        delete[] sinlookup;
    if (coslookup != NULL)
        delete[] coslookup;
}


void FFT::init()
{
    FourierTransform::init();
    
    buildReverseTable();
    buildTrigTables();
}


void FFT::allocateArrays()
{
    spectrum_len = _timeSize / 2 + 1;
    spectrum = new float[spectrum_len];
    real_len = _timeSize;
    real = new float[real_len];
    imag_len = _timeSize;
    imag = new float[imag_len];
}

void FFT::scaleBand(int i, float s)
{
    if (s < 0)
    {
        // Minim.error("Can't scale a frequency band by a negative value.");
        return;
    }
    
    real[i] *= s;
    imag[i] *= s;
    spectrum[i] *= s;
    
    if (i != 0 && i != _timeSize / 2)
    {
        real[_timeSize - i] = real[i];
        imag[_timeSize - i] = -imag[i];
    }
}

void FFT::setBand(int i, float a)
{
    if (a < 0)
    {
        // Minim.error("Can't set a frequency band to a negative value.");
        return;
    }
    if (real[i] == 0 && imag[i] == 0)
    {
        real[i] = a;
        spectrum[i] = a;
    }
    else
    {
        real[i] /= spectrum[i];
        imag[i] /= spectrum[i];
        spectrum[i] = a;
        real[i] *= spectrum[i];
        imag[i] *= spectrum[i];
    }
    if (i != 0 && i != _timeSize / 2)
    {
        real[_timeSize - i] = real[i];
        imag[_timeSize - i] = -imag[i];
    }
}

void FFT::fft()
{
    for (int halfSize = 1; halfSize < real_len; halfSize *= 2)
    {
        // float k = -(float)Math.PI/halfSize;
        // phase shift step
        // float phaseShiftStepR = (float)Math.cos(k);
        // float phaseShiftStepI = (float)Math.sin(k);
        // using lookup table
        float phaseShiftStepR = Cos(halfSize);
        float phaseShiftStepI = Sin(halfSize);
        // current phase shift
        float currentPhaseShiftR = 1.0f;
        float currentPhaseShiftI = 0.0f;
        for (int fftStep = 0; fftStep < halfSize; fftStep++)
        {
            for (int i = fftStep; i < real_len; i += 2 * halfSize)
            {
                int off = i + halfSize;
                float tr = (currentPhaseShiftR * real[off]) - (currentPhaseShiftI * imag[off]);
                float ti = (currentPhaseShiftR * imag[off]) + (currentPhaseShiftI * real[off]);
                real[off] = real[i] - tr;
                imag[off] = imag[i] - ti;
                real[i] += tr;
                imag[i] += ti;
            }
            float tmpR = currentPhaseShiftR;
            currentPhaseShiftR = (tmpR * phaseShiftStepR) - (currentPhaseShiftI * phaseShiftStepI);
            currentPhaseShiftI = (tmpR * phaseShiftStepI) + (currentPhaseShiftI * phaseShiftStepR);
        }
    }
}

void FFT::forward(float* buffer, int buffer_len)
{
    if (buffer_len != _timeSize)
    {
        //    Minim.error("FFT.forward: The length of the passed sample buffer must be equal to timeSize().");
        return;
    }
    //  doWindow(buffer);
    // copy samples to real/imag in bit-reversed order
    bitReverseSamples(buffer, buffer_len, 0);
    // perform the fft
    fft();
    // fill the spectrum buffer with amplitudes
    fillSpectrum();
    
}

void FFT::forward(float* buffer, int buffer_len, int startAt)
{
    if ( buffer_len - startAt < _timeSize )
    {
        /*   Minim.error( "FourierTransform.forward: not enough samples in the buffer between " +
         startAt + " and " + buffer_len + " to perform a transform."
         );
         */
        return;
    }
    
    //   windowFunction.apply( buffer, startAt, timeSize );
    bitReverseSamples(buffer, buffer_len, startAt);
    fft();
    fillSpectrum();
}

/**
 * Performs a forward transform on the passed buffers.
 *
 * @param buffReal the real part of the time domain signal to transform
 * @param buffImag the imaginary part of the time domain signal to transform
 */
void FFT::forward(float* buffReal, int buffReal_len, float* buffImag, int buffImag_len)
{
    if (buffReal_len != _timeSize || buffImag_len != _timeSize)
    {
        //  Minim.error("FFT.forward: The length of the passed buffers must be equal to timeSize().");
        return;
    }
    setComplex(buffReal, buffReal_len, buffImag, buffImag_len);
    bitReverseComplex();
    fft();
    fillSpectrum();
}

void FFT::inverse(float* buffer, int buffer_len)
{
    if (buffer_len > real_len)
    {
        //   Minim.error("FFT.inverse: the passed array's length must equal FFT.timeSize().");
        return;
    }
    // conjugate
    for (int i = 0; i < _timeSize; i++)
    {
        imag[i] *= -1;
    }
    bitReverseComplex();
    fft();
    // copy the result in real into buffer, scaling as we do
    for (int i = 0; i < buffer_len; i++)
    {
        buffer[i] = real[i] / real_len;
    }
}

void FFT::buildReverseTable()
{
    int N = _timeSize;
    reverse = new int[N];
    
    // set up the bit reversing table
    reverse[0] = 0;
    for (int limit = 1, bit = N / 2; limit < N; limit <<= 1, bit >>= 1)
        for (int i = 0; i < limit; i++)
            reverse[i + limit] = reverse[i] + bit;
}

// copies the values in the samples array into the real array
// in bit reversed order. the imag array is filled with zeros.
void FFT::bitReverseSamples(float* samples, int samples_len, int startAt)
{
    for (int i = 0; i < _timeSize; ++i)
    {
        real[i] = samples[ startAt + reverse[i] ];
        imag[i] = 0.0f;
    }
}

void FFT::bitReverseComplex()
{
    float* revReal = new float[real_len];
    float* revImag = new float[imag_len];
    for (int i = 0; i < real_len; i++)
    {
        revReal[i] = real[reverse[i]];
        revImag[i] = imag[reverse[i]];
    }
    
    memcpy(real, revReal, sizeof(float) * real_len);
    memcpy(imag, revImag, sizeof(float) * imag_len);
    
    delete[] revReal;
    delete[] revImag;
}

float FFT::Sin(int i)
{
    return sinlookup[i];
}

float FFT::Cos(int i)
{
    return coslookup[i];
}

void FFT::buildTrigTables()
{
    int N = _timeSize;
    sinlookup = new float[N];
    sinlookup_len = N;
    coslookup = new float[N];
    coslookup_len = N;
    for (int i = 0; i < N; i++)
    {
        sinlookup[i] = (float) sin(-(float) PI / i);
        coslookup[i] = (float) cos(-(float) PI / i);
    }
}

