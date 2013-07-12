//
//  UZLoupeView.m
//  UZTextView
//
//  Created by sonson on 2013/07/10.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "UZLoupeView.h"

@implementation UZLoupeView

- (CAAnimation*)yAnimation {
	// size
	CAKeyframeAnimation *sizeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
	sizeAnimation.values = [NSArray arrayWithObjects:
							[NSNumber numberWithFloat:self.frame.size.height/2],
							[NSNumber numberWithFloat:0],
							nil];
	sizeAnimation.keyTimes = [NSArray arrayWithObjects:
							  [NSNumber numberWithFloat:0],
							  [NSNumber numberWithFloat:1],
							  nil];
	return sizeAnimation;
}

- (CAAnimation*)scaleAnimation {
	// size
	CAKeyframeAnimation *sizeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
	sizeAnimation.values = [NSArray arrayWithObjects:
							[NSNumber numberWithFloat:0],
							[NSNumber numberWithFloat:1],
							nil];
	sizeAnimation.keyTimes = [NSArray arrayWithObjects:
							  [NSNumber numberWithFloat:0],
							  [NSNumber numberWithFloat:1],
							  nil];
	return sizeAnimation;
}

- (void)animate {
	CAAnimation *sizeAnimation = [self scaleAnimation];
	CAAnimation *yAnimation = [self yAnimation];
	// make group
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.animations = @[sizeAnimation, yAnimation];
	group.duration = 0.1;
	group.removedOnCompletion = NO;
	group.fillMode = kCAFillModeForwards;
	group.delegate = self;
	
	// commit animation
	[self.layer addAnimation:group forKey:@"hoge"];
}

- (CAAnimation*)hideyAnimation {
	// size
	CAKeyframeAnimation *sizeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
	sizeAnimation.values = [NSArray arrayWithObjects:
							[NSNumber numberWithFloat:0],
							[NSNumber numberWithFloat:self.frame.size.height/2],
							nil];
	sizeAnimation.keyTimes = [NSArray arrayWithObjects:
							  [NSNumber numberWithFloat:0],
							  [NSNumber numberWithFloat:1],
							  nil];
	return sizeAnimation;
}

- (CAAnimation*)hidescaleAnimation {
	// size
	CAKeyframeAnimation *sizeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
	sizeAnimation.values = [NSArray arrayWithObjects:
							[NSNumber numberWithFloat:1],
							[NSNumber numberWithFloat:0],
							nil];
	sizeAnimation.keyTimes = [NSArray arrayWithObjects:
							  [NSNumber numberWithFloat:0],
							  [NSNumber numberWithFloat:1],
							  nil];
	return sizeAnimation;
}

- (void)hideanimate {
	CAAnimation *sizeAnimation = [self hidescaleAnimation];
	CAAnimation *yAnimation = [self hideyAnimation];
	// make group
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.animations = @[sizeAnimation, yAnimation];
	group.duration = 0.1;
	group.removedOnCompletion = NO;
	group.fillMode = kCAFillModeForwards;
	group.delegate = self;
	
	// commit animation
	[self.layer addAnimation:group forKey:@"hoge"];
}

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
	[[self.tintColor colorWithAlphaComponent:1] setStroke];
	
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
	
	CGContextSaveGState(context);
	CGContextSetLineWidth(context, 2);
	CGContextAddArc(context, radius, radius, radius-1, 0, M_PI * 2, 0);
	CGContextClosePath(context);
	CGContextDrawPath(context, kCGPathStroke);
	CGContextRestoreGState(context);
}

@end
