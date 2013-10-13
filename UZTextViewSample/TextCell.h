//
//  TextCell.h
//  UZTextView
//
//  Created by sonson on 2013/07/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UZTextView;

@interface TextCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *iconImageView;
@property (nonatomic, strong) IBOutlet UIButton	*nameButton;
@property (nonatomic, strong) IBOutlet UZTextView *textView;
@property (nonatomic, strong) NSURL *profileIconURL;

@end
