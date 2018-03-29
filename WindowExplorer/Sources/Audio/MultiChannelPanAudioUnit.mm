//  Copyright © 2018 JABT. All rights reserved.

#import "MultiChannelPanAudioUnit.h"

#import <Accelerate/Accelerate.h>
#import <AVFoundation/AVFoundation.h>

#import "BufferedAudioBus.hpp"

// Number of channels to pan across
const UInt32 channels = 6;

// Define parameter addresses.
const AudioUnitParameterID locationParameterID = 0;

@interface MultiChannelPanAudioUnit ()

@property (nonatomic) AUParameterTree *parameterTree;
@property (nonatomic) AUAudioUnitBus *outputBus;
@property (nonatomic) AUAudioUnitBusArray *inputBusArray;
@property (nonatomic) AUAudioUnitBusArray *outputBusArray;

@end


@implementation MultiChannelPanAudioUnit {
    BufferedInputBus _inputBus;
}

@synthesize parameterTree = _parameterTree;

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError **)outError {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];

    if (self == nil) {
        return nil;
    }

    // Create parameter objects.
    AUParameter *location = [AUParameterTree
                             createParameterWithIdentifier:@"location" name:@"Location"
                             address:locationParameterID
                             min:0 max:1 unit:kAudioUnitParameterUnit_Pan unitName:nil
                             flags:kAudioUnitParameterFlag_IsReadable | kAudioUnitParameterFlag_IsWritable
                             valueStrings:nil dependentParameters:nil];

    // Initialize the parameter values.
    location.value = 0.5;
    
    // Create the parameter tree.
    _parameterTree = [AUParameterTree createTreeWithChildren:@[ location ]];
    
    // Create the input bus
    AVAudioFormat *inputFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:1];
    _inputBus.init(inputFormat, 2);
    _inputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeInput busses:@[_inputBus.bus]];

    // Create the output bus
    AudioChannelLayout *layout = (AudioChannelLayout *)malloc(sizeof(AudioChannelLayout) + sizeof(AudioChannelDescription) * (channels - 1));
    for (UInt32 channel = 0; channel < channels; channel += 1) {
        AudioChannelDescription *desc = &layout->mChannelDescriptions[channel];
        desc->mChannelLabel = channel + 1;
        desc->mChannelFlags = 0;
        desc->mCoordinates[0] = 0;
        desc->mCoordinates[1] = 0;
        desc->mCoordinates[2] = 0;
    }
    layout->mNumberChannelDescriptions = channels;
    layout->mChannelBitmap = 0;
    layout->mChannelLayoutTag = kAudioChannelLayoutTag_UseChannelDescriptions;

    AVAudioChannelLayout *alayout = [[AVAudioChannelLayout alloc] initWithLayout:layout];
    AVAudioFormat *outputFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channelLayout:alayout];
    _outputBus = [[AUAudioUnitBus alloc] initWithFormat:outputFormat error:nil];
    _outputBus.supportedChannelCounts = @[@(channels)];
    _outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeOutput busses:@[_outputBus]];

    // implementorValueObserver is called when a parameter changes value.
    typeof(self) __weak weakSelf = self;
    _parameterTree.implementorValueObserver = ^(AUParameter *param, AUValue value) {
        weakSelf.location = value;
    };

    // implementorValueProvider is called when the value needs to be refreshed.
    _parameterTree.implementorValueProvider = ^(AUParameter *param) {
        return weakSelf.location;
    };

    // A function to provide string representations of parameter values.
    _parameterTree.implementorStringFromValueCallback = ^(AUParameter *param, const AUValue *__nullable valuePtr) {
        AUValue value = valuePtr == nil ? param.value : *valuePtr;
        
        switch (param.address) {
            case locationParameterID:
                return [NSString stringWithFormat:@"%.f", value];
            default:
                return @"?";
        }
    };
    
    self.maximumFramesToRender = 512;
    
    return self;
}

- (NSArray<NSNumber *> *)channelCapabilities {
    return @[@-1, @(channels)];
}

#pragma mark - AUAudioUnit Overrides

- (AUAudioUnitBusArray *)inputBusses {
    return _inputBusArray;
}

- (AUAudioUnitBusArray *)outputBusses {
    return _outputBusArray;
}

// Allocate resources required to render.
// Subclassers should call the superclass implementation.
- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    if (![super allocateRenderResourcesAndReturnError:outError]) {
        return NO;
    }

    _inputBus.allocateRenderResources(self.maximumFramesToRender);
    
    return YES;
}

// Deallocate resources allocated in allocateRenderResourcesAndReturnError:
// Subclassers should call the superclass implementation.
- (void)deallocateRenderResources {
    _inputBus.deallocateRenderResources();
    [super deallocateRenderResources];
}

#pragma mark - AUAudioUnit (AUAudioUnitImplementation)

- (AUInternalRenderBlock)internalRenderBlock {
    // Capture in locals to avoid ObjC member lookups. If "self" is captured in render, we're doing it wrong. See sample code.
    __block BufferedInputBus *input = &_inputBus;
    
    return ^AUAudioUnitStatus(AudioUnitRenderActionFlags *actionFlags, const AudioTimeStamp *timestamp, AVAudioFrameCount frameCount, NSInteger outputBusNumber, AudioBufferList *outputData, const AURenderEvent *realtimeEventListHead, AURenderPullInputBlock pullInputBlock) {
        AudioUnitRenderActionFlags pullFlags = 0;

        AUAudioUnitStatus err = input->pullInput(&pullFlags, timestamp, frameCount, 0, pullInputBlock);
        if (err != 0) {
            return err;
        }

        AudioBufferList *inAudioBufferList = input->mutableAudioBufferList;
        AudioBufferList *outAudioBufferList = outputData;

        Float32 location = self.location;
        for (UInt32 channel = 0; channel < outAudioBufferList->mNumberBuffers; channel += 1) {
            Float32 channelLocation = Float32(2*channel + 1) / Float32(2 * channels);

            Float32 channelGain = 0;
            if (location <= channelLocation) {
                channelGain = Float32(channels) * (location - channelLocation) + 1;
            } else {
                channelGain = -Float32(channels) * (location - channelLocation) + 1;
            }
            if (channelGain < 0) {
                channelGain = 0;
            }

            vDSP_vsmul((float *)inAudioBufferList->mBuffers[0].mData, 1, &channelGain, (float *)outAudioBufferList->mBuffers[channel].mData, 1, inAudioBufferList->mBuffers[0].mDataByteSize / sizeof(Float32));
        }

        return noErr;
    };
}

@end
