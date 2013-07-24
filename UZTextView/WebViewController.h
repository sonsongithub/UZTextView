//
//  WebViewController.h
//  UZTextView
//
//  Created by sonson on 2013/07/25.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) NSURL *URL;

@end
