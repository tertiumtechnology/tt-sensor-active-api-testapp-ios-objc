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
#import "DeviceDetailViewController.h"
#import "ExtendedTagTestsReadVC.h"
#import "ExtendedTagTestsWriteVC.h"
#import "PassiveAPI/PassiveReader.h"
#import "PassiveAPI/Tag.h"
#import "EventsForwarder.h"

@interface ExtendedTagTestsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, AbstractReaderListenerProtocol, AbstractResponseListenerProtocol, AbstractInventoryListenerProtocol>
{
    PassiveReader *_api;
    EventsForwarder *_eventsForwarder;
    NSMutableAttributedString *_resultsBuffer;
    NSInteger _selectedRow;
}

@property (weak, nonatomic) DeviceDetailViewController *deviceDetailVC;
@property (weak, nonatomic) ExtendedTagTestsReadVC *extendedTagTestsReadVC;
@property (weak, nonatomic) ExtendedTagTestsWriteVC *extendedTagTestsWriteVC;
@property (weak, nonatomic) UIButton *btnStartOperation;
@property (weak, nonatomic) UIButton *btnStartOperationRead;
@property (weak, nonatomic) UIButton *btnStartOperationWrite;

@property (weak, nonatomic) IBOutlet UILabel *lblHeader;
@property (weak, nonatomic) IBOutlet UITableView *tblTags;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segChange;
@property (weak, nonatomic) IBOutlet UIView *cntRead;
@property (weak, nonatomic) IBOutlet UIView *cntWrite;
@property (weak, nonatomic) IBOutlet UITextView *txtResult;

@property (nonatomic, strong) NSArray<Tag *> *tags;
@property (nonatomic, strong) NSString *deviceName;

-(Tag *) getSelectedTag;
-(void)enableStartButton: (bool) enabled;
-(void)appendText: (NSString *) text color: (UIColor *) color;
-(void)appendText: (NSString *) text error: (int) error;

@end
