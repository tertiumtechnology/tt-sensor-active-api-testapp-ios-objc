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

#import <UIKit/UIKit.h>
#import <TxRxLib/TxRxLib.h>
#import <RfidActiveApiSensorLibObjC/RfidActiveApiSensorLibObjC.h>
#import "EventsForwarder.h"

@class Core;

typedef enum CommandType: int {
    noCommand = 0
    ,initialCommands
    ,customCommand
    ,repeatingCommand
} CommandType;

@interface DeviceDetailViewController : UIViewController<UIPickerViewDelegate, UIPickerViewDataSource, AbstractReaderListenerProtocol, AbstractResponseListenerProtocol, AbstractInventoryListenerProtocol>
{
    PassiveReader *_api;
	EventsForwarder *_eventsForwarder;
    NSTimer *_timer;
    UIFont *_font;
    NSMutableAttributedString *_initialCommandsBuffer;
    NSMutableAttributedString *_customCommandsBuffer;
    NSMutableArray<Tag *> *_tags;
    float _batteryLevel;
    NSInteger _batteryStatus;
    bool _deviceAvailable;
    NSInteger _currentInitialOperation;
    NSInteger _maxInitialOperations;
    NSInteger _selectedRow;
    NSInteger _repeatingCommandIndex;
    NSInteger _lastRepeatingCommand;
    CommandType _lastCommandType;
    bool _inExtendedView;
    bool _connected;
}

@property (nonatomic, retain) NSString *deviceName;

@property (weak, nonatomic) IBOutlet UILabel *lblDevice;
@property (weak, nonatomic) IBOutlet UIButton *btnConnect;
@property (weak, nonatomic) IBOutlet UIButton *btnStartOperation;
@property (weak, nonatomic) IBOutlet UITextView *txtInitialCommands;
@property (weak, nonatomic) IBOutlet UIPickerView *pikSelectCommand;
@property (weak, nonatomic) IBOutlet UITextView *txtCustomCommands;
@property (weak, nonatomic) IBOutlet UILabel *lblBatteryStatus;

- (IBAction)btnConnectPressed:(id)sender;
-(void)appendTextToBuffer: (NSString *) text error: (int) error;
-(void)appendTextToBuffer: (NSString *) text color: (UIColor *) color;


@end
