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

#import "SettingsViewController.h"
#import "PassiveAPI/BleSettings.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    _bleSettings = [BleSettings getInstance];
    _txtConnectTimeout.text = [[NSNumber numberWithInteger: [_bleSettings getTimeOutValue: S_TERTIUM_TIMEOUT_CONNECT]] stringValue];
    _txtWriteTimeout.text = [[NSNumber numberWithInteger: [_bleSettings getTimeOutValue: S_TERTIUM_TIMEOUT_SEND_PACKET]] stringValue];
    _txtFirstReadTimeout.text = [[NSNumber numberWithInteger: [_bleSettings getTimeOutValue: S_TERITUM_TIMEOUT_RECEIVE_FIRST_PACKET]] stringValue];
    _txtLaterReadTimeout.text = [[NSNumber numberWithInteger: [_bleSettings getTimeOutValue: S_TERTIUM_TIMEOUT_RECEIVE_PACKETS]] stringValue];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing: YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [_bleSettings setTimeOutValue: [_txtConnectTimeout.text integerValue] forTimeOutType: S_TERTIUM_TIMEOUT_CONNECT];
    [_bleSettings setTimeOutValue: [_txtWriteTimeout.text integerValue] forTimeOutType: S_TERTIUM_TIMEOUT_SEND_PACKET];
    [_bleSettings setTimeOutValue: [_txtFirstReadTimeout.text integerValue] forTimeOutType: S_TERITUM_TIMEOUT_RECEIVE_FIRST_PACKET];
    [_bleSettings setTimeOutValue: [_txtLaterReadTimeout.text integerValue] forTimeOutType: S_TERTIUM_TIMEOUT_RECEIVE_PACKETS];
}

@end
