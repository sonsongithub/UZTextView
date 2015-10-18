//
//  TextViewController.m
//  UZTextView
//
//  Created by sonson on 2015/10/16.
//  Copyright © 2015年 sonson. All rights reserved.
//

#import "TextViewController.h"

#import "UZTextView.h"

@interface TextViewController ()
@property (nonatomic, strong) IBOutlet UZTextView *textView;
@end

@implementation TextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *str = @"test\nte\nst\ntest\nwww\nUZTextView";
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:str];
//    [attr addAttribute:NSStrikethroughStyleAttributeName value:@(1) range:NSMakeRange(0, str.length)];
    [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:40] range:NSMakeRange(0, str.length)];
    [attr addAttribute:NSUnderlineStyleAttributeName value:@(1) range:NSMakeRange(0, 4)];
    [attr addAttribute:NSStrikethroughStyleAttributeName value:@(3) range:NSMakeRange(5, 4)];
    [attr addAttribute:NSBackgroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange(24, 4)];
    self.textView.attributedString = attr;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
