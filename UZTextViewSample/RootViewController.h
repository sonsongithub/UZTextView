//
//  RootViewController.h
//  UZTextView
//
//  Created by sonson on 2013/07/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UZTextView.h"

@interface RootViewController : UITableViewController <UZTextViewDelegate, UISearchBarDelegate> {
	NSArray *_tweets;
	NSString *_URLString;
	UIEdgeInsets _margin;
}

@end
