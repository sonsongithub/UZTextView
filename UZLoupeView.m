//
//  UZLoupeView.m
//  UZTextView
//
//  Created by sonson on 2013/07/10.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "UZLoupeView.h"

@implementation UZLoupeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self setBackgroundColor:[UIColor clearColor]];
	}
	return self;
}

- (void)update:(UIImage*)image {
	_image = image;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	[[self.tintColor colorWithAlphaComponent:0.75] setStroke];
	
	float radius = rect.size.width/2;
	
	CGContextAddArc(context, radius, radius, radius, 0, M_PI * 2, 0);
	CGContextClosePath(context);
	[[UIColor blackColor] setFill];
	CGContextDrawPath(context, kCGPathFill);
	
	CGContextSaveGState(context);
	CGContextAddArc(context, radius, radius, radius, 0, M_PI * 2, 0);
	CGContextClosePath(context);
	CGContextClip(context);
	[_image drawAtPoint:CGPointZero];
	CGContextRestoreGState(context);
	
	CGContextAddArc(context, radius, radius, radius, 0, M_PI * 2, 0);
	CGContextClosePath(context);
	CGContextDrawPath(context, kCGPathStroke);
}

@end
