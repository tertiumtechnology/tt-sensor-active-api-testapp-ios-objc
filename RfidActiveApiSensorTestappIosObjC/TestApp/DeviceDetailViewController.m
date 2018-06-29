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

#import "DeviceDetailViewController.h"
#import "ExtendedTagTestsViewController.h"
#import "PassiveAPI/ISO15693_tag.h"
#import "PassiveAPI/ISO14443A_tag.h"
#import "PassiveAPI/EPC_tag.h"

@implementation DeviceDetailViewController

static NSMutableArray* _initialCommandsMap = nil;
static NSMutableArray* _customCommandsMap = nil;

static NSString* const operations[] = {
                         @"Select Operation",
                         @"Test Availability",
                         @"Sound",
                         @"Light",
                         @"Stop Light",
                         @"Set Shutdown Time (300)",
                         @"Get Shutdown Time",
                         @"Set RF Power",
                         @"Get RF Power",
                         @"Set ISO15693 Option Bits (Only HF)",
                         @"Get ISO15693 Option Bits (Only HF)",
                         @"Set ISO15693 Extension Flag(Only HF)",
                         @"Get ISO15693 Extension Flag(Only HF)",
                         @"Set ISO15693 Bitrate(Only HF)",
                         @"Get ISO15693 Bitrate(Only HF)",
                         @"Set EPC Frequency (only UHF)",
                         @"Get EPC Frequency (only UHF)",
                         @"setScanOnInput",
                         @"setNormalScan",
                         @"Do Inventory",
                         @"Clear inventory",
                         @"Extended tag tests",
                         @"Read first tag",
                         @"Write first tag",
                         @"Lock first tag",
                         @"Read TID for first tag",
                         @"Write ID for first tag",
                         @"Kill first tag"
                    };

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    _api = [PassiveReader getInstance];
	_eventsForwarder = [EventsForwarder getInstance];
    _eventsForwarder.readerListenerDelegate = self;
    _eventsForwarder.inventoryListenerDelegate = self;
    _eventsForwarder.responseListenerDelegate = self;
    
    //
    _font = [UIFont fontWithName: @"Terminal" size: 10.0];
    
    //
    _tags = [NSMutableArray new];
    _initialCommandsBuffer = [NSMutableAttributedString new];
    _customCommandsBuffer = [NSMutableAttributedString new];
    _txtInitialCommands.layer.borderColor = [[UIColor blueColor] CGColor];
    _txtInitialCommands.layer.borderWidth = 3.0;
    _txtCustomCommands.layer.borderColor = [[UIColor blueColor] CGColor];
    _txtCustomCommands.layer.borderWidth = 3.0;
    
    [self reset];
    [_lblDevice setText: _deviceName];
    
    //
    _inExtendedView = false;
    _connected = false;
    _lastRepeatingCommand = 0;
    
    //
    _timer = [NSTimer scheduledTimerWithTimeInterval: 15.0 target: self selector: @selector(repeatingCommandsTimerTick:) userInfo: nil repeats: YES];
    
    //
    _lastCommandType = initialCommands;
    [self updateBatteryLabel];
}

-(void)dealloc
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnConnectPressed:(id)sender
{
    if (_deviceName != nil) {
        if (_connected == false) {
            [self reset];
            [_api connect: _deviceName];
        } else {
            [_api disconnect];
        }
    }
    
    [self.view endEditing:YES];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

// UIPickerViewDelegate, UIPickerViewDataSource protocol implementation
-(UIView*) pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *pickerLabel = (UILabel *)view;
    
    if (!pickerLabel) {
        pickerLabel = [UILabel new];
        pickerLabel.font = _font;
        pickerLabel.textAlignment = NSTextAlignmentLeft;
    }
    
    pickerLabel.text = operations[row];
    pickerLabel.textColor = [UIColor blackColor];
    return pickerLabel;
}

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView
{
    return 1;
}

-(NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return operations[row];
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return sizeof(operations)/sizeof(NSString *);
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    _selectedRow = row;
}

//
-(void)enableStartButton: (bool) enabled
{
    _btnStartOperation.enabled = enabled;
    if (!enabled) {
        [_btnStartOperation setTitleColor: [UIColor blackColor] forState: UIControlStateNormal];
        [_btnStartOperation setTitleColor: [UIColor blackColor] forState: UIControlStateSelected];
    } else {
        [_btnStartOperation setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
        [_btnStartOperation setTitleColor: [UIColor grayColor] forState: UIControlStateSelected];
    }
}

//
-(void) scrollDown: (UITextView *) textView
{
    NSRange range = NSMakeRange(textView.text.length - 1, 0);
    [textView scrollRangeToVisible: range];
}

-(void)appendInitialCommandsBuffer: (NSString *) text color: (UIColor *) color
{
    [_initialCommandsBuffer appendAttributedString: [[NSAttributedString alloc] initWithString: text attributes: @{ NSForegroundColorAttributeName: color }]];
    _txtInitialCommands.attributedText = [_initialCommandsBuffer copy];
    [self scrollDown: _txtInitialCommands];
}

-(void)appendCustomCommandsBuffer: (NSString *) text color: (UIColor *) color
{
    [_customCommandsBuffer appendAttributedString: [[NSAttributedString alloc] initWithString: text attributes: @{ NSForegroundColorAttributeName: color }]];
    _txtCustomCommands.attributedText = [_customCommandsBuffer copy];
    [self scrollDown: _txtCustomCommands];
}

-(void)appendTextToBuffer: (NSString *) text error: (int) error
{
    NSString *fmtText;
    
    if (_lastCommandType == repeatingCommand)
        return;
    
    fmtText = [NSString stringWithFormat: @"%@\r\n", text];
    if (_lastCommandType == initialCommands) {
        [self appendInitialCommandsBuffer: fmtText color: (error == 0 ? [UIColor whiteColor]: [UIColor redColor])];
    } else if (_lastCommandType == customCommand) {
        [self appendCustomCommandsBuffer: fmtText color: (error == 0 ? [UIColor whiteColor]: [UIColor redColor])];
    }
}

-(void)appendTextToBuffer: (NSString *) text color: (UIColor *) color
{
    NSString *fmtText;
    
    fmtText = [NSString stringWithFormat: @"%@\r\n", text];
    if (_lastCommandType == initialCommands) {
        [self appendInitialCommandsBuffer: fmtText color: color];
    } else {
        [self appendCustomCommandsBuffer: fmtText color: color];
    }
}

-(void)appendTextToBuffer: (NSString *) text color: (UIColor *) color command: (int) command
{
    if (command == _lastRepeatingCommand)
        return;
    
    [self appendTextToBuffer: text color: color];
}

-(void)reset
{
    [_api disconnect];
    [self enableStartButton: false];
    _lastCommandType = initialCommands;
    _currentInitialOperation = 0;
    _maxInitialOperations = 1;
    _batteryLevel = 0;
    _batteryStatus = 0;
    _deviceAvailable = false;
    [_tags removeAllObjects];
}

-(void)callNextInitialOperation
{
    if (!_initialCommandsMap) {
        _initialCommandsMap = [NSMutableArray new];
        [_initialCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if ([vc->_api isHF]) {
                [vc appendTextToBuffer: @"HF reader (for ISO-15693/ISO-14443 tags)" color: [UIColor whiteColor]];
            } else {
                [vc appendTextToBuffer: @"UHF reader (for EPC tags)" color: [UIColor whiteColor]];
            }
            
            [vc enableStartButton: true];
        }];
        
        [_initialCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc appendTextToBuffer: @"setInventoryType" color: [UIColor yellowColor]];
            if ([vc->_api isHF]){
                [vc->_api setInventoryType: ISO15693_AND_ISO14443A_STANDARD];
            } else {
                [vc->_api setInventoryType: EPC_STANDARD];
            }
        }];
        
        [_initialCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc appendTextToBuffer: @"getFirmwareVersion" color: [UIColor yellowColor]];
            [vc->_api getFirmwareVersion];
        }];
        
        [_initialCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc appendTextToBuffer: @"setInventoryParameters" color: [UIColor yellowColor]];
            [vc->_api setInventoryParameters: FEEDBACK_SOUND_AND_LIGHT timeout: 1000 interval: 1000];
        }];
    }
    
    if (_btnStartOperation.enabled == false)
        return;
    
    _lastCommandType = initialCommands;
    _maxInitialOperations = _initialCommandsMap.count;
    [self enableStartButton: false];
    
    void (^command)(DeviceDetailViewController*vc) = [_initialCommandsMap objectAtIndex: _currentInitialOperation];
    command(self);
    _currentInitialOperation = _currentInitialOperation + 1;
    if (_currentInitialOperation == 1) {
        [self enableStartButton: false];
        void (^command)(DeviceDetailViewController*vc) = [_initialCommandsMap objectAtIndex: _currentInitialOperation];
        command(self);
        _currentInitialOperation = _currentInitialOperation + 1;
    }
}

-(void)callCustomOperation: (int) method
{
    if (_btnStartOperation.enabled == false) {
        return;
    }
    
    if (_customCommandsMap == nil) {
        _customCommandsMap = [NSMutableArray new];
        
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc enableStartButton: true];
        }];
        
        // Test Availability
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api testAvailability];
        }];
        
        // Sound
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api sound: 1000 step: 1000 duration: 1000 interval: 500 repetition: 3];
        }];

        // Light
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api light: true ledBlinking: 500];
        }];

        // Light off
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api light: false ledBlinking: 0];
        }];

        // Set Shutdown Time (300)
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api setShutdownTime: 300];
        }];

        // Get Shutdown Time
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api getShutdownTime];
        }];

        // Set RF Power
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if ([vc->_api isHF]) {
                [vc->_api setRFpower: HF_RF_FULL_POWER mode: HF_RF_AUTOMATIC_POWER];
            } else {
                [vc->_api setRFpower: UHF_RF_POWER_0_DB mode: UHF_RF_POWER_AUTOMATIC_MODE];
            }
        }];
        
        // Get RF Power
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api getRFpower];
        }];
        
        // SetISO15693optionBits
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api setISO15693optionBits: ISO15693_OPTION_BITS_NONE];
        }];

        // GetISO15693optionBits
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api getISO15693optionBits];
        }];
        
        // SetISO15693extensionFlag
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api setISO15693extensionFlag: true permanent: false];
        }];
        
        // GetISO15693extensionFlag
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api getISO15693extensionFlag];
        }];
        
        // SetISO15693bitrate
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api setISO15693bitrate: ISO15693_HIGH_BITRATE permanent: false];
        }];
        
        // GetISO15693bitrate
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api getISO15693bitrate];
        }];

        // SetEPCfrequency
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api setEPCfrequency: RF_CARRIER_866_9_MHZ];
        }];
        
        // GetEPCfrequency
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api getEPCfrequency];
        }];
        
        // setScanOnInput
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api setInventoryMode: SCAN_ON_INPUT_MODE];
        }];
        
        // setNormalScan
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api setInventoryMode: NORMAL_MODE];
        }];
        
        // DoInventory
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [self->_tags removeAllObjects];
            [vc->_api doInventory];
            
            // IMPORTANT! force no command sent, inventory doesn't notify back!
            [vc enableStartButton: true];
        }];
        
        // Clear inventory
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [self->_tags removeAllObjects];
            
            // IMPORTANT! force no command sent, inventory doesn't notify back!
            [vc enableStartButton: true];
            [vc appendTextToBuffer: @"Tag list cleared!" color: [UIColor whiteColor]];
        }];
        
        // Extended tag tests
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            ExtendedTagTestsViewController *extTestsVC;
            
            if (vc->_tags.count != 0) {
                extTestsVC = [vc.storyboard instantiateViewControllerWithIdentifier: @"ExtendedTagTestsViewController"];
                if (extTestsVC) {
                    extTestsVC.tags = vc->_tags;
                    extTestsVC.deviceDetailVC = vc;
                    extTestsVC.deviceName = vc.deviceName;
                    vc->_inExtendedView = true;
                    [vc.navigationController pushViewController: extTestsVC animated: true];
                }
            } else {
                [vc appendTextToBuffer: @"Please do inventory first!" color: [UIColor redColor]];
            }
            [vc enableStartButton: true];
        }];
        
        // Read first tag
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (vc->_tags.count != 0) {
                id tag = vc->_tags[0];
                if ([tag isKindOfClass: [ISO15693_tag class]]) {
                    ISO15693_tag* tag = (ISO15693_tag *) vc->_tags[0];
                    [tag setTimeout: 2000];
                    [tag read: 0 blocks: 2];
                 } else if ([tag isKindOfClass: [EPC_tag class]]) {
                    EPC_tag* tag = (EPC_tag *) vc->_tags[0];
                    [tag read: 8 blocks: 4 password: nil];
                }
            } else {
                [vc appendTextToBuffer: @"Please do inventory first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
            }
        }];
        
        // Write first tag
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            NSDate *date = [NSDate new];
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSInteger minutes = [calendar component: NSCalendarUnitMinute fromDate: date];
            
            char data[] = {
                        (char)(minutes)
                        ,(char)(minutes+1)
                        ,(char)(minutes+2)
                        ,(char)(minutes+3)
                        ,(char)(minutes+4)
                        ,(char)(minutes+5)
                        ,(char)(minutes+6)
                        ,(char)(minutes+7)
            };
            
            if (vc->_tags.count != 0) {
                id tag = vc->_tags[0];
                if ([tag isKindOfClass: [ISO15693_tag class]]) {
                    ISO15693_tag *tag = (ISO15693_tag *) vc->_tags[0];
                    [tag setTimeout: 2000];
                    [tag write: 0 data: [[NSData alloc] initWithBytes: data length: sizeof(data)/sizeof(char)]];
                } else if ([tag isKindOfClass: [EPC_tag class]]) {
                    EPC_tag *tag = (EPC_tag *) vc->_tags[0];
                    [tag write: 8 data: [[NSData alloc] initWithBytes: data length: sizeof(data)/sizeof(char)] password: nil];
                }
            } else {
                [vc appendTextToBuffer: @"Please do inventory first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
            }
        }];
        
        // Lock first tag
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (vc->_tags.count != 0) {
                id tag = vc->_tags[0];
                if ([tag isKindOfClass: [ISO15693_tag class]]) {
                    ISO15693_tag *tag = (ISO15693_tag *) vc->_tags[0];
                    [tag setTimeout: 2000];
                    [tag lock: 0 blocks: 2];
                } else if ([tag isKindOfClass: [EPC_tag class]]) {
                    EPC_tag *tag = (EPC_tag *) vc->_tags[0];
                    [tag lock: EPC_TAG_MEMORY_NOTWRITABLE password: nil];
                }
            } else {
                [vc appendTextToBuffer: @"Please do inventory first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
            }
        }];

        // Read TID for first tag
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (vc->_tags.count != 0) {
                id tag = vc->_tags[0];
                if ([tag isKindOfClass: [EPC_tag class]]) {
                    EPC_tag *tag = (EPC_tag *) vc->_tags[0];
                    [tag readTID: 8 password: nil];
                } else {
                    [vc appendTextToBuffer: @"Command unavailable on this tag" color: [UIColor redColor]];
                    [vc enableStartButton: true];
                }
            } else {
                [vc appendTextToBuffer: @"Please do inventory first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
            }
        }];

        // Write ID for first tag
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            UInt8 ID[] = {
                      0x00,
                      0x01,
                      0x02,
                      0x03,
                      0x04,
                      0x05,
                      0x06,
                      0x07,
                      0x08,
                      0x09,
                      0x0A,
                      0x0B,
                      0x0C,
                      0x0D,
                      0x0E,
                      0x0F
            };
            
            if (vc->_tags.count != 0) {
                id tag = vc->_tags[0];
                if ([tag isKindOfClass: [EPC_tag class]]) {
                    EPC_tag *tag = (EPC_tag *) vc->_tags[0];
                    [tag writeID: [[NSData alloc] initWithBytes: ID length: sizeof(ID)/sizeof(UInt8)] NSI: 0];
                } else {
                    [vc appendTextToBuffer: @"Command unavailable on this tag" color: [UIColor redColor]];
                    [vc enableStartButton: true];
                }
            } else {
                [vc appendTextToBuffer: @"Please do inventory first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
            }
        }];
        
        // Kill first tag
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (vc->_tags.count != 0) {
                id tag = vc->_tags[0];
                if ([tag isKindOfClass: [EPC_tag class]]) {
                    char data[] = { 0, 0, 0, 0 };
                    EPC_tag *tag = (EPC_tag *) vc->_tags[0];
                    [tag kill: [[NSData alloc] initWithBytes: data length: sizeof(data)/sizeof(UInt8)]];
                } else {
                    [vc appendTextToBuffer: @"Command unavailable on this tag" color: [UIColor redColor]];
                    [vc enableStartButton: true];
                }
            } else {
                [vc appendTextToBuffer: @"Please do inventory first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
            }
        }];
    }
    
    _lastCommandType = customCommand;
    [self enableStartButton: false];
    void (^command)(DeviceDetailViewController*vc) = [_customCommandsMap objectAtIndex: method];
    command(self);
}

-(void)pushCommands
{
    if (_currentInitialOperation < _maxInitialOperations)
        [self callNextInitialOperation];
}

-(void)updateBatteryLabel
{
    NSString *fmtText;
    
    fmtText = [NSString stringWithFormat: @"Available: %@ Battery status: %ld Level: %0.2f", (_deviceAvailable ? @"yes": @"No"), (long)_batteryStatus, _batteryLevel];
    _lblBatteryStatus.text = fmtText;
}

//
-(void)repeatingCommandsTimerTick:(NSTimer *)timer
{
    if (_connected && _inExtendedView == false && _btnStartOperation.isEnabled == true && _currentInitialOperation >= _maxInitialOperations) {
        if (_repeatingCommandIndex >= 3)
            _repeatingCommandIndex = 0;
        
        _lastCommandType = repeatingCommand;
        [self enableStartButton: false];
        
        if (_repeatingCommandIndex == 0) {
            [self->_api getBatteryLevel];
            _lastRepeatingCommand = ABSTRACT_READER_LISTENER_GET_BATTERY_LEVEL_COMMAND;
        } else if (_repeatingCommandIndex == 1) {
            [self->_api getBatteryStatus];
            _lastRepeatingCommand = ABSTRACT_READER_LISTENER_GET_BATTERY_STATUS_COMMAND;
        } else if (_repeatingCommandIndex == 2) {
            [self->_api testAvailability];
            _lastRepeatingCommand = ABSTRACT_READER_LISTENER_TEST_AVAILABILITY_COMMAND;
        }
        
        _repeatingCommandIndex = _repeatingCommandIndex + 1;
    }
}
- (IBAction)selfcallCustomOperation_selectedRowbtnStartOperationPressed:(id)sender {
    [self callCustomOperation: (int)_selectedRow];
}

// AbstractReaderListenerProtocol implementation
-(void)connectionFailureEvent: (int) error
{
    UIAlertView *alertView;
    _connected = false;
    
    alertView = [[UIAlertView alloc] initWithTitle: @"Connection failed!" message: @"error" delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
    [alertView show];
}

-(void)connectionSuccessEvent
{
    [self enableStartButton: true];
    _connected = true;
    [_btnConnect setTitle: @"DISCONNECT" forState: UIControlStateNormal];
    [self pushCommands];
}

-(void)disconnectionEvent
{
    [self enableStartButton: false];
    _connected = false;
    [_btnConnect setTitle: @"CONNECT" forState: UIControlStateNormal];
}

-(void)availabilityEvent: (bool) available
{
    _deviceAvailable = available;
    [self updateBatteryLabel];
    [self appendTextToBuffer: [NSString stringWithFormat: @"availabilityEvent %@", (available ? @"yes": @"no")] color: [UIColor whiteColor] command: ABSTRACT_READER_LISTENER_TEST_AVAILABILITY_COMMAND];
}

-(void)resultEvent: (int) command error: (int) error
{
    NSString *result, *errStr;
    [self enableStartButton: true];
    
    errStr = (error == 0 ? @"NO error": [NSString stringWithFormat: @"Error %d", error]);
    result = [NSString stringWithFormat: @"Result command = %d %@", command, errStr];
    [self appendTextToBuffer: result error: error];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self pushCommands];
    });
}

-(void)batteryStatusEvent: (int) status
{
    _batteryStatus = status;
    [self updateBatteryLabel];
}

-(void)firmwareVersionEvent: (int) major minor: (int) minor
{
    NSString *firmwareVersion;
    
    firmwareVersion = [NSString stringWithFormat: @"Firmware = %d.%d", major, minor];
    [self appendTextToBuffer: firmwareVersion color: [UIColor whiteColor]];
}

-(void)shutdownTimeEvent: (int) time
{
    NSString *shutdownTime = [NSString stringWithFormat: @"Shutdown-time %d", time];
    [self appendTextToBuffer: shutdownTime color: [UIColor whiteColor]];
}

-(void)RFpowerEvent: (int) level mode: (int) mode
{
    NSString *shutdownTime = [NSString stringWithFormat: @"RF-power: level = %d, mode = %d", level, mode];
    [self appendTextToBuffer: shutdownTime color: [UIColor whiteColor]];
}

-(void)batteryLevelEvent: (float)level
{
    _batteryLevel = level;
    [self updateBatteryLabel];
}

-(void)RFforISO15693tunnelEvent: (int) delay timeout: (int) timeout
{
    NSString *rfForIsoEvent = [NSString stringWithFormat: @"RFforISO15693tunnel: delay = %d, timeout = %d", delay, timeout];
    [self appendTextToBuffer: rfForIsoEvent color: [UIColor whiteColor]];
}

-(void)ISO15693optionBitsEvent: (int) option_bits
{
    NSString *ISO15693optionBits = [NSString stringWithFormat: @"ISO15693optionBits: bits = %d", option_bits];
    [self appendTextToBuffer: ISO15693optionBits color: [UIColor whiteColor]];
}

-(void)ISO15693extensionFlagEvent: (bool) flag permanent: (bool) permanent
{
    NSString *ISO15693extensionFlag = [NSString stringWithFormat: @"ISO15693extensionFlag: flag = %@ permanent = %@", (flag == true? @"true":  @"false"), (permanent == true? @"true": @"false")];
    [self appendTextToBuffer: ISO15693extensionFlag color: [UIColor whiteColor]];
}

-(void)ISO15693bitrateEvent: (int) bitrate permanent: (bool) permanent
{
    NSString *ISO15693bitrate = [NSString stringWithFormat: @"ISO15693bitrate: bitrate = %d permanent = %@", bitrate, (permanent == true? @"true":  @"false")];
    [self appendTextToBuffer: ISO15693bitrate color: [UIColor whiteColor]];
}

-(void)EPCfrequencyEvent: (int) frequency
{
    NSString *EPCfrequency = [NSString stringWithFormat: @"EPCfrequency: frequency = %d", frequency];
    [self appendTextToBuffer: EPCfrequency color: [UIColor whiteColor]];
}

-(void)tunnelEvent: (NSData *_Nonnull) data
{
    NSString *tunnelEvent = [NSString stringWithFormat: @"tunnelEvent: data = %@", [PassiveReader dataToString: data]];
    [self appendTextToBuffer: tunnelEvent color: [UIColor whiteColor]];
}

// AbstractInventoryListenerProtocol implementation
- (void)inventoryEvent:(Tag * _Nonnull)tag
{
    [self enableStartButton: true];
    [_tags addObject: tag];
    [self appendTextToBuffer: [NSString stringWithFormat: @"inventoryEvent tag: %@", [tag toString]] color: [UIColor whiteColor]];
}

// AbstractResponseListenerProtocol implementation
- (void)writeIDevent: (NSData *_Nonnull)tagID error:(int)error
{
    NSString *text;
    
    [self enableStartButton: true];
    text = [NSString stringWithFormat: @"writeIDevent tag: %@, error: %d", [PassiveReader dataToString: tagID], error];
    [self appendTextToBuffer: text error: error];
}

- (void)writePasswordEvent:(NSData *_Nonnull)tagID error:(int)error
{
    NSString *text;
    
    [self enableStartButton: true];
    text = [NSString stringWithFormat: @"writePasswordEvent tag: %@, error: %d", [PassiveReader dataToString: tagID], error];
    [self appendTextToBuffer: text error: error];
}

- (void)readTIDevent:(NSData *_Nonnull)tagID error:(int)error TID:(NSData *_Nullable)tid
{
    NSString *text;
    
    [self enableStartButton: true];
    text = [NSString stringWithFormat: @"readTIDevent tag: %@, error: %d, TID: %@", [PassiveReader dataToString: tagID], error, [PassiveReader dataToString: tid]];
    [self appendTextToBuffer: text error: error];
}

- (void)readEvent:(NSData *_Nonnull)tagID error:(int)error data: (NSData *_Nullable) data
{
    NSString *text;
    
    [self enableStartButton: true];
    text = [NSString stringWithFormat: @"readEvent tag: %@, error: %d, Data: %@", [PassiveReader dataToString: tagID], error, [PassiveReader dataToString: data]];
    [self appendTextToBuffer: text error: error];
}

- (void)writeEvent:(NSData *_Nonnull)tagID error:(int)error
{
    NSString *text;
    
    [self enableStartButton: true];
    text = [NSString stringWithFormat: @"writeEvent tag: %@, error: %d", [PassiveReader dataToString: tagID], error];
    [self appendTextToBuffer: text error: error];
}

- (void)lockEvent:(NSData *_Nonnull)tagID error:(int)error
{
    NSString *text;
    
    [self enableStartButton: true];
    text = [NSString stringWithFormat: @"lockEvent tag: %@, error: %d", [PassiveReader dataToString: tagID], error];
    [self appendTextToBuffer: text error: error];
}

- (void)killEvent:(NSData *_Nonnull)tagID error:(int)error
{
    NSString *text;
    
    [self enableStartButton: true];
    text = [NSString stringWithFormat: @"killEvent tag: %@, error: %d", [PassiveReader dataToString: tagID], error];
    [self appendTextToBuffer: text error: error];
}

//
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([[segue.destinationViewController class] isKindOfClass: [ExtendedTagTestsViewController class]]) {
		ExtendedTagTestsViewController *nextVC = (ExtendedTagTestsViewController *) segue.destinationViewController;
		nextVC.deviceDetailVC = self;
	}
}

-(void)unwindForSegue:(UIStoryboardSegue *)unwindSegue towardsViewController:(UIViewController *)subsequentVC
{
    [_timer invalidate];
    [_api disconnect];
    
    _eventsForwarder.readerListenerDelegate = nil;
    _eventsForwarder.inventoryListenerDelegate = nil;
    _eventsForwarder.responseListenerDelegate = nil;
}

-(IBAction)unwindToDeviceDetailViewController:(UIStoryboardSegue *) unwindSegue
{
    _eventsForwarder.readerListenerDelegate = self;
    _eventsForwarder.inventoryListenerDelegate = self;
    _eventsForwarder.responseListenerDelegate = self;
    
    _inExtendedView = false;
    if (_connected) {
        [self enableStartButton: true];
    }
}

@end
