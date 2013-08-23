//
//  TextCell.m
//  UZTextView
//
//  Created by sonson on 2013/07/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "TextCell.h"

#import "UZTextView.h"

@implementation TextCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)prepareForReuse {
	[super prepareForReuse];
	[self.textView prepareForReuse];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
