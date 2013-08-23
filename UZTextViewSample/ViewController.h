//
//  ViewController.h
//  UZTextView
//
//  Created by sonson on 2013/06/16.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UZTextView.h"

@interface ViewController : UIViewController <UZTextViewDelegate>

@property (nonatomic, strong) IBOutlet UZTextView *textView;

@end
