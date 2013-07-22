//
//  RootViewController.h
//  UZTextView
//
//  Created by sonson on 2013/07/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UZTextView.h"

@interface RootViewController : UITableViewController <UZTextViewDelegate> {
	NSArray *_tweets;
}

@end
