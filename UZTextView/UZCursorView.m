//
//  UZCursorView.m
//  UZTextView
//
//  Created by sonson on 2013/07/19.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "UZCursorView.h"

#define UZ_CURSOR_BALL_RADIUS	6
#define UZ_CURSOR_POLE_WIDTH	2

#define UZ_CURSOR_HORIZONTAL_MARGIN 10
#define UZ_CURSOR_VERTICAL_MARGIN 10

@implementation UZCursorView

+ (CGRect)cursorRectWithEdgeRect:(CGRect)rect cursorDirection:(UZTextViewCursorDirection)direction {
	if (direction == UZTextViewUpCursor) {
		return CGRectMake(rect.origin.x - UZ_CURSOR_BALL_RADIUS - UZ_CURSOR_HORIZONTAL_MARGIN,
						  rect.origin.y - UZ_CURSOR_VERTICAL_MARGIN,
						  UZ_CURSOR_HORIZONTAL_MARGIN + UZ_CURSOR_BALL_RADIUS * 2,
						  rect.size.height + UZ_CURSOR_VERTICAL_MARGIN * 2);
	}
	else {
		return CGRectMake(rect.origin.x - UZ_CURSOR_BALL_RADIUS,
						  rect.origin.y - UZ_CURSOR_VERTICAL_MARGIN,
						  UZ_CURSOR_HORIZONTAL_MARGIN + UZ_CURSOR_BALL_RADIUS * 2,
						  rect.size.height + UZ_CURSOR_VERTICAL_MARGIN * 2);
	}
}

- (id)initWithCursorDirection:(UZTextViewCursorDirection)direction {
	self = [super initWithFrame:CGRectZero];
	_direction = direction;
	self.backgroundColor = [UIColor clearColor];
	
	// for debug
	self.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
	
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
		circleCenter = CGPointMake(rect.size.width - UZ_CURSOR_BALL_RADIUS, rect.origin.y + UZ_CURSOR_BALL_RADIUS);
		lineRect = CGRectMake(
							  circleCenter.x - UZ_CURSOR_POLE_WIDTH/2, circleCenter.y,
							  UZ_CURSOR_POLE_WIDTH, rect.size.height - circleCenter.y
							  );
	}
	else {
		circleCenter = CGPointMake(UZ_CURSOR_BALL_RADIUS, rect.origin.y + rect.size.height - UZ_CURSOR_BALL_RADIUS);
		lineRect = CGRectMake(
							  circleCenter.x - UZ_CURSOR_POLE_WIDTH/2, rect.origin.y,
							  UZ_CURSOR_POLE_WIDTH, rect.origin.y + rect.size.height
							  );
	}
	CGContextAddArc(context, circleCenter.x, circleCenter.y, UZ_CURSOR_BALL_RADIUS, 0, 2 * M_PI, 0);
	CGContextClosePath(context);
	[[self.tintColor colorWithAlphaComponent:1] setFill];
	CGContextFillPath(context);
	CGContextFillRect(context, lineRect);
}

@end
