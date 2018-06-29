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

#import "ScanViewController.h"
#import "BleTableViewHeaderCell.h"
#import "BleTableViewDeviceCell.h"
#import "DeviceDetailViewController.h"
#import "TxRxLib/TxRxManagerErrors.h"
#import "PassiveAPI/AbstractScanListener.h"

@interface ScanViewController ()

@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    _scannedDevices = [NSMutableArray new];
	_scanner = [Scanner getInstance];
    _scanner.delegate = self;
}

-(void)dealloc
{
    // Remove from notification
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 1;
    else
        return _scannedDevices.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0) {
        BleTableViewHeaderCell* cell;
        
        cell = [tableView dequeueReusableCellWithIdentifier: @"HeaderCell"];
        _btnScan = cell.scanButton;
        _defaultColor = cell.backgroundColor;
        return cell;
    } else {
        BleTableViewDeviceCell* cell;
        
        cell = [tableView dequeueReusableCellWithIdentifier: @"DeviceCell"];
        [cell.deviceLabel setText: (NSString *) _scannedDevices[indexPath.row]];
        return cell;
    }
}

- (IBAction)btnScanPressed:(id)sender
{
	if ([_scanner isScanning] == false) {
		[_scannedDevices removeAllObjects];
		[_scanner startScan];
	} else {
		[_scanner stopScan];
	}
}

// AbstractScanListenerProtocol implementation
-(void)deviceFoundEvent: (NSString *) deviceName
{
    [_scannedDevices addObject: deviceName];
    [_devicesTableView reloadData];
}

- (void)deviceScanBeganEvent
{
    [_btnScan setTitle: @"STOP" forState: UIControlStateNormal];
    [_devicesTableView reloadData];
}

- (void)deviceScanEndedEvent
{
    [_btnScan setTitle: @"SCAN" forState: UIControlStateNormal];
}

- (void)deviceScanErrorEvent:(NSError *)error
{
    UIAlertView* alertView;
	
    alertView = [[UIAlertView alloc] initWithTitle: @"DeviceScanError" message: error.localizedDescription delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
	[alertView show];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: @"DetailView"]) {
        NSInteger row = [_devicesTableView indexPathForSelectedRow].row;
        DeviceDetailViewController* detail;
        detail = (DeviceDetailViewController*) [segue destinationViewController];
        detail.deviceName = (NSString *) _scannedDevices[row];
        if (_scanner.isScanning) {
            [_scanner stopScan];
        }
    }
}

-(IBAction)unwindToScanController:(UIStoryboardSegue *) unwindSegue
{
}

@end
