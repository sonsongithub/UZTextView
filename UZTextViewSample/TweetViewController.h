//
//  TweetViewController.h
//  UZTextView
//
//  Created by sonson on 2013/07/25.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UZTextView.h"

@class Tweet;

@interface TweetViewController : UIViewController <UZTextViewDelegate> {
	NSString *_URLString;
}
@property (nonatomic, strong) IBOutlet UZTextView *textView;
@property (nonatomic, strong) IBOutlet UIImageView *iconImageView;
@property (nonatomic, strong) IBOutlet UIButton *nameButton;
@property (nonatomic, strong) Tweet *tweet;
@end
