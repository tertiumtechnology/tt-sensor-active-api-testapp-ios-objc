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

#import "ExtendedTagTestsViewController.h"
#import "ExtendedTagTestsCell.h"

@interface ExtendedTagTestsViewController ()

@end

@implementation ExtendedTagTestsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    _txtResult.layer.borderColor = [[UIColor blueColor] CGColor];
    _txtResult.layer.borderWidth = 3.0;
    _lblHeader.text = _deviceName;
    _api = [PassiveReader getInstance];
    _resultsBuffer = [NSMutableAttributedString new];
    
    //
    _eventsForwarder = [EventsForwarder getInstance];
    _eventsForwarder.readerListenerDelegate = self;
    _eventsForwarder.inventoryListenerDelegate = self;
    _eventsForwarder.responseListenerDelegate = self;
    
    [_tblTags reloadData];
    [_tblTags selectRowAtIndexPath: [NSIndexPath indexPathForRow: 0 inSection: 0] animated: true scrollPosition: UITableViewScrollPositionNone];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)segChanged:(id)sender {
    [self.view endEditing:true];
    if (self.segChange.selectedSegmentIndex == 0) {
        self.btnStartOperation = _btnStartOperationRead;
        [self.cntRead setHidden: false];
        [self.cntWrite setHidden: true];
    } else if (self.segChange.selectedSegmentIndex == 1) {
        self.btnStartOperation = _btnStartOperationWrite;
        [self.cntRead setHidden: true];
        [self.cntWrite setHidden: false];
    }
}

-(Tag *) getSelectedTag
{
    return _tags[_selectedRow];
}

// UITableViewDataSource
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tags.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ExtendedTagTestsCell *cell;
    Tag* tag;
    
    cell = (ExtendedTagTestsCell *) [tableView dequeueReusableCellWithIdentifier: @"ExtendedTagTestsCell"];
    tag = (Tag *) _tags[indexPath.row];
    cell.lblTagID.text = [tag toString];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedRow = indexPath.row;
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

-(void)scrollDown: (UITextView *) textView
{
    NSRange range = NSMakeRange(textView.text.length - 1, 0);
    [textView scrollRangeToVisible: range];
}

-(void)appendText: (NSString *) text color: (UIColor *) color
{
    NSString *fmtText;
    
    fmtText = [NSString stringWithFormat: @"%@\r\n", text];
    [_resultsBuffer appendAttributedString: [[NSAttributedString alloc] initWithString: fmtText attributes: @{ NSForegroundColorAttributeName: color }]];
    _txtResult.attributedText = _resultsBuffer;
    [self scrollDown: _txtResult];
}

-(void)appendText: (NSString *) text error: (int) error
{
    [self appendText: text color: (error == 0 ? [UIColor whiteColor]: [UIColor redColor])];
}
                                   
// AbstractResponseListenerProtocol implementation
-(void)writeIDevent: (NSData *) tagID error: (int) error
{
    [self enableStartButton: true];
}

-(void)writePasswordEvent:(NSData *) tagID error: (int) error
{
    [self enableStartButton: true];
}

-(void)readTIDevent:(NSData *) tagID error: (int) error TID: (NSData *) TID
{
    [self enableStartButton: true];
}

-(void)readEvent:(NSData *) tagID error: (int) error data: (NSData *) data
{
    NSString *text;
    
    [self enableStartButton: true];
    text = [NSString stringWithFormat: @"readEvent tag: %@ error: %d data %@", [PassiveReader dataToString: tagID], error, [PassiveReader dataToString: data]];
    [self appendText: text error: error];
}

-(void)writeEvent:(NSData *) tagID error: (int) error
{
    NSString *text;
    
    [self enableStartButton: true];
    text = [NSString stringWithFormat: @"writeEvent tag: %@ error: %d", [PassiveReader dataToString: tagID], error];
    [self appendText: text error: error];
}

-(void)lockEvent:(NSData *) tagID error: (int) error
{
    [self enableStartButton: true];
}

-(void)killEvent:(NSData *) tagID error: (int) error
{
    [self enableStartButton: true];
}

// AbstractInventoryListenerProtocol implementation
-(void)inventoryEvent:(NSData *) tagID
{
    [self enableStartButton: true];
}

// AbstractReaderListenerProtocol implementation
-(void)connectionFailureEvent: (int) error
{
    [self.deviceDetailVC connectionFailureEvent: error];
    [self performSegueWithIdentifier: @"ExtendedTagTestsUnwindSegue" sender: self];
}

-(void)connectionSuccessEvent
{
}

-(void)disconnectionEvent
{
    [self.deviceDetailVC disconnectionEvent];
    [self performSegueWithIdentifier: @"ExtendedTagTestsUnwindSegue" sender: self];
}

-(void)availabilityEvent: (bool) available
{
}

-(void)resultEvent: (int) command error: (int) error
{
    [self enableStartButton: true];
    NSString *errStr = (error == 0 ? @"NO error": [NSString stringWithFormat: @"Error %d", error]);
    NSString *result = [NSString stringWithFormat: @"Result command = %d %@", command, errStr];
    [self appendText: result error: error];
}

-(void)batteryStatusEvent: (int) status
{
}

-(void)firmwareVersionEvent: (int) major minor: (int) minor
{
}

-(void)shutdownTimeEvent: (int) time
{
}

-(void)RFpowerEvent: (int) level mode: (int) mode
{
}

-(void)batteryLevelEvent: (float) level
{
}

-(void)RFforISO15693tunnelEvent: (int) delay timeout: (int) timeout
{
}

-(void)ISO15693optionBitsEvent: (int) option_bits
{
}

-(void)ISO15693extensionFlagEvent: (bool) flag permanent: (bool)permanent
{
}

-(void)ISO15693bitrateEvent: (int) bitrate permanent: (bool) permanent
{
}

-(void)EPCfrequencyEvent: (int) frequency
{
}

-(void)tunnelEvent: (NSData *) data
{
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    
    if ([segue.destinationViewController isKindOfClass: [ExtendedTagTestsReadVC class]]) {
        ExtendedTagTestsReadVC *childVC = (ExtendedTagTestsReadVC *) segue.destinationViewController;
        childVC.mainVC = self;
        self.extendedTagTestsReadVC = childVC;
    } else if ([segue.destinationViewController isKindOfClass: [ExtendedTagTestsWriteVC class]]) {
        ExtendedTagTestsWriteVC *childVC = (ExtendedTagTestsWriteVC *) segue.destinationViewController;
        childVC.mainVC = self;
        self.extendedTagTestsWriteVC = childVC;
    }
}

-(void)unwindForSegue:(UIStoryboardSegue *)unwindSegue towardsViewController:(UIViewController *)subsequentVC
{
}

-(IBAction)unwindToExtendedTagTestsViewController:(UIStoryboardSegue *) unwindSegue
{
}

@end
