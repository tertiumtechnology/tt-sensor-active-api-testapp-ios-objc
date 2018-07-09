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
        _api = [PassiveReader getInstance];
        _api.readerListenerDelegate = self;
        _api.inventoryListenerDelegate = self;
        _api.responseListenerDelegate = self;
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

// AbstractResponseListenerProtocol implementation
-(void)writeIDevent: (NSData*_Nonnull) tagID error: (int) error
{
	if (_responseListenerDelegate)
		[_responseListenerDelegate writeIDevent: tagID error: error];
}

-(void)writePasswordEvent: (NSData *_Nonnull) tagID error: (int) error
 {
	if (_responseListenerDelegate)
		[_responseListenerDelegate writePasswordEvent: tagID error: error];
}

-(void)readTIDevent: (NSData *_Nonnull) tagID error: (int) error TID: (NSData *_Nullable) TID
{
	if (_responseListenerDelegate)
		[_responseListenerDelegate readTIDevent: tagID error: error TID: TID];
}

-(void)readEvent: (NSData *_Nonnull) tagID error: (int) error data: (NSData *_Nullable) data
{
	if (_responseListenerDelegate)
		[_responseListenerDelegate readEvent: tagID error: error data: data];
}

-(void)writeEvent: (NSData *_Nonnull) tagID error: (int) error
{
	if (_responseListenerDelegate)
		[_responseListenerDelegate writeEvent: tagID error: error];
}

-(void)lockEvent: (NSData *_Nonnull) tagID error: (int) error
{
	if (_responseListenerDelegate)
		[_responseListenerDelegate lockEvent: tagID error: error];
}

-(void)killEvent: (NSData *_Nonnull) tagID error: (int) error
{
	if (_responseListenerDelegate)
		[_responseListenerDelegate killEvent: tagID error: error];
}

// AbstractInventoryListenerProtocol implementation
-(void)inventoryEvent: (Tag *_Nonnull) tag
{
	if (_inventoryListenerDelegate)
		[_inventoryListenerDelegate inventoryEvent: tag];
}

// AbstractReaderListenerProtocol implementation
-(void)connectionFailureEvent: (int) error
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate connectionFailureEvent: error];
}

-(void)connectionSuccessEvent
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate connectionSuccessEvent];
}

-(void)disconnectionEvent
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate disconnectionEvent];
}

-(void)availabilityEvent: (bool) available
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate availabilityEvent: available];
}

-(void)resultEvent: (int) command error: (int) error 
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate resultEvent: command error: error];
}

-(void)batteryStatusEvent: (int) status
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate batteryStatusEvent: status];
}

-(void)firmwareVersionEvent: (int) major minor: (int) minor
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate firmwareVersionEvent: major minor: minor];
}

-(void)shutdownTimeEvent: (int) time
{
    if (_readerListenerDelegate)
		[_readerListenerDelegate shutdownTimeEvent: time];
}

-(void)RFpowerEvent: (int) level mode: (int) mode
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate RFpowerEvent: level mode: mode];
}

-(void)batteryLevelEvent: (float) level
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate batteryLevelEvent: level];
}

-(void)RFforISO15693tunnelEvent: (int) delay timeout: (int) timeout
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate RFforISO15693tunnelEvent: delay timeout: timeout];
}

-(void)ISO15693optionBitsEvent: (int) option_bits
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate ISO15693optionBitsEvent: option_bits];
}

-(void)ISO15693extensionFlagEvent: (bool) flag permanent: (bool) permanent
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate ISO15693extensionFlagEvent: flag permanent: permanent];
}

-(void)ISO15693bitrateEvent: (int) bitrate permanent: (bool) permanent
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate ISO15693bitrateEvent: bitrate permanent: permanent];
}

-(void)EPCfrequencyEvent: (int) frequency
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate EPCfrequencyEvent: frequency];
}

-(void)tunnelEvent: (NSData *) data
{
	if (_readerListenerDelegate)
		[_readerListenerDelegate tunnelEvent: data];
}

@end
