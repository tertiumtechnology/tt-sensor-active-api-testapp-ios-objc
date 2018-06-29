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

#import "ExtendedTagTestsReadVC.h"
#import "ExtendedTagTestsViewController.h"
#import "PassiveAPI/EPC_tag.h"
#import "PassiveAPI/ISO15693_tag.h"
#import "PassiveAPI/ISO14443A_tag.h"

@interface ExtendedTagTestsReadVC ()

@end

@implementation ExtendedTagTestsReadVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _mainVC.btnStartOperation = _btnStartOperation;
    _mainVC.btnStartOperationRead = _btnStartOperation;
    _api = [PassiveReader getInstance];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnReadClicked:(id)sender {
    int address, blocks;
    Tag *selectedTag;
    
    [self.view endEditing: true];
    selectedTag = [_mainVC getSelectedTag];
    if (_txtAddress.text != nil && _txtAddress.text.length) {
        if (_txtBlocks.text != nil && _txtBlocks.text.length) {
            address = (int)[_txtAddress.text integerValue];
            blocks = (int)[_txtBlocks.text integerValue];
            if ([selectedTag isKindOfClass: [ISO15693_tag class]]) {
                ISO15693_tag *tag = (ISO15693_tag *) selectedTag;
                [_mainVC enableStartButton: false];
                [tag setTimeout: 2000];
                [_mainVC appendText: [NSString stringWithFormat: @"Reading %d blocks at address %d from tag %@", blocks, address, [tag toString]] color: [UIColor yellowColor]];
                [tag read: address blocks: blocks];
            } else if ([selectedTag isKindOfClass: [EPC_tag class]]) {
                EPC_tag *tag = (EPC_tag *) selectedTag;
                [_mainVC enableStartButton: false];
                [_mainVC appendText: [NSString stringWithFormat: @"Reading %d blocks at address %d from tag %@", blocks, address, [tag toString]] color: [UIColor yellowColor]];
                [tag read: address blocks: blocks password: nil];
            }
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
