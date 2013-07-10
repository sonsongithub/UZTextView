//
//  UZTextView.m
//  Text
//
//  Created by sonson on 2013/06/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "UZTextView.h"

#import "UZLoupeView.h"

#define NEW_LINE_GLYPH 65535

#define NSLogRect(p) NSLog(@"%f,%f,%f,%f",p.origin.x, p.origin.y, p.size.width, p.size.height)
#define NSLogRange(p) NSLog(@"%d,%d",p.location, p.length)

@implementation UZTextView

- (NSArray*)fragmentRectsForGlyphFromIndex:(int)fromIndex toIndex:(int)toIndex {
	// Extracted fragment rects from layout manager
	NSMutableArray *fragmentRects = [NSMutableArray array];
	for (int i = fromIndex; i <= toIndex;) {
		// Get right glyph index and left one on the line
		NSRange effectiveRange;
		[_layoutManager lineFragmentRectForGlyphAtIndex:i effectiveRange:(NSRangePointer)&effectiveRange];
		NSUInteger left = effectiveRange.location >= i ? effectiveRange.location : i;
		NSUInteger right = effectiveRange.location + effectiveRange.length <= toIndex ? effectiveRange.location + effectiveRange.length - 1 : toIndex;
		
		// Skip new line code
		CGGlyph rightGlyph = [_layoutManager glyphAtIndex:right];
		if (rightGlyph == NEW_LINE_GLYPH)
			right--;
		
		// Get regions of right and left glyph
		CGRect r1 = [_layoutManager boundingRectForGlyphRange:NSMakeRange(left, 1) inTextContainer:_textContainer];
		CGRect r2 = [_layoutManager boundingRectForGlyphRange:NSMakeRange(right, 1) inTextContainer:_textContainer];
		
		// Get line region by combining right and left regions.
		CGRect r = CGRectMake(r1.origin.x, r1.origin.y, r2.origin.x + r2.size.width - r1.origin.x, r1.size.height);
		
		[fragmentRects addObject:[NSValue valueWithCGRect:r]];
		
		// forward glyph index pointer, i
		i = effectiveRange.location + effectiveRange.length;
	}
	return [NSArray arrayWithArray:fragmentRects];
}

- (void)drawSelectedLinkFragments {
	if (_from != _end || !_isTapping)
		return;
	
	NSRange range;
	NSDictionary *dict = [self.attributedString attributesAtIndex:_from effectiveRange:&range];
	if (dict[NSLinkAttributeName]) {
		NSLogRange(range);
		CGRect glyphrect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(_from, 1) inTextContainer:_textContainer];
		
		CGPoint p = [_touch locationInView:self];
		if (CGRectContainsPoint(glyphrect, p)) {
			CGContextRef context = UIGraphicsGetCurrentContext();
			
			[[self.tintColor colorWithAlphaComponent:0.5] setFill];
			
			NSUInteger start = range.location;
			NSUInteger end = range.location + range.length;
			
			NSArray *fragmentRects = [self fragmentRectsForGlyphFromIndex:start toIndex:end];
			
			for (NSValue *rectValue in fragmentRects) {
				CGContextFillRect(context, [rectValue CGRectValue]);
			}
		}
	}
}

- (void)drawSelectedTextFragments {
	if (!_isSelecting)
		return;
	
	// Re-order start and end index.
	NSUInteger start = _from < _end ? _from : _end;
	NSUInteger end = _from > _end ? _from : _end;
	
	// Set drawing color
	[[self.tintColor colorWithAlphaComponent:0.5] setFill];
	CGContextRef context = UIGraphicsGetCurrentContext();

	NSArray *fragmentRects = [self fragmentRectsForGlyphFromIndex:start toIndex:end];
	
	for (NSValue *rectValue in fragmentRects) {
		CGContextFillRect(context, [rectValue CGRectValue]);
	}
#if 0
	// Render start and end cursors, for debug
	CGRect left_cursol = [_layoutManager boundingRectForGlyphRange:NSMakeRange(start, 1) inTextContainer:_textContainer];
	CGRect right_cursol = [_layoutManager boundingRectForGlyphRange:NSMakeRange(end, 1) inTextContainer:_textContainer];
	[[UIColor colorWithRed:0 green:1 blue:0 alpha:0.8] setFill];
	CGContextFillRect(context, left_cursol);
	CGContextFillRect(context, right_cursol);
#endif
}

- (void)searchLinkAttribute {
}

- (void)_pushSnapshotToLoupeViewAtLocation:(CGPoint)location {
	float radius = 100;
	UIView *v = [[UIScreen mainScreen] snapshotView];
	UIGraphicsBeginImageContextWithOptions(v.frame.size, NO, 0);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[[UIColor blackColor] set];
	CGContextFillRect(ctx, v.frame);
	CGContextScaleCTM(ctx, 1, 1);
	CGContextTranslateCTM(ctx, 0, 0);
	[v.layer renderInContext:ctx];
	UIImage *sourceViewImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	[_loupeView update:sourceViewImage];
	[_loupeView setCenter:CGPointMake(location.x, location.y - radius/2)];
}

- (void)pushSnapshotToLoupeViewAtLocation:(CGPoint)location {
	// Create UIImage from source view controller's view.
	float radius = 100;
//	CGPoint p = [touch locationInView:self];
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(radius, radius), NO, 0);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextScaleCTM(ctx, 1, 1);
	CGContextTranslateCTM(ctx, -location.x + radius/2, -location.y+radius/2);
	// Drawing code
	[self drawContentWithRect:self.frame];
	UIImage *sourceViewImage = UIGraphicsGetImageFromCurrentImageContext();
	[_loupeView update:sourceViewImage];
	[_loupeView setCenter:CGPointMake(location.x, location.y - radius/2)];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	_touch = touch;
	_from = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
	_end = _from;
	_isSelecting = NO;
	_isTapping = YES;
	[self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	_end = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
	_isSelecting = YES;
	_isTapping = NO;
	[self setNeedsDisplay];
	
//	[self _pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
	[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	_end = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
	_isTapping = NO;
	_isSelecting = NO;
	[self setNeedsDisplay];
//#if 1
	// for debug
	NSUInteger start = _from < _end ? _from : _end;
	NSUInteger end = _from > _end ? _from : _end;
	NSLog(@"%@", [[self.attributedString string] substringWithRange:NSMakeRange(start, end - start + 1)]);
//#endif
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		_layoutManager = [[NSLayoutManager alloc] init];
		_textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
		_textStorage = [[NSTextStorage alloc] init];
		_loupeView = [[UZLoupeView alloc] init];
		[_layoutManager addTextContainer:_textContainer];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
        // Initialization code
		_layoutManager = [[NSLayoutManager alloc] init];
		_textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
		_textStorage = [[NSTextStorage alloc] init];
		[_layoutManager addTextContainer:_textContainer];
		_loupeView = [[UZLoupeView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
		[self addSubview:_loupeView];
	}
	return self;
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
	_attributedString = attributedString;
	
	[_textStorage setAttributedString:attributedString];
	
	[_layoutManager setTextStorage:_textStorage];
	
	[_textStorage addLayoutManager:_layoutManager];
	
	NSRange range = [_layoutManager glyphRangeForTextContainer:_textContainer];
	
	for (int i = range.location; i < range.location + range.length; i++) {
		NSLog(@"%d->%d", i, [_layoutManager glyphAtIndex:i]);
	}
	
	CGRect r = [_layoutManager lineFragmentRectForGlyphAtIndex:self.attributedString.length-1 effectiveRange:NULL];
	NSLog(@"%f,%f, %f,%f", r.origin.x, r.origin.y, r.size.width, r.size.height);
	
	CGRect currentRect = self.frame;
	currentRect.size = CGSizeMake(r.size.width, r.size.height + r.origin.y);
	self.frame = currentRect;
	[self setNeedsLayout];
	[self setNeedsDisplay];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	NSLog(@"layoutSubviews");
	[self setNeedsDisplay];
}

- (void)drawContentWithRect:(CGRect)rect {
	// draw background color
	CGContextRef context = UIGraphicsGetCurrentContext();
	[[UIColor whiteColor] setFill];
	CGContextFillRect(context, rect);
    
	// Drawing code
	[_textContainer setSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
	[_layoutManager drawGlyphsForGlyphRange:NSMakeRange(0, self.attributedString.length) atPoint:CGPointMake(0, 0)];
	[self drawSelectedTextFragments];
	[self drawSelectedLinkFragments];
}

- (void)drawLoupeWithRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	[[self.tintColor colorWithAlphaComponent:0.75] setStroke];
	[[UIColor whiteColor] setFill];
	
	CGPoint p = [_touch locationInView:self];
	float radius = 50;
	float offset = 0;
	CGContextAddArc(context, p.x, p.y - radius - offset, radius, 0, M_PI * 2, 0);
	CGContextClosePath(context);
	CGContextDrawPath(context, kCGPathFillStroke);
	
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, 0, - offset - radius);
	CGContextAddArc(context, p.x, p.y, radius, 0, M_PI * 2, 0);
	CGContextClosePath(context);
	CGContextClip(context);
	[self drawContentWithRect:rect];
	CGContextRestoreGState(context);
}

- (void)drawRect:(CGRect)rect {
	// draw main content
	[self drawContentWithRect:rect];
	
//	// draw loupe
//	if (_isSelecting) {
//		[self drawLoupeWithRect:rect];
//	}
}

@end
