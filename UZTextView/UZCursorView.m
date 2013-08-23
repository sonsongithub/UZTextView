//
//  UZCursorView.m
//  UZTextView
//
//  Created by sonson on 2013/07/19.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "UZCursorView.h"

@implementation UZCursorView

- (id)initWithCursorDirection:(UZTextViewCursorDirection)direction {
	self = [super initWithFrame:CGRectZero];
	_direction = direction;
	_cursorCirclrRadius = 6;
	_cursorLineWidth = 2;
	self.backgroundColor = [UIColor clearColor];
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGRect lineRect;
	CGPoint circleCenter;
	
	if (_direction == UZTextViewUpCursor) {
		circleCenter = CGPointMake(CGRectGetMidX(rect), rect.origin.y + _cursorCirclrRadius);
		lineRect = CGRectMake(
							  circleCenter.x - _cursorLineWidth/2, circleCenter.y,
							  _cursorLineWidth, rect.size.height - _cursorCirclrRadius * 2
							  );
	}
	else {
		circleCenter = CGPointMake(CGRectGetMidX(rect), rect.origin.y + rect.size.height - _cursorCirclrRadius);
		lineRect = CGRectMake(
							  circleCenter.x - _cursorLineWidth/2, rect.origin.y + _cursorCirclrRadius,
							  _cursorLineWidth, rect.size.height - _cursorCirclrRadius * 2
							  );
	}
	CGContextAddArc(context, circleCenter.x, circleCenter.y, _cursorCirclrRadius, 0, 2 * M_PI, 0);
	CGContextClosePath(context);
	[[self.tintColor colorWithAlphaComponent:1] setFill];
	CGContextFillPath(context);
	CGContextFillRect(context, lineRect);
}

@end
