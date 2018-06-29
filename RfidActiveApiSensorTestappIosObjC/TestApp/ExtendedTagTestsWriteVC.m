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

#import "ExtendedTagTestsWriteVC.h"
#import "ExtendedTagTestsViewController.h"
#import "PassiveAPI/EPC_tag.h"
#import "PassiveAPI/ISO15693_tag.h"
#import "PassiveAPI/ISO14443A_tag.h"

@interface ExtendedTagTestsWriteVC ()

@end

@implementation ExtendedTagTestsWriteVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSData*)hexStringToData: (NSString *) string {
    UInt8 array[string.length / 2];
    
    for (NSInteger i = 0; i < string.length / 2; i++) {
        array[i] = [PassiveReader hexToByte: [string substringWithRange: NSMakeRange(i*2, 2)]];
    }
    
    return [[NSData alloc] initWithBytes: array length: sizeof(array)/sizeof(UInt8)];
}

-(bool)isValidChar: (int) asciiCode {
    if (asciiCode >= 48 && asciiCode <= 57) {
        return true;
    }
    
    if (asciiCode >= 65 && asciiCode <= 70) {
        return true;
    }
    
    if (asciiCode >= 97 && asciiCode <= 102) {
        return true;
    }
    
    return false;
}

-(bool)verifyString: (NSString *) string {
    UInt8 cstring[string.length+1];
    
    strcpy((char*)cstring, [string UTF8String]);
    for (NSInteger i = 0; i < string.length; i++) {
        if ([self isValidChar: cstring[i]] == false)
            return false;
    }
    
    return true;
}

- (IBAction)btnWriteClicked:(id)sender {
    Tag *selectedTag;
    NSString *data;
    int address;
    
    [self.view endEditing: true];
    selectedTag = [_mainVC getSelectedTag];
    data = _txtData.text;
    if (_txtAddress.text != nil && _txtAddress.text.length) {
        if (data == nil || data.length == 0) {
            [_mainVC appendText: @"Empty data string!" color: [UIColor redColor]];
            return;
        }
        
        if ([self verifyString: data] == false) {
            [_mainVC appendText: @"Extraneous characters in data string, only 0-9, A-F accepted!" color: [UIColor redColor]];
            return;
        }
        
        if (data.length % 2 != 0) {
            [_mainVC appendText: @"Supplied data must be a string of hex values. Length must be even!" color: [UIColor redColor]];
            return;
        }
        
        address = (int)[_txtAddress.text integerValue];
        if ([selectedTag isKindOfClass: [ISO15693_tag class]]) {
            ISO15693_tag *tag = (ISO15693_tag *) selectedTag;
            if ((data.length / 2) % 4 == 0) {
                [tag setTimeout: 2000];
                [_mainVC enableStartButton: false];
                [tag write: address data: [self hexStringToData: data]];
                [_mainVC appendText: [NSString stringWithFormat: @"Writing %d blocks at address %d to tag %@", (int)data.length / 8, address, [tag toString]] color: [UIColor yellowColor]];
            } else {
                [_mainVC appendText: @"Error, data length must be multiple of four bytes" color: [UIColor redColor]];
            }
        } else if ([selectedTag isKindOfClass: [EPC_tag class]]) {
            EPC_tag *tag = (EPC_tag *) selectedTag;
            if ((data.length / 2) % 2 == 0) {
                [_mainVC enableStartButton: false];
                [tag write: address data: [self hexStringToData: data] password: nil];
                [_mainVC appendText: [NSString stringWithFormat: @"Writing %d blocks at address %d to tag %@", (int)data.length / 4, address, [tag toString]] color: [UIColor yellowColor]];
            } else {
                [_mainVC appendText: @"Error, data length must be multiple of two bytes" color: [UIColor redColor]];
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
