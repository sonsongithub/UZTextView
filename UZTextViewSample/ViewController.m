//
//  ViewController.m
//  UZTextView
//
//  Created by sonson on 2013/06/16.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "ViewController.h"

#import "UZTextView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)textView:(UZTextView* __nonnull)textView didLongTapLinkAttribute:(id __nullable)value {
}

- (void)selectionDidBeginTextView:(UZTextView*)textView {
}

- (void)selectionDidEndTextView:(UZTextView*)textView {
}

- (void)didTapTextDoesNotIncludeLinkTextView:(UZTextView*)textView {
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	NSString *string = @"hoge\rhoge\rhttp://www.yahoo.co.jp\r\rあれから吉田悠一012345678901234567890123456789012345678901234567890123456789hoge>>190";
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
	[attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Arial"size:20] range:NSMakeRange(0, string.length)];
	
	[attributedString addAttribute:NSLinkAttributeName value:@"http://www.yahoo.co.jp" range:NSMakeRange(10, 22)];
	[attributedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleNone) range:NSMakeRange(10, 22)];
	
	self.textView.attributedString = attributedString;
	self.textView.delegate = self;
}

- (void)textView:(UZTextView *)textview didClickLinkAttribute:(id)value {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Clicked"
														message:[value objectForKey:@"NSLink"]
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
	[alertView show];
}

@end
