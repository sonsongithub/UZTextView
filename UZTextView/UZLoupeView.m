//
//  UZLoupeView.m
//  UZTextView
//
//  Created by sonson on 2013/07/10.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "UZLoupeView.h"

#define UZ_LOUPE_NO_ANIMATION_DUARTION	0.0001
#define UZ_LOUPE_ANIMATION_DUARTION		0.2
#define UZ_LOUPE_OUTLINE_STROKE_WIDTH	2

#define UZCoreAnimationName (NSString*)_UZCoreAnimationName
#define UZLoupeViewAppearingAnimation (NSString*)_UZLoupeViewAppearingAnimation
#define UZLoupeViewDisappearingAnimation (NSString*)_UZLoupeViewDisappearingAnimation

const NSString *_UZCoreAnimationName = @"_UZCoreAnimationName";
const NSString *_UZLoupeViewAppearingAnimation = @"_UZLoupeViewAppearingAnimation";
const NSString *_UZLoupeViewDisappearingAnimation = @"_UZLoupeViewDisappearingAnimation";

@interface UZLoupeView() {
#ifdef TARGET_IS_EXTENSION
	UIInterfaceOrientation intrinsicOrientation;
#else
#endif
}
@end

@implementation UZLoupeView

#ifdef TARGET_IS_EXTENSION

// code for application
UIView *searchKeyWindow(UIView* view) {
	UIView *p = view.superview;
	if ([p isKindOfClass:[UIWindow class]]) {
		return view;
	}
	if (p == nil)
		return view;
	return searchKeyWindow(p);
}

- (UIInterfaceOrientation)orientation {
	return intrinsicOrientation;
}

- (void)startObserveDeviceOrientation {
	intrinsicOrientation = UIInterfaceOrientationPortrait;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)orientationChanged:(NSNotification*)notification {
	UIDeviceOrientation deviceOrienation = [UIDevice currentDevice].orientation;
	if (deviceOrienation != UIDeviceOrientationUnknown && deviceOrienation != UIDeviceOrientationFaceDown && deviceOrienation != UIDeviceOrientationFaceUp) {
		switch (deviceOrienation) {
			case UIDeviceOrientationPortrait:
				intrinsicOrientation = UIInterfaceOrientationPortrait;
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				intrinsicOrientation = UIInterfaceOrientationPortraitUpsideDown;
				break;
			case UIDeviceOrientationLandscapeLeft:
				intrinsicOrientation = UIInterfaceOrientationLandscapeLeft;
				break;
			case UIDeviceOrientationLandscapeRight:
				intrinsicOrientation = UIInterfaceOrientationLandscapeRight;
				break;
			default:
				break;
		}
	}
}

#else

// code for application
- (UIInterfaceOrientation)orientation {
	return [UIApplication sharedApplication].statusBarOrientation;
}

#endif

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
	UIInterfaceOrientation orientation = [self orientation];
	
	if (UIInterfaceOrientationIsPortrait(orientation)) {
		CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
		animation.keyTimes = @[@(0), @(1)];
		if (orientation == UIInterfaceOrientationPortrait)
			animation.values = @[@(self.frame.size.height/2), @(0)];
		else
			animation.values = @[@(self.frame.size.height/2), @(0)];
		return animation;
	}
	else {
		CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
		animation.keyTimes = @[@(0), @(1)];
		if (orientation == UIInterfaceOrientationLandscapeLeft)
			animation.values = @[@(self.frame.size.height/2), @(0)];
		else
			animation.values = @[@(self.frame.size.height/2), @(0)];
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
	UIInterfaceOrientation orientation = [self orientation];
	if (UIInterfaceOrientationIsPortrait(orientation)) {
		CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
		animation.keyTimes = @[@(0), @(1)];
		if (orientation == UIInterfaceOrientationPortrait)
			animation.values = @[@(0), @(self.frame.size.height/2)];
		else
			animation.values = @[@(0), @(self.frame.size.height/2)];
		return animation;
	}
	else {
		CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
		animation.keyTimes = @[@(0), @(1)];
		if (orientation == UIInterfaceOrientationLandscapeLeft)
			animation.values = @[@(0), @(self.frame.size.height/2)];
		else
			animation.values = @[@(0), @(self.frame.size.height/2)];
		return animation;
	}
}

#pragma mark - Animate

- (void)animateForAppearingWithDuration:(CGFloat)duration {
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

- (void)animateForDisappearingWithDuration:(CGFloat)duration {
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
	CGFloat duration = animated ? UZ_LOUPE_ANIMATION_DUARTION : UZ_LOUPE_NO_ANIMATION_DUARTION;
	if (visible)
		[self animateForAppearingWithDuration:duration];
	else
		[self animateForDisappearingWithDuration:duration];
}

- (void)updateAtLocation:(CGPoint)location textView:(UIView*)textView {
	CGFloat offset = _loupeRadius;
	CGFloat angle = 0;
	
	UIInterfaceOrientation orientation = [self orientation];
	
	// convert point on key window
	
#ifdef TARGET_IS_EXTENSION
	UIView *targetView = (UIWindow*)searchKeyWindow(self);
#else
	UIView *targetView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
#endif
	CGPoint c = [targetView convertPoint:CGPointMake(location.x, location.y) fromView:textView];
	
	// Create UIImage from source view controller's view.
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(_loupeRadius * 2, _loupeRadius * 2), NO, 0);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(ctx, -location.x + _loupeRadius, -location.y + _loupeRadius);
	
	if (orientation == UIInterfaceOrientationLandscapeLeft) {
		c.y -= offset;
	}
	else if (orientation == UIInterfaceOrientationLandscapeRight) {
		c.y -= offset;
	}
	else if (orientation == UIInterfaceOrientationPortrait) {
		c.y -= offset;
	}
	else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
		c.y -= offset;
	}
	
	// adjust orientation
	CGContextTranslateCTM(ctx, location.x, location.y);
	CGContextRotateCTM(ctx, angle);
	CGContextTranslateCTM(ctx, -location.x, -location.y);
	
	// Drawing code
	self.hidden = YES;
	[textView.layer renderInContext:ctx];
	self.hidden = NO;
	
	// Create bitmap
	_image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	// update location
	[targetView addSubview:self];

	[self setCenter:c];
}

#pragma mark - Override

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setCenter:(CGPoint)center {
	[super setCenter:center];
	[self setNeedsDisplay];
}

- (id)initWithRadius:(CGFloat)radius {
	self = [super initWithFrame:CGRectMake(0, 0, radius * 2, radius * 2)];
	if (self) {
		_loupeRadius = radius;
		self.backgroundColor = [UIColor clearColor];
		self.hidden = YES;
#ifdef TARGET_IS_EXTENSION
		[self startObserveDeviceOrientation];
#endif
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// draw back ground fill
	[self.textViewBackgroundColor setFill];
	CGContextAddArc(context, _loupeRadius, _loupeRadius, _loupeRadius, 0, M_PI * 2, 0);
	CGContextClosePath(context);
	CGContextDrawPath(context, kCGPathFill);
	
	// draw captured UZTextView bitmap
	CGContextSaveGState(context);
	CGContextAddArc(context, _loupeRadius, _loupeRadius, _loupeRadius, 0, M_PI * 2, 0);
	CGContextClosePath(context);
	CGContextClip(context);
	[_image drawAtPoint:CGPointZero];
	CGContextRestoreGState(context);
	
	// draw outline stroke
	[[self.tintColor colorWithAlphaComponent:1] setStroke];
	CGContextSaveGState(context);
	CGContextSetLineWidth(context, UZ_LOUPE_OUTLINE_STROKE_WIDTH);
	CGContextAddArc(context, _loupeRadius, _loupeRadius, _loupeRadius-1, 0, M_PI * 2, 0);
	CGContextClosePath(context);
	CGContextDrawPath(context, kCGPathStroke);
	CGContextRestoreGState(context);
}

@end
