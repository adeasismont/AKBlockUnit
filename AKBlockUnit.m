#import "AKBlockUnit.h"

// constants
const float kAKBlockUnitDefaultSampleRate		= 44100.;
const UInt32 kAKBlockUnitDefaultBus				= 0;

// forward declarations
OSStatus AKBlockUnitRenderCallback(void *inRefCon,
								   AudioUnitRenderActionFlags *ioActionFlags,
								   const AudioTimeStamp *inTimeStamp,
								   UInt32 inBusNumber, 
								   UInt32 inNumberFrames,
								   AudioBufferList *ioData);

// internal interface
@interface AKBlockUnit ()
{
	AudioUnit				_audioUnit;
	AKAudioCallback			_block;
}
- (void)configureWithComponent:(AudioComponentDescription)componentDescription
				   audioFormat:(AudioStreamBasicDescription)audioFormat
						 block:(AKAudioCallback)block;
- (AudioComponentDescription)defaultComponentDescription;
- (AudioStreamBasicDescription)defaultAudioFormat;
- (OSStatus)renderCallbackWithFlags:(AudioUnitRenderActionFlags*)flags
						  timestamp:(const AudioTimeStamp*)timeStamp
						  busNumber:(UInt32)busNumber
					   numberFrames:(UInt32)numberFrames
						 bufferList:(AudioBufferList*)data;
@end

// render callback
OSStatus AKBlockUnitRenderCallback(void *inRefCon,
								   AudioUnitRenderActionFlags *ioActionFlags,
								   const AudioTimeStamp *inTimeStamp,
								   UInt32 inBusNumber, 
								   UInt32 inNumberFrames,
								   AudioBufferList *ioData)
{
	AKBlockUnit *unit = (AKBlockUnit*)inRefCon;
	if ([unit isKindOfClass:[AKBlockUnit class]])
		return [unit renderCallbackWithFlags:ioActionFlags
								   timestamp:inTimeStamp
								   busNumber:inBusNumber
								numberFrames:inNumberFrames
								  bufferList:ioData];
	return noErr;
}

@implementation AKBlockUnit

- (id)initWithBlock:(AKAudioCallback)block
{
	if ((self = [super init]))
	{
		[self configureWithComponent:[self defaultComponentDescription]
						 audioFormat:[self defaultAudioFormat]
							   block:block];
	}
	return self;
}


- (id)initWithComponentDescription:(AudioComponentDescription)componentDescription
							 block:(AKAudioCallback)block
{
	if ((self = [super init]))
	{
		[self configureWithComponent:componentDescription
						 audioFormat:[self defaultAudioFormat]
							   block:block];
	}
	return self;
}


- (id)initWithComponentDescription:(AudioComponentDescription)componentDescription
					   audioFormat:(AudioStreamBasicDescription)audioFormat
							 block:(AKAudioCallback)block
{
	if ((self = [super init]))
	{
		[self configureWithComponent:componentDescription
						 audioFormat:audioFormat
							   block:block];
	}
	return self;
}


- (void)dealloc
{
	AudioUnitUninitialize(_audioUnit);
	Block_release(_block);
	[super dealloc];
}


- (void)configureWithComponent:(AudioComponentDescription)componentDescription
				   audioFormat:(AudioStreamBasicDescription)audioFormat
						 block:(AKAudioCallback)block;
{
	OSStatus status = noErr;
	
	_block = Block_copy(block);
	
	// find component
	AudioComponent component = AudioComponentFindNext(NULL, 
													  &componentDescription);
	assert(component != NULL);
	
	// create instance (AudioUnit)
	status = AudioComponentInstanceNew(component, &_audioUnit);
	assert(status == noErr);
	
	// set bus (0)
	UInt32 flag = 1;
	status = AudioUnitSetProperty(_audioUnit, 
								  kAudioOutputUnitProperty_EnableIO, 
								  kAudioUnitScope_Output, 
								  kAKBlockUnitDefaultBus, 
								  &flag, 
								  sizeof(flag));
	assert(status == noErr);
	
	// set format
	status = AudioUnitSetProperty(_audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Input, 
								  kAKBlockUnitDefaultBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
	assert(status == noErr);
	
	// setup render callback
	AURenderCallbackStruct callbackInfo;
	callbackInfo.inputProc = AKBlockUnitRenderCallback;
	callbackInfo.inputProcRefCon = self;
	status = AudioUnitSetProperty(_audioUnit, 
								  kAudioUnitProperty_SetRenderCallback, 
								  kAudioUnitScope_Global, 
								  kAKBlockUnitDefaultBus, 
								  &callbackInfo, 
								  sizeof(callbackInfo));
	assert(status == noErr);
	
	// initialize audio unit
	status = AudioUnitInitialize(_audioUnit);
	assert(status == noErr);
}


- (AudioComponentDescription)defaultComponentDescription
{
	AudioComponentDescription componentDescription;
	componentDescription.componentType = kAudioUnitType_Output;
	componentDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	componentDescription.componentFlags = 0;
	componentDescription.componentFlagsMask = 0;
	componentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	return componentDescription;
}


- (AudioStreamBasicDescription)defaultAudioFormat
{
	AudioStreamBasicDescription audioDescription;
	audioDescription.mSampleRate = kAKBlockUnitDefaultSampleRate;
	audioDescription.mFormatID = kAudioFormatLinearPCM;
	audioDescription.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioDescription.mFramesPerPacket = 1;
	audioDescription.mChannelsPerFrame = 1;
	audioDescription.mBitsPerChannel = 16;
	audioDescription.mBytesPerPacket = 2;
	audioDescription.mBytesPerFrame = 2;
	return audioDescription;
}


- (OSStatus)renderCallbackWithFlags:(AudioUnitRenderActionFlags*)flags
						  timestamp:(const AudioTimeStamp*)timeStamp
						  busNumber:(UInt32)busNumber
					   numberFrames:(UInt32)numberFrames
						 bufferList:(AudioBufferList*)data
{
	OSStatus result;
	result = _block(_audioUnit,
					flags,
					busNumber,
					numberFrames,
					data);
	return result;
}


- (void)start
{
	OSStatus status;
	status = AudioOutputUnitStart(_audioUnit);
	assert(status == noErr);
}


- (void)stop
{
	OSStatus status;
	status = AudioOutputUnitStop(_audioUnit);
	assert(status == noErr);
}

@end