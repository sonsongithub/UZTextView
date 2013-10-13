//
//  WebViewController.m
//  UZTextView
//
//  Created by sonson on 2013/07/25.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	[self.webView loadRequest:[NSURLRequest requestWithURL:self.URL]];
}

@end
