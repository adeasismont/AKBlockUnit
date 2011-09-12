AKBlockUnit
===========

A simple block based Core Audio output unit.

Usage
=====

AKBlockUnit creates an audio output unit, and calls your specified block as the render callback.
Belows describes how to create a simple sine tone.

+ create a render callback

````
const float kFrequency = 11000;
const float kGain = 1.0;
const float kWaveform = (kFrequency * 2. * M_PI);

AKAudioCallback callback = ^OSStatus(AudioUnit audioUnit,
										 AudioUnitRenderActionFlags *ioActionFlags,
										 UInt32 inBusNumber,
										 UInt32 inNumberFrames,
										 AudioBufferList *ioData)
{
	static double previousPhase = 0;
	SInt16 *samples = (SInt16*)ioData->mBuffers[0].mData;
	
	for (UInt32 i = 0; i < inNumberFrames; i++)
	{
		double rad = previousPhase + kWaveform * 1 / kAKBlockUnitDefaultSampleRate;
		float val = kGain * SHRT_MAX * sinf(rad);
		previousPhase = rad;
		samples[i] = (SInt16)val;
	}
	return noErr;
};
````

+ create the AKBlockUnit instance

````
AKBlockUnit *unit = [[AKBlockUnit alloc] initWithBlock:callback];
````

+ start the output

````
[unit start];
````

Licence
=======

Public domain, free use.
Created by Anton Kiland 2011
anton@kiland.se