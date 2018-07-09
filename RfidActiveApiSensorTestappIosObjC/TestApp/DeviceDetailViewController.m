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

@implementation DeviceDetailViewController

static NSMutableArray* _initialCommandsMap = nil;
static NSMutableArray* _customCommandsMap = nil;

static NSString* const operations[] = {
                        @"Select Operation",
                        @"Test Availability",
                        @"Get Clock",
                        @"Set Clock",
                        @"Read all sensors",
                        @"Enable memory erase",
                        @"Erase memory",
                        @"Seek logged data",
                        @"Get logged data (from last seek, 3 record forward)",
                        @"Enable sensor log (60s)",
                        @"Disable sensor log",
                        @"Get current log configuration",
                        @"Get measure from measuring sensor",
                        @"Read measuring sensor",
                        @"Calibrate measuring sensor",
                        @"Get calibration configuration",
                        @"Setup optical sensor (fg_level 0, fg_tol 1000, bg_level 10000)",
                        @"Read optic foreground level for seal sensor",
                        @"Read optic background level for seal sensor",
                        @"Read seal sensor status",
                        @"Get localization from localization sensor",
                        @"Read localization sensor"
                    };

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //
    sensorTypeStrings = @{
                                               @ABSTRACT_SENSOR_BATTERY_CHARGE_SENSOR: @"Battery charge sensor",
                                               @ABSTRACT_SENSOR_DISPLACEMENT_TRANSDUCER_SENSOR_1: @"Displacement transducer sensor type 1",
                                               @ABSTRACT_SENSOR_INTERNAL_TEMPERATURE_SENSOR_1: @"Internal temperature sensor type 1",
                                               @ABSTRACT_SENSOR_EXTERNAL_TEMPERATURE_SENSOR_1: @"External temperature sensor type 1",
                                               @ABSTRACT_SENSOR_OXYGEN_5_PERCENT_SENSOR: @"Oxygen sensor type (5%)",
                                               @ABSTRACT_SENSOR_OXYGEN_25_PERCENT_SENSOR: @"Oxygen sensor type (25%)",
                                               @ABSTRACT_SENSOR_OBSOLETE_TEMPERATUTE_SENSOR: @"Obsolete temperature sensor type",
                                               @ABSTRACT_SENSOR_OPTIC_EMITTER_ON_SENSOR: @"Optic sensor type",
                                               @ABSTRACT_SENSOR_OPTIC_EMITTER_OFF_OR_MAGNETIC_SENSOR: @"Optic / Magnetic sensor type",
                                               @ABSTRACT_SENSOR_ELECTRONIC_SEAL_SENSOR: @"Electronic seal sensor type",
                                               @ABSTRACT_SENSOR_TEMPERATURE_SENSOR: @"Temperature sensor type",
                                               @ABSTRACT_SENSOR_RELATIVE_HUMIDITY_SENSOR: @"Relative humidity sensor type",
                                               @ABSTRACT_SENSOR_ATMOSPHERIC_PRESSURE_SENSOR: @"Atmospheric pressure sensor type",
                                               @ABSTRACT_SENSOR_PRESSURE_SENSOR: @"Pressure sensor type",
                                               @ABSTRACT_SENSOR_CURRENT_SENSOR: @"Current sensor type",
                                               @ABSTRACT_SENSOR_LEM_CURRENT_SENSOR: @"LEM current sensor type",
                                               @ABSTRACT_SENSOR_DISPLACEMENT_TRANSDUCER_SENSOR_2: @"Displacement transducer sensor type 2",
                                               @ABSTRACT_SENSOR_INTERNAL_TEMPERATURE_SENSOR_2: @"Internal temperature sensor type 2",
                                               @ABSTRACT_SENSOR_EXTERNAL_TEMPERATURE_SENSOR_2: @"External temperature sensor type 2",
                                               @ABSTRACT_SENSOR_LOCALIZATION_LATITUDE_SENSOR_0: @"Localization latitude sensor type",
                                               @ABSTRACT_SENSOR_LOCALIZATION_LATITUDE_SENSOR_1: @"Localization latitude sensor type",
                                               @ABSTRACT_SENSOR_LOCALIZATION_LONGITUDE_SENSOR_0: @"Localization longitude sensor type",
                                               @ABSTRACT_SENSOR_LOCALIZATION_LONGITUDE_SENSOR_1: @"Localization longitude sensor type",
                                               @ABSTRACT_SENSOR_INCLINOMETER_AXIS_X_SENSOR: @"Inclinometer axis Y sensor type",
                                               @ABSTRACT_SENSOR_INCLINOMETER_AXIS_Y_SENSOR: @"Inclinometer axis X sensor type",
                                               @ABSTRACT_SENSOR_PIEZOMETRIC_PRESSURE_SENSOR: @"Piezometric pressure sensor type",
                                               @ABSTRACT_SENSOR_LOAD_CELL_SENSOR: @"Load cell sensor type",
                                               };
    
    // Do any additional setup after loading the view.
    _api = [ActiveSensor getInstance];
	_eventsForwarder = [EventsForwarder getInstance];
    _eventsForwarder.responseListenerDelegate = self;
    _eventsForwarder.sensorListenerDelegate = self;

    //
    _font = [UIFont fontWithName: @"Terminal" size: 10.0];
    
    //
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
    _inMultiCommand = false;
    _activeSensor = nil;
    _sensors = [NSMutableArray new];
    
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
    [_sensors removeAllObjects];
}

-(void)callNextInitialOperation
{
    if (!_initialCommandsMap) {
        _initialCommandsMap = [NSMutableArray new];
        [_initialCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc appendTextToBuffer: @"getFirmwareVersion" color: [UIColor yellowColor]];
            [vc->_api getFirmwareVersion];
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
            [vc appendTextToBuffer: @"Test availability" color: [UIColor yellowColor]];
        }];
        
        // Get Clock
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api getClock];
            [vc appendTextToBuffer: @"Get Clock" color: [UIColor yellowColor]];
        }];

        // // Set Clock
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            vc->_inMultiCommand = true;
            [vc->_api getClock];
            [vc appendTextToBuffer: @"Set Clock" color: [UIColor yellowColor]];
        }];

        // Read all sensors
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api readAllSensors];
            [vc appendTextToBuffer: @"Read all sensors" color: [UIColor yellowColor]];
        }];

        // Enable memory erase
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api enableMemoryErase];
            [vc appendTextToBuffer: @"Enable memory erase" color: [UIColor yellowColor]];
        }];

        // // Erase memory
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api eraseMemory];
            [vc appendTextToBuffer: @"Erase memory" color: [UIColor yellowColor]];
        }];

        // Seek logged data
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api seekLoggedData: 1];
            [vc appendTextToBuffer: @"Seek logged data" color: [UIColor yellowColor]];
        }];
        
        // // Get logged data
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc->_api getLoggedData: 3 backward: false];
            [vc appendTextToBuffer: @"Get logged data" color: [UIColor yellowColor]];
        }];
        
        // Enable log sensor
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (self->_activeSensor == nil) {
                [vc appendTextToBuffer: @"Select a sensor first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }

            [vc appendTextToBuffer: @"Enable log sensor" color: [UIColor yellowColor]];
            [vc appendTextToBuffer: [NSString stringWithFormat: @"Enabling log for sensor: %@", vc->_sensorTypeName] color: [UIColor whiteColor]];
            [self->_activeSensor logSensor: true acquisitionPeriod: 60];
        }];

        // Disable log sensor
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (self->_activeSensor == nil) {
                [vc appendTextToBuffer: @"Select a sensor first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }

            [vc appendTextToBuffer: @"Disable log sensor" color: [UIColor yellowColor]];
            [vc appendTextToBuffer: [NSString stringWithFormat: @"Disabling log for sensor: %@", vc->_sensorTypeName] color: [UIColor whiteColor]];
            [self->_activeSensor logSensor: false acquisitionPeriod: 1];
        }];
        
        // Get current Log Configuration
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (self->_activeSensor == nil) {
                [vc appendTextToBuffer: @"Select a sensor first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }

            [vc appendTextToBuffer: @"Get current log configuration" color: [UIColor yellowColor]];
            [vc appendTextToBuffer: [NSString stringWithFormat: @"Retreiving log configuration for sensor: %@", vc->_sensorTypeName] color: [UIColor whiteColor]];
            [self->_activeSensor getLogConfiguration];
        }];
        
        // Get measure from measuring sensor
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc enableStartButton: true];
            if (self->_activeSensor == nil) {
                [vc appendTextToBuffer: @"Select a sensor first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
            
            [vc appendTextToBuffer: @"Get measure from measuring sensor" color: [UIColor yellowColor]];
            if ([self->_activeSensor isKindOfClass: [MeasuringSensor class]]) {
                MeasuringSensor *sensor = (MeasuringSensor *) self->_activeSensor;
                if ([sensor getMeasureValidity] == true) {
                    [vc appendTextToBuffer: [NSString stringWithFormat: @"measure value: %f@%d", [sensor getMeasureValue], [sensor getMeasureTimestamp]] color: [UIColor whiteColor]];
                } else {
                    [vc appendTextToBuffer: @"Sensor measure invalid" color: [UIColor redColor]];
                }
            } else {
                [vc appendTextToBuffer: @"Invalid command for this kind of sensor (not measuring sensor)" color: [UIColor redColor]];
                return;
            }
        }];
        
        // Read measuring sensor
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (self->_activeSensor == nil) {
                [vc appendTextToBuffer: @"Select a sensor first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
            
            [vc appendTextToBuffer: @"Read measuring sensor" color: [UIColor yellowColor]];
            if ([self->_activeSensor isKindOfClass: [MeasuringSensor class]]) {
                MeasuringSensor *sensor = (MeasuringSensor *) self->_activeSensor;
                [vc appendTextToBuffer: [NSString stringWithFormat: @"Reading measuring sensor: %@", vc->_sensorTypeName] color: [UIColor whiteColor]];
                [sensor readSensor];
            } else {
                [vc appendTextToBuffer: @"Invalid command for this kind of sensor (not measuring sensor)" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
        }];
        
        // Calibrate measuring sensor (offset 0, gain 1, scale 25)
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (self->_activeSensor == nil) {
                [vc appendTextToBuffer: @"Select a sensor first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }

            [vc appendTextToBuffer: @"Calibrate measuring sensor (offset 0, gain 1, scale 25)" color: [UIColor yellowColor]];
            if ([self->_activeSensor isKindOfClass: [MeasuringSensor class]]) {
                MeasuringSensor *sensor = (MeasuringSensor *) self->_activeSensor;
                [vc appendTextToBuffer: [NSString stringWithFormat: @"Calibrating measuring sensor: %@", vc->_sensorTypeName] color: [UIColor whiteColor]];
                [sensor calibrateSensor: 0 valueGain: 1 fullScale: 25];
            } else {
                [vc appendTextToBuffer: @"Invalid command for this kind of sensor (not measuring sensor)" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
        }];

        // Get Calibration Configuration from Measuring Sensor
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (self->_activeSensor == nil) {
                [vc appendTextToBuffer: @"Select a sensor first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }

            [vc appendTextToBuffer: @"Get Calibration Configuration from Measuring Sensor" color: [UIColor yellowColor]];
            if ([self->_activeSensor isKindOfClass: [MeasuringSensor class]]) {
                MeasuringSensor *sensor = (MeasuringSensor *) self->_activeSensor;
                [vc appendTextToBuffer: [NSString stringWithFormat: @"Getting calibrationg configuration for measuring sensor: %@", vc->_sensorTypeName] color: [UIColor whiteColor]];
                [sensor getCalibrationConfiguration];
            } else {
                [vc appendTextToBuffer: @"Invalid command for this kind of sensor (not measuring sensor)" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
        }];
        
        // Setup optical seal sensor (fg_level 0, fg_tolerance 1000...)
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (self->_activeSensor == nil) {
                [vc appendTextToBuffer: @"Select a sensor first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
            
            [vc appendTextToBuffer: @"Setup optical seal sensor (fg_level 0, fg_tolerance 1000...)" color: [UIColor yellowColor]];
            if ([self->_activeSensor isKindOfClass: [SealSensor class]]) {
                SealSensor *sensor = (SealSensor *) self->_activeSensor;
                [vc appendTextToBuffer: [NSString stringWithFormat: @"Setting up optical seal sensor: %@", vc->_sensorTypeName] color: [UIColor whiteColor]];
                [sensor setupOpticSeal: 0 foregroundTolerance: 1000 backgroundLevel: 1000];
            } else {
                [vc appendTextToBuffer: @"Invalid command for this kind of sensor (not seal sensor)" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
        }];
        
        // Read optic foreground level for Seal Sensors
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (self->_activeSensor == nil) {
                [vc appendTextToBuffer: @"Select a sensor first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }

            [vc appendTextToBuffer: @"Read optic foreground level for Seal Sensors" color: [UIColor yellowColor]];
            if ([self->_activeSensor isKindOfClass: [SealSensor class]]) {
                SealSensor *sensor = (SealSensor *) self->_activeSensor;
                [vc appendTextToBuffer: [NSString stringWithFormat: @"Reading optic foreground level for seal sensor: %@", vc->_sensorTypeName] color: [UIColor whiteColor]];
                [sensor readOpticSealForeground];
            } else {
                [vc appendTextToBuffer: @"Invalid command for this kind of sensor (not seal sensor)" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
        }];
        
        // Read optic background level for Seal Sensors
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (self->_activeSensor == nil) {
                [vc appendTextToBuffer: @"Select a sensor first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
            
            [vc appendTextToBuffer: @"Read optic background level for Seal Sensors" color: [UIColor yellowColor]];
            if ([self->_activeSensor isKindOfClass: [SealSensor class]]) {
                SealSensor *sensor = (SealSensor *) self->_activeSensor;
                [vc appendTextToBuffer: [NSString stringWithFormat: @"Reading optic background level for seal sensor: %@", vc->_sensorTypeName] color: [UIColor whiteColor]];
                [sensor readOpticSealBackground];
            } else {
                [vc appendTextToBuffer: @"Invalid command for this kind of sensor (not seal sensor)" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
        }];
        
        // Read seal sensor status
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (self->_activeSensor == nil) {
                [vc appendTextToBuffer: @"Select a sensor first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
            
            [vc appendTextToBuffer: @"Read seal sensor status" color: [UIColor yellowColor]];
            if ([self->_activeSensor isKindOfClass: [SealSensor class]]) {
                SealSensor *sensor = (SealSensor *) self->_activeSensor;
                [vc appendTextToBuffer: [NSString stringWithFormat: @"Reading status for seal sensor: %@", vc->_sensorTypeName] color: [UIColor whiteColor]];
                [sensor readSeal];
            } else {
                [vc appendTextToBuffer: @"Invalid command for this kind of sensor (not seal sensor)" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
        }];
        
        // Get localization from localization sensor
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            [vc enableStartButton: true];
            if (self->_activeSensor == nil) {
                [vc appendTextToBuffer: @"Select a sensor first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
            
            [vc appendTextToBuffer: @"Get localization from localization sensor" color: [UIColor yellowColor]];
            if ([self->_activeSensor isKindOfClass: [LocalizationSensor class]]) {
                LocalizationSensor *sensor = (LocalizationSensor *) self->_activeSensor;
                [vc appendTextToBuffer: [NSString stringWithFormat: @"Reading localization from localization sensor: %@", vc->_sensorTypeName] color: [UIColor whiteColor]];
                if ([sensor getLocalizationValidity] == true) {
                    [vc appendTextToBuffer: [NSString stringWithFormat: @"Localization data for localization sensor: %f %f", [sensor getLongitudeValue], [sensor getLatitudeValue]] color: [UIColor whiteColor]];
                } else {
                    [vc appendTextToBuffer: [NSString stringWithFormat: @"Localization error for localization sensor: %@", vc->_sensorTypeName] color: [UIColor redColor]];
                }
            } else {
                [vc appendTextToBuffer: @"Invalid command for this kind of sensor (not localization sensor)" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }
        }];
        
        // Read localization sensor
        [_customCommandsMap addObject: ^(DeviceDetailViewController*vc) {
            if (self->_activeSensor == nil) {
                [vc appendTextToBuffer: @"Select a sensor first!" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
            }

            [vc appendTextToBuffer: @"Read localization sensor" color: [UIColor yellowColor]];
            if ([self->_activeSensor isKindOfClass: [LocalizationSensor class]]) {
                LocalizationSensor *sensor = (LocalizationSensor *) self->_activeSensor;
                [vc appendTextToBuffer: [NSString stringWithFormat: @"Reading localization sensor: %@", vc->_sensorTypeName] color: [UIColor whiteColor]];
                [sensor readLocalization];
            } else {
                [vc appendTextToBuffer: @"Invalid command for this kind of sensor (not localization sensor)" color: [UIColor redColor]];
                [vc enableStartButton: true];
                return;
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
    if (_connected && _inExtendedView == false && _inMultiCommand == false && _btnStartOperation.isEnabled == true && _currentInitialOperation >= _maxInitialOperations) {
        if (_repeatingCommandIndex >= 1)
            _repeatingCommandIndex = 0;

        _lastCommandType = repeatingCommand;
        [self enableStartButton: false];
        
        if (_repeatingCommandIndex == 0) {
            [_api testAvailability];
            _lastRepeatingCommand = ABSTRACT_SENSOR_LISTENER_TEST_AVAILABILITY_COMMAND;
        }
        
        _repeatingCommandIndex = _repeatingCommandIndex + 1;
    }
}
- (IBAction)selfcallCustomOperation_selectedRowbtnStartOperationPressed:(id)sender {
    [self callCustomOperation: (int)_selectedRow];
}

// AbstractSensorListenerProtocol implementation
-(void)availabilityEvent: (bool) available
{
    _deviceAvailable = available;
    [self updateBatteryLabel];
    [self appendTextToBuffer: [NSString stringWithFormat: @"availabilityEvent %@", (available ? @"yes": @"no")] color: [UIColor whiteColor] command: ABSTRACT_SENSOR_LISTENER_TEST_AVAILABILITY_COMMAND];
}

-(void)connectionFailureEvent: (int) error
{
    UIAlertView *alertView;
    _connected = false;
    
    alertView = [[UIAlertView alloc] initWithTitle: @"Connection failed!" message: @"error" delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
    [alertView show];
}

-(void)connectionSuccessEvent
{
    [self appendTextToBuffer: @"Successfull connection" color: [UIColor whiteColor]];
    [self enableStartButton: true];
    _connected = true;
    [_btnConnect setTitle: @"DISCONNECT" forState: UIControlStateNormal];
    [self appendTextToBuffer: [NSString stringWithFormat: @"%d sensors found", [_api getSensorsNumber]] color: [UIColor whiteColor]];
    _sensorTypeCodes = [_api getSensorsTypes];
    [_sensors removeAllObjects];
    for (int i = 0; i < [_api getSensorsNumber]; i++) {
        NSString *sensorType = sensorTypeStrings[@(_sensorTypeCodes[i])];
        [self appendTextToBuffer: [NSString stringWithFormat: @"Found %@", sensorType] color: [UIColor whiteColor]];
        [_sensors addObject: sensorType];
    }
    
    if ([_api getSensorsNumber] > 0) {
        _activeSensor = [_api getSensorByIndex: 0];
        _sensorTypeName = sensorTypeStrings[@(_sensorTypeCodes[0])];
    }
    
    [_pikSelectSensor reloadAllComponents];
    [self pushCommands];
}

-(void)disconnectionEvent
{
    [self enableStartButton: false];
    _connected = false;
    [_btnConnect setTitle: @"CONNECT" forState: UIControlStateNormal];
}

-(void)resultEvent: (int) command error: (int) error
{
    NSString *result, *errStr;
    errStr = (error == 0 ? @"NO error": [NSString stringWithFormat: @"Error %d", error]);
    result = [NSString stringWithFormat: @"Result command = %d %@", command, errStr];
    [self appendTextToBuffer: result error: error];
    if (_inMultiCommand) {
        if (command == 7) {
            _inMultiCommand = false;
            [self enableStartButton: true];
        }
    } else {
        [self enableStartButton: true];
    }
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
