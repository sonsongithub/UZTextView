//
//  UZLoupeView.m
//  UZTextView
//
//  Created by sonson on 2013/07/10.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "UZLoupeView.h"

#define UZ_LOUPE_NO_ANIMATION_DUARTION	0.0001
#define UZ_LOUPE_ANIMATION_DUARTION		0.1
#define UZ_LOUPE_OUTLINE_STROKE_WIDTH	2

@implementation UZLoupeView

#pragma mark - Create Core Animation objects

- (CAAnimation*)translationYAnimationWhileAppearing {
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsPortrait(orientation)) {
		CAKeyframeAnimation *sizeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
		sizeAnimation.keyTimes = @[@(0), @(1)];
		if (orientation == UIInterfaceOrientationPortrait)
			sizeAnimation.values = @[@(self.frame.size.height/2), @(0)];
		else
			sizeAnimation.values = @[@(-self.frame.size.height/2), @(0)];
		return sizeAnimation;
	}
	else {
		CAKeyframeAnimation *sizeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
		sizeAnimation.keyTimes = @[@(0), @(1)];
		if (orientation == UIInterfaceOrientationLandscapeLeft)
			sizeAnimation.values = @[@(self.frame.size.width/2), @(0)];
		else
			sizeAnimation.values = @[@(-self.frame.size.width/2), @(0)];
		return sizeAnimation;
	}
}

- (CAAnimation*)transformScaleAnimationWhileAppearing {
	CAKeyframeAnimation *sizeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
	sizeAnimation.values = @[@(0), @(1)];
	sizeAnimation.keyTimes = @[@(0), @(1)];
	return sizeAnimation;
}

- (CAAnimation*)translationYAnimationWhileDisappearing {
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsPortrait(orientation)) {
		CAKeyframeAnimation *sizeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
		sizeAnimation.keyTimes = @[@(0), @(1)];
		if (orientation == UIInterfaceOrientationPortrait)
			sizeAnimation.values = @[@(0), @(self.frame.size.height/2)];
		else
			sizeAnimation.values = @[@(0), @(-self.frame.size.height/2)];
		return sizeAnimation;
	}
	else {
		CAKeyframeAnimation *sizeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
		sizeAnimation.keyTimes = @[@(0), @(1)];
		if (orientation == UIInterfaceOrientationLandscapeLeft)
			sizeAnimation.values = @[@(0), @(self.frame.size.width/2)];
		else
			sizeAnimation.values = @[@(0), @(-self.frame.size.width/2)];
		return sizeAnimation;
	}
}

- (CAAnimation*)transformScaleAnimationWhileDisapearing {
	CAKeyframeAnimation *sizeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
	sizeAnimation.values = @[@(1), @(0)];
	sizeAnimation.keyTimes = @[@(0), @(1)];
	return sizeAnimation;
}

#pragma mark - Animate

- (void)animateForAppearingWithDuration:(float)duration {
	// decide whether animation should be started or not
	if (!self.hidden)
		return;
	self.hidden = NO;
	
	// make animation group
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.animations = @[[self transformScaleAnimationWhileAppearing], [self translationYAnimationWhileAppearing]];
	group.duration = duration;
	group.removedOnCompletion = NO;
	group.fillMode = kCAFillModeForwards;
	group.delegate = self;
	
	// commit animation
	[self.layer addAnimation:group forKey:@"appear"];
}

- (void)animateForDisappearingWithDuration:(float)duration {
	// make group
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.animations = @[[self translationYAnimationWhileDisappearing], [self transformScaleAnimationWhileDisapearing]];
	group.duration = duration;
	group.removedOnCompletion = NO;
	group.fillMode = kCAFillModeForwards;
	group.delegate = self;
	
	// commit animation
	[self.layer addAnimation:group forKey:@"disappear"];
}

#pragma mark - Core Animation callback

- (void)animationDidStop:(CAAnimation*)animation finished:(BOOL)flag {
	if (animation == [self.layer animationForKey:@"appear"]) {
	}
	if (animation == [self.layer animationForKey:@"disappear"]) {
		self.hidden = YES;
	}
}

#pragma mark - Public

- (void)setVisible:(BOOL)visible animated:(BOOL)animated {
	float duration = animated ? UZ_LOUPE_ANIMATION_DUARTION : UZ_LOUPE_NO_ANIMATION_DUARTION;
	if (visible)
		[self animateForAppearingWithDuration:duration];
	else
		[self animateForDisappearingWithDuration:duration];
}

- (void)update:(UIImage*)image {
	_image = image;
	[self setNeedsDisplay];
}

#pragma mark - Override

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setBackgroundColor:[UIColor clearColor]];
		self.hidden = YES;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	[[self.tintColor colorWithAlphaComponent:1] setStroke];
	
	// draw back ground fill
	float radius = rect.size.width/2;
	CGContextAddArc(context, radius, radius, radius, 0, M_PI * 2, 0);
	CGContextClosePath(context);
	[[UIColor blackColor] setFill];
	CGContextDrawPath(context, kCGPathFill);
	
	// draw captured UZTextView bitmap
	CGContextSaveGState(context);
	CGContextAddArc(context, radius, radius, radius, 0, M_PI * 2, 0);
	CGContextClosePath(context);
	CGContextClip(context);
	[_image drawAtPoint:CGPointZero];
	CGContextRestoreGState(context);
	
	// draw outline stroke
	CGContextSaveGState(context);
	CGContextSetLineWidth(context, UZ_LOUPE_OUTLINE_STROKE_WIDTH);
	CGContextAddArc(context, radius, radius, radius-1, 0, M_PI * 2, 0);
	CGContextClosePath(context);
	CGContextDrawPath(context, kCGPathStroke);
	CGContextRestoreGState(context);
}

@end
