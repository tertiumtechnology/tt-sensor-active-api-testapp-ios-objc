/*
 * The MIT License
 *
 * Copyright 2017 Tertium Technology.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "EventsForwarder.h"

@implementation EventsForwarder

static EventsForwarder *_sharedInstance;

-(id)init
{
    self = [super init];
    if (self) {
        _api = [ActiveSensor getInstance];
        _api.responseListenerDelegate = self;
        _api.sensorListenerDelegate = self;
    }
    
    return self;
}

+(EventsForwarder *_Nonnull) getInstance
{
    if (_sharedInstance == nil) {
        _sharedInstance = [EventsForwarder new];
    }
    
    return _sharedInstance;
}

// AbstractResponseListenerProtocol protocol
-(void)calibrateSensorEvent: (int) sensorType error: (int) error
{
    [_responseListenerDelegate calibrateSensorEvent: sensorType error: error];
}

-(void)getCalibrationConfigurationEvent: (int) sensorType error: (int) error uncalibratedRawValue: (int) uncalibratedRawValue valueOffset: (int) valueOffset valueGain: (float) valueGain fullScale: (int) fullScale
{
    [_responseListenerDelegate getCalibrationConfigurationEvent: sensorType error: error uncalibratedRawValue: uncalibratedRawValue valueOffset: valueOffset valueGain: valueGain fullScale: fullScale];
}

-(void)getLogConfigurationEvent: (int) sensorType error: (int) error logEnable: (bool) logEnable logPeriod: (int) logPeriod
{
    [_responseListenerDelegate getLogConfigurationEvent: sensorType error: error logEnable: logEnable logPeriod: logPeriod];
}

-(void)logSensorEvent: (int) sensorType error: (int) error
{
    [_responseListenerDelegate logSensorEvent: sensorType error: error];
}

-(void)readLocalizationEvent: (int) error latitude: (float) latitude longitude: (float) longitude timestamp: (int) timestamp
{
    [_responseListenerDelegate readLocalizationEvent: error latitude: latitude longitude: longitude timestamp: timestamp];
}

-(void)readMagneticSealStatusEvent: (int) error status: (int) status
{
    [_responseListenerDelegate readMagneticSealStatusEvent: error status: status];
}

-(void)readOpticSealBackgroundEvent: (int) error backgroundLevel: (int) backgroundLevel
{
    [_responseListenerDelegate readOpticSealBackgroundEvent: error backgroundLevel: backgroundLevel];
}

-(void)readOpticSealForegroundEvent: (int) error foregroundLevel: (int) foregroundLevel
{
    [_responseListenerDelegate readOpticSealForegroundEvent: error foregroundLevel: foregroundLevel];
}

-(void)readSealEvent: (int) error closed: (bool) closed status: (int) status
{
    [_responseListenerDelegate readSealEvent: error closed: closed status: status];
}

-(void)readSensorEvent: (int) sensorType error: (int) error sensorValue: (float) sensorValue timestamp: (int) timestamp
{
    [_responseListenerDelegate readSensorEvent: sensorType error: error sensorValue: sensorValue timestamp: timestamp];
}

-(void)setupSealEvent: (int) error
{
    [_responseListenerDelegate setupSealEvent: error];
}

// AbstractSensorListenerProtocol
-(void)availabilityEvent: (bool) available
{
    [_sensorListenerDelegate availabilityEvent: available];
}

-(void)connectionFailureEvent: (int) error
{
    [_sensorListenerDelegate connectionFailureEvent: error];
}

-(void)connectionSuccessEvent
{
    [_sensorListenerDelegate connectionSuccessEvent];
}

-(void)disconnectionSuccessEvent
{
    [_sensorListenerDelegate disconnectionSuccessEvent];
}

-(void)firmwareVersionEvent: (int) major minor: (int) minor
{
    [_sensorListenerDelegate firmwareVersionEvent: major minor: minor];
}

-(void)getClockEvent: (int) sensorTime systemTime: (int) systemTime
{
    [_sensorListenerDelegate getClockEvent: sensorTime systemTime: systemTime];
}

-(void)getLoggedLocalizationDataEvent: (int) gpserror latitude: (float) latitude longitude: (float) longitude timestamp: (int) timestamp
{
    [_sensorListenerDelegate getLoggedLocalizationDataEvent: gpserror latitude: latitude longitude: longitude timestamp: timestamp];
}

-(void)getLoggedMeasureDataEvent: (int) sensorType sensorValue: (float) sensorValue timestamp: (int) timestamp
{
    [_sensorListenerDelegate getLoggedMeasureDataEvent: sensorType sensorValue: sensorValue timestamp: timestamp];
}

-(void)getLoggedSealDataEvent: (bool) closed status: (int) status timestamp: (int) timestamp
{
    [_sensorListenerDelegate getLoggedSealDataEvent: closed status: status timestamp: timestamp];
}

-(void)resultEvent: (int) command error: (int) error
{
    [_sensorListenerDelegate resultEvent: command error: error];
}

@end
