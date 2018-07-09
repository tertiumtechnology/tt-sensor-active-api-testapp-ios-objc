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
    
    if (pickerView == _pikSelectSensor) {
        pickerLabel.text = _sensors[row];
    } else {
        pickerLabel.text = operations[row];
    }
    
    pickerLabel.textColor = [UIColor blackColor];
    return pickerLabel;
}

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView
{
    return 1;
}

-(NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (pickerView == _pikSelectSensor) {
        return _sensors[row];
    } else {
        return operations[row];
    }
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == _pikSelectSensor) {
        return [_sensors count];
    } else {
        return sizeof(operations)/sizeof(NSString *);
    }
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (pickerView == _pikSelectSensor) {
        if (_sensorTypeCodes) {
            _sensorTypeName = sensorTypeStrings[@(_sensorTypeCodes[row])];
            _activeSensor = [_api getSensorByIndex: (int)row];
            _activeSensorIndex = (int)row;
        }
    } else {
        _selectedRow = row;
    }
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
    
    _commandSensor = _activeSensor;
    _commandSensorTypeName = sensorTypeStrings[@(_sensorTypeCodes[_activeSensorIndex])];
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

-(void)disconnectionSuccessEvent
{
    [self enableStartButton: false];
    _connected = false;
    [_btnConnect setTitle: @"CONNECT" forState: UIControlStateNormal];
    [_sensors removeAllObjects];
    [_pikSelectSensor reloadAllComponents];
    _activeSensor = nil;
}

-(void)firmwareVersionEvent: (int) major minor: (int) minor
{
    NSString *firmwareVersion;
    
    firmwareVersion = [NSString stringWithFormat: @"Firmware = %d.%d", major, minor];
    [self appendTextToBuffer: firmwareVersion color: [UIColor whiteColor]];
}

-(void)getClockEvent:(int)sensorTime systemTime:(int)systemTime
{
    if (!_inMultiCommand) {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Sensor time: %ds, System time: %ds", sensorTime, systemTime] color: [UIColor whiteColor]];
        [self enableStartButton: true];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_api setClock: systemTime+2 update_time: sensorTime+2];
        });
    }
}

- (void)getLoggedLocalizationDataEvent:(int)gpsError latitude:(float)latitude longitude:(float)longitude timestamp:(int)timestamp
{
    if (gpsError == ABSTRACT_SENSOR_LISTENER_NO_ERROR) {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Localization logged latitude/longitude: %f/%f@%d", latitude, longitude, timestamp] color: [UIColor whiteColor]];
    } else {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Localization logged error: %d", gpsError] color: [UIColor redColor]];
    }
    [self enableStartButton: true];
}

- (void)getLoggedMeasureDataEvent:(int)sensorType sensorValue:(float)sensorValue timestamp:(int)timestamp
{
    [self appendTextToBuffer: [NSString stringWithFormat: @"Sensor %@ logged value: %f@%d", _commandSensorTypeName, sensorValue, timestamp] color: [UIColor whiteColor]];
    [self enableStartButton: true];
}

- (void)getLoggedSealDataEvent:(bool)closed status:(int)status timestamp:(int)timestamp
{
    [self appendTextToBuffer: [NSString stringWithFormat: @"Seal logged closed status: %d and counter: %d@%d", closed, status, timestamp] color: [UIColor whiteColor]];
    [self enableStartButton: true];
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

// AbstractResponseListenerProtocol
- (void)calibrateSensorEvent:(int)sensorType error:(int)error
{
    if (error == ABSTRACT_SENSOR_LISTENER_NO_ERROR) {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Calibrate sensor %@ success", _commandSensorTypeName] color: [UIColor whiteColor]];
    } else {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Calibrate sensor %@ error: %d", _commandSensorTypeName, error] color: [UIColor redColor]];
    }
    
    [self enableStartButton: true];
}

- (void)getCalibrationConfigurationEvent:(int)sensorType error:(int)error uncalibratedRawValue:(int)uncalibratedRawValue valueOffset:(int)valueOffset valueGain:(float)valueGain fullScale:(int)fullScale
{
    if (error == ABSTRACT_SENSOR_LISTENER_NO_ERROR) {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Calibration configuration sensor %@ uncalibratedRawValue: %d valueOffset: %d valueGain: %f fullScale: %d", _commandSensorTypeName, uncalibratedRawValue, valueOffset, valueGain, fullScale] color: [UIColor whiteColor]];
    } else {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Calibration configuration sensor %@ error: %d", _commandSensorTypeName, error] color: [UIColor redColor]];
    }
    
    [self enableStartButton: true];
}

- (void)getLogConfigurationEvent:(int)sensorType error:(int)error logEnable:(bool)logEnable logPeriod:(int)logPeriod
{
    if (error == ABSTRACT_SENSOR_LISTENER_NO_ERROR) {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Log configuration sensor %@ enabled: %@ with period: %d", _commandSensorTypeName, (logEnable == true ? @"true": @"false"), logPeriod] color: [UIColor whiteColor]];
    } else {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Log configuration sensor %@ error: %d", _commandSensorTypeName, error] color: [UIColor redColor]];
    }
    
    [self enableStartButton: true];
}

- (void)logSensorEvent:(int)sensorType error:(int)error
{
    if (error == ABSTRACT_SENSOR_LISTENER_NO_ERROR) {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Log sensor %@ success", _commandSensorTypeName] color: [UIColor whiteColor]];
    } else {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Log sensor %@ error: %d", _commandSensorTypeName, error] color: [UIColor redColor]];
    }
    
    [self enableStartButton: true];
}

- (void)readLocalizationEvent:(int)error latitude:(float)latitude longitude:(float)longitude timestamp:(int)timestamp
{
    if (error == ABSTRACT_SENSOR_LISTENER_NO_ERROR) {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Read localization latitude/longitude: %f/%f@%d", latitude, longitude, timestamp] color: [UIColor whiteColor]];
    } else {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Read localization error: %d", error] color: [UIColor redColor]];
    }
    
    [self enableStartButton: true];
}

- (void)readMagneticSealStatusEvent:(int)error status:(int)status
{
    if (error == ABSTRACT_SENSOR_LISTENER_NO_ERROR) {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Magnetic seal status: %d", status] color: [UIColor whiteColor]];
    } else {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Magnetic seal status error: %d", error] color: [UIColor redColor]];
    }
    
    [self enableStartButton: true];
}

- (void)readOpticSealBackgroundEvent:(int)error backgroundLevel:(int)backgroundLevel
{
    if (error == ABSTRACT_SENSOR_LISTENER_NO_ERROR) {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Optical seal background level: %d", backgroundLevel] color: [UIColor whiteColor]];
    } else {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Optical seal read background level error: %d", error] color: [UIColor redColor]];
    }
    
    [self enableStartButton: true];
    
}

- (void)readOpticSealForegroundEvent:(int)error foregroundLevel:(int)foregroundLevel
{
    if (error == ABSTRACT_SENSOR_LISTENER_NO_ERROR) {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Optical seal foreground level: %d", foregroundLevel] color: [UIColor whiteColor]];
    } else {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Optical seal read foreground level error: %d", error] color: [UIColor redColor]];
    }
    
    [self enableStartButton: true];
}

- (void)readSealEvent:(int)error closed:(bool)closed status:(int)status
{
    if (error == ABSTRACT_SENSOR_LISTENER_NO_ERROR) {
        if (closed == true) {
            [self appendTextToBuffer: [NSString stringWithFormat: @"status closed@%d", status] color: [UIColor whiteColor]];
        } else {
            [self appendTextToBuffer: [NSString stringWithFormat: @"status open@%d", status] color: [UIColor whiteColor]];
        }
    } else {
        [self appendTextToBuffer: [NSString stringWithFormat: @"status read error: %d", error] color: [UIColor redColor]];
    }
    
    [self enableStartButton: true];
}

- (void)readSensorEvent:(int)sensorType error:(int)error sensorValue:(float)sensorValue timestamp:(int)timestamp
{
    if (error == ABSTRACT_SENSOR_LISTENER_NO_ERROR) {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Read sensor %@ value: %f@%d", _commandSensorTypeName, sensorValue, timestamp] color: [UIColor whiteColor]];
    } else {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Read sensor %@ error: %d", _commandSensorTypeName, error] color: [UIColor redColor]];
    }
    
    [self enableStartButton: true];
}

- (void)setupSealEvent:(int)error
{
    if (error == ABSTRACT_SENSOR_LISTENER_NO_ERROR) {
        [self appendTextToBuffer: @"Setup seal successfull" color: [UIColor whiteColor]];
    } else {
        [self appendTextToBuffer: [NSString stringWithFormat: @"Setup seal sensor error: %d", error] color: [UIColor redColor]];
    }
    
    [self enableStartButton: true];
}

//
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
-(void)unwindForSegue:(UIStoryboardSegue *)unwindSegue towardsViewController:(UIViewController *)subsequentVC
{
    [_timer invalidate];
    [_api disconnect];
    
    _eventsForwarder.sensorListenerDelegate = nil;
    _eventsForwarder.responseListenerDelegate = nil;
}

-(IBAction)unwindToDeviceDetailViewController:(UIStoryboardSegue *) unwindSegue
{
    _eventsForwarder.sensorListenerDelegate = self;
    _eventsForwarder.responseListenerDelegate = self;
    
    _inExtendedView = false;
    if (_connected) {
        [self enableStartButton: true];
    }
}

@end
