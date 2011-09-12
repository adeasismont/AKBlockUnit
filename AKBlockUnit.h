/*
 AKBlockUnit
 
 A simple block based Core Audio output unit.
 
 Created by Anton Kiland 2011.
 Released as is to the public domain, free use.
*/

#import <AudioToolbox/AudioToolbox.h>

typedef OSStatus (^AKAudioCallback)(AudioUnit audioUnit,
									AudioUnitRenderActionFlags *ioActionFlags,
									UInt32 inBusNumber,
									UInt32 inNumberFrames,
									AudioBufferList *ioData);

extern const float kAKBlockUnitDefaultSampleRate;
extern const UInt32 kAKBlockUnitDefaultBus;

@interface AKBlockUnit : NSObject

// assumes kAudioUnitType_Output, linear PCM, signed, packet ints, 16 bits per channel
- (id)initWithBlock:(AKAudioCallback)block;

// assumes linear PCM, signed, packet ints, 16 bits per channel
- (id)initWithComponentDescription:(AudioComponentDescription)componentDescription
							 block:(AKAudioCallback)block;

// initialize with specified component and audio format descriptions
- (id)initWithComponentDescription:(AudioComponentDescription)componentDescription
					   audioFormat:(AudioStreamBasicDescription)audioFormat
							 block:(AKAudioCallback)block;

- (void)start;
- (void)stop;

@end