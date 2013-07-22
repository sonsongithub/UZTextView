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

#define UZCoreAnimationName (NSString*)_UZCoreAnimationName
#define UZLoupeViewAppearingAnimation (NSString*)_UZLoupeViewAppearingAnimation
#define UZLoupeViewDisappearingAnimation (NSString*)_UZLoupeViewDisappearingAnimation

const NSString *_UZCoreAnimationName = @"_UZCoreAnimationName";
const NSString *_UZLoupeViewAppearingAnimation = @"_UZLoupeViewAppearingAnimation";
const NSString *_UZLoupeViewDisappearingAnimation = @"_UZLoupeViewDisappearingAnimation";

@implementation UZLoupeView

#pragma mark - Update own content

- (void)updateUsingSuperViewAtLocationOnSuperview:(CGPoint)location {
}

- (void)updateUsingKeyWindowAtLocationOnSuperview:(CGPoint)location {
}

- (void)updateAtLocation:(CGPoint)location textView:(UIView*)textView {
	float loupeRadius = 50;

	if (_windowImage == nil) {
		// Create UIImage from source view controller's view.
		UIGraphicsBeginImageContextWithOptions([UIApplication sharedApplication].keyWindow.frame.size, NO, 0);
		CGContextRef ctx = UIGraphicsGetCurrentContext();
		CGContextScaleCTM(ctx, 1, 1);
		
		// Drawing code
		self.hidden = YES;
		[[UIApplication sharedApplication].keyWindow.layer renderInContext:ctx];
		self.hidden = NO;
		
		_windowImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}
	
	
	_windowImageOffset = [[UIApplication sharedApplication].keyWindow convertPoint:CGPointMake(location.x, location.y) fromView:textView];
	_windowImageOffset.x -= loupeRadius;
	_windowImageOffset.y -= loupeRadius;
	
	// Create UIImage from source view controller's view.
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(loupeRadius * 2, loupeRadius * 2), NO, 0);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(ctx, -location.x + loupeRadius, -location.y + loupeRadius);
	// Drawing code
	self.hidden = YES;
	[textView.layer renderInContext:ctx];
	self.hidden = NO;
	
	_image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	[self setNeedsDisplay];
	
	CGPoint c = [[UIApplication sharedApplication].keyWindow convertPoint:CGPointMake(location.x, location.y) fromView:textView];
	
	float offset = loupeRadius + 10;
	
	switch ([UIApplication sharedApplication].statusBarOrientation) {
		case UIInterfaceOrientationLandscapeLeft:
			c.x -= offset;
			break;
		case UIInterfaceOrientationLandscapeRight:
			c.x += offset;
			break;
		case UIInterfaceOrientationPortrait:
			c.y -= offset;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			c.y -= offset;
			break;
	}
	
	[self setBounds:CGRectMake(0, 0, 100, 100)];
	[self setCenter:c];
	[[UIApplication sharedApplication].keyWindow addSubview:self];
}

#pragma mark - Create Core Animation objects for appearing

- (CAAnimation*)alphaAnimationWhileAppearing {
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
	animation.values	= @[@(0), @(0.97), @(1)];
	animation.keyTimes	= @[@(0), @(0.7), @(1)];
	return animation;
}

- (CAAnimation*)transformScaleAnimationWhileAppearing {
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
	animation.values	= @[@(0), @(1)];
	animation.keyTimes	= @[@(0), @(1)];
	return animation;
}

- (CAAnimation*)translationAnimationWhileAppearing {
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	
	if (UIInterfaceOrientationIsPortrait(orientation)) {
		CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
		animation.keyTimes = @[@(0), @(1)];
		if (orientation == UIInterfaceOrientationPortrait)
			animation.values = @[@(self.frame.size.height/2), @(0)];
		else
			animation.values = @[@(-self.frame.size.height/2), @(0)];
		return animation;
	}
	else {
		CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
		animation.keyTimes = @[@(0), @(1)];
		if (orientation == UIInterfaceOrientationLandscapeLeft)
			animation.values = @[@(self.frame.size.width/2), @(0)];
		else
			animation.values = @[@(-self.frame.size.width/2), @(0)];
		return animation;
	}
}

#pragma mark - Create Core Animation objects for disappearing

- (CAAnimation*)alphaAnimationWhileDisappearing {
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
	animation.values	= @[@(1.0), @(0.97), @(0)];
	animation.keyTimes	= @[@(0), @(0.7), @(1)];
	return animation;
}

- (CAAnimation*)transformScaleAnimationWhileDisapearing {
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
	animation.values	= @[@(1), @(0)];
	animation.keyTimes	= @[@(0), @(1)];
	return animation;
}

- (CAAnimation*)translationAnimationWhileDisappearing {
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsPortrait(orientation)) {
		CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
		animation.keyTimes = @[@(0), @(1)];
		if (orientation == UIInterfaceOrientationPortrait)
			animation.values = @[@(0), @(self.frame.size.height/2)];
		else
			animation.values = @[@(0), @(-self.frame.size.height/2)];
		return animation;
	}
	else {
		CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
		animation.keyTimes = @[@(0), @(1)];
		if (orientation == UIInterfaceOrientationLandscapeLeft)
			animation.values = @[@(0), @(self.frame.size.width/2)];
		else
			animation.values = @[@(0), @(-self.frame.size.width/2)];
		return animation;
	}
}

#pragma mark - Animate

- (void)animateForAppearingWithDuration:(float)duration {
	// decide whether animation should be started or not
	if (!self.hidden)
		return;
	self.hidden = NO;
	
	// make animation group
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.animations = @[[self transformScaleAnimationWhileAppearing], [self translationAnimationWhileAppearing], [self alphaAnimationWhileAppearing]];
	group.duration = duration;
	group.removedOnCompletion = NO;
	group.fillMode = kCAFillModeForwards;
	group.delegate = self;
	
	// commit animation
	[group setValue:UZLoupeViewAppearingAnimation forKey:UZCoreAnimationName];
	[self.layer addAnimation:group forKey:UZLoupeViewAppearingAnimation];
}

- (void)animateForDisappearingWithDuration:(float)duration {
	// make group
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.animations = @[[self translationAnimationWhileDisappearing], [self transformScaleAnimationWhileDisapearing], [self alphaAnimationWhileDisappearing]];
	group.duration = duration;
	group.removedOnCompletion = NO;
	group.fillMode = kCAFillModeForwards;
	group.delegate = self;
	
	// commit animation
	[group setValue:UZLoupeViewDisappearingAnimation forKey:UZCoreAnimationName];
	[self.layer addAnimation:group forKey:UZLoupeViewDisappearingAnimation];
}

#pragma mark - Core Animation callback

- (void)animationDidStop:(CAAnimation*)animation finished:(BOOL)flag {
	if ([[animation valueForKey:UZCoreAnimationName] isEqualToString:UZLoupeViewAppearingAnimation]) {
	}
	if ([[animation valueForKey:UZCoreAnimationName] isEqualToString:UZLoupeViewDisappearingAnimation]) {
		self.hidden = YES;
		self.layer.transform = CATransform3DIdentity;
	}
}

#pragma mark - Public

- (void)setVisible:(BOOL)visible animated:(BOOL)animated {
	float duration = animated ? UZ_LOUPE_ANIMATION_DUARTION : UZ_LOUPE_NO_ANIMATION_DUARTION;
	_windowImage = nil;
	if (visible)
		[self animateForAppearingWithDuration:duration];
	else
		[self animateForDisappearingWithDuration:duration];
}

- (void)updateLoupeWithImage:(UIImage*)image {
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
	
	float radius = rect.size.width/2;
	
	// draw back ground fill
	CGContextSaveGState(context);
	CGContextAddArc(context, radius, radius, radius, 0, M_PI * 2, 0);
	CGContextClosePath(context);
	CGContextClip(context);
	CGContextTranslateCTM(context, -_windowImageOffset.x, -_windowImageOffset.y);
	[_windowImage drawAtPoint:CGPointZero];
	CGContextRestoreGState(context);
	
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
