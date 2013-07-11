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

- (BOOL)clickFromAtPoint:(CGPoint)point {
	CGRect left_cursol = [_layoutManager boundingRectForGlyphRange:NSMakeRange(_from, 1) inTextContainer:_textContainer];
	return CGRectContainsPoint(left_cursol, point);
}

- (BOOL)clickEndAtPoint:(CGPoint)point {
	CGRect right_cursol = [_layoutManager boundingRectForGlyphRange:NSMakeRange(_end, 1) inTextContainer:_textContainer];
	return CGRectContainsPoint(right_cursol, point);
}

#pragma mark - Touch event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	_touch = touch;
	_isSelecting = NO;
	_isTapping = YES;
	[self setNeedsDisplay];
	
	[_loupeView animate];
	if (_status == UZTextViewSelected) {
		if ([self clickFromAtPoint:[touch locationInView:self]]) {
			_status = UZTextViewEditingFromSelection;
			return;
		}
		if ([self clickEndAtPoint:[touch locationInView:self]]) {
			_status = UZTextViewEditingToSelection;
			return;
		}
	}
	_status = UZTextViewSelecting;
	_from = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
	_end = _from;
	
	[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
}

- (void)updateSelecting {
	NSUInteger start = _from < _end ? _from : _end;
	NSUInteger end = _from > _end ? _from : _end;
	NSLog(@"%@", [[self.attributedString string] substringWithRange:NSMakeRange(start, end - start + 1)]);
	//#endif
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	if (_status == UZTextViewSelecting) {
		_end = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
	}
	else if (_status == UZTextViewEditingFromSelection) {
		_from = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
		[self updateSelecting];
	}
	else if (_status == UZTextViewEditingToSelection) {
		_end = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
		[self updateSelecting];
	}
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	if (_status == UZTextViewSelecting) {
		_end = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
	}
	else if (_status == UZTextViewEditingFromSelection) {
		_from = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
	}
	else if (_status == UZTextViewEditingToSelection) {
		_end = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
	}
	
	NSUInteger start = _from < _end ? _from : _end;
	NSUInteger end = _from > _end ? _from : _end;
	_from = start;
	_end = end;
	
	if (abs(_from - _end) > 0)
		_status = UZTextViewSelected;
	else
		_status = UZTextViewNoSelection;
	
	[self updateSelecting];
	[_loupeView hideanimate];
	[self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	
}

#pragma mark - Layout

- (NSArray*)fragmentRectsForGlyphFromIndex:(int)fromIndex toIndex:(int)toIndex {
	if (!(fromIndex < toIndex && fromIndex >=0 && toIndex >=0))
		return @[];
	
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

- (void)drawCursor {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Re-order start and end index.
	NSUInteger start = _from < _end ? _from : _end;
	NSUInteger end = _from > _end ? _from : _end;
	
	// Render start and end cursors, for debug
	CGRect left_cursol = [_layoutManager boundingRectForGlyphRange:NSMakeRange(start, 1) inTextContainer:_textContainer];
	CGRect right_cursol = [_layoutManager boundingRectForGlyphRange:NSMakeRange(end, 1) inTextContainer:_textContainer];
	[[UIColor colorWithRed:0 green:1 blue:0 alpha:0.8] setFill];
	
	{
		UIColor* fillColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
		UIColor* strokeColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1];
		UIBezierPath* path = [UIBezierPath bezierPath];
		CGContextSaveGState(context);
		CGContextTranslateCTM(context, left_cursol.origin.x - 6, left_cursol.origin.y);
		[path moveToPoint: CGPointMake(12,-6)];
		[path addCurveToPoint: CGPointMake(6,-12) controlPoint1: CGPointMake(12,-9) controlPoint2: CGPointMake(9,-12)];
		[path addCurveToPoint: CGPointMake(0,-6) controlPoint1: CGPointMake(2,-12) controlPoint2: CGPointMake(0,-9)];
		[path addCurveToPoint: CGPointMake(4,0) controlPoint1: CGPointMake(0,-3) controlPoint2: CGPointMake(2,0)];
		[path addLineToPoint: CGPointMake(4,32)];
		[path addLineToPoint: CGPointMake(7,32)];
		[path addLineToPoint: CGPointMake(7,0)];
		[path addCurveToPoint: CGPointMake(12,-6) controlPoint1: CGPointMake(10,0) controlPoint2: CGPointMake(12,-3)];
		[fillColor setFill];
		[path fill];
		[strokeColor setStroke];
		path.lineWidth = 1;
		[path stroke];
		CGContextRestoreGState(context);
	}
	{
		UIColor* fillColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
		UIColor* strokeColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1];
		UIBezierPath* path = [UIBezierPath bezierPath];
		CGContextSaveGState(context);
		if ([_layoutManager glyphAtIndex:end] == NEW_LINE_GLYPH)
			CGContextTranslateCTM(context, right_cursol.origin.x - 6, right_cursol.origin.y);
		else
			CGContextTranslateCTM(context, right_cursol.origin.x + right_cursol.size.width - 6, right_cursol.origin.y);
		[path moveToPoint: CGPointMake(0,38)];
		[path addCurveToPoint: CGPointMake(6,44) controlPoint1: CGPointMake(0,41) controlPoint2: CGPointMake(2,44)];
		[path addCurveToPoint: CGPointMake(12,38) controlPoint1: CGPointMake(9,44) controlPoint2: CGPointMake(12,41)];
		[path addCurveToPoint: CGPointMake(7,31) controlPoint1: CGPointMake(12,35) controlPoint2: CGPointMake(10,32)];
		[path addLineToPoint: CGPointMake(7,0)];
		[path addLineToPoint: CGPointMake(4,0)];
		[path addLineToPoint: CGPointMake(4,31)];
		[path addCurveToPoint: CGPointMake(0,38) controlPoint1: CGPointMake(2,32) controlPoint2: CGPointMake(0,35)];
		[fillColor setFill];
		[path fill];
		[strokeColor setStroke];
		path.lineWidth = 1;
		[path stroke];
		CGContextRestoreGState(context);
	}

}

- (void)searchLinkAttribute {
}

- (void)pushSnapshotToLoupeViewAtLocation:(CGPoint)location {
	// Create UIImage from source view controller's view.
	float radius = 100;
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(radius, radius), NO, 0);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[[UIColor whiteColor] setFill];
	CGContextFillRect(ctx, CGRectMake(0, 0, radius, radius));
	CGContextScaleCTM(ctx, 1, 1);
	CGContextTranslateCTM(ctx, -location.x + radius/2, -location.y+radius/2);
	// Drawing code
	[self drawContent];
	UIImage *sourceViewImage = UIGraphicsGetImageFromCurrentImageContext();
	[_loupeView update:sourceViewImage];
	UIGraphicsEndImageContext();
	[_loupeView setCenter:CGPointMake(location.x, location.y - radius/2)];
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

- (void)drawContent {
	// Drawing code
	[_textContainer setSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
	[_layoutManager drawGlyphsForGlyphRange:NSMakeRange(0, self.attributedString.length) atPoint:CGPointMake(0, 0)];

	if (_status == UZTextViewSelecting) {
		[self drawSelectedTextFragments];
	}
	if (_status == UZTextViewSelected || _status == UZTextViewEditingToSelection || _status == UZTextViewEditingFromSelection) {
		[self drawSelectedTextFragments];
		[self drawCursor];
	}
}

- (void)drawRect:(CGRect)rect {
	// draw background color
	CGContextRef context = UIGraphicsGetCurrentContext();
	[[UIColor whiteColor] setFill];
	CGContextFillRect(context, rect);
	
	// draw main content
	[self drawContent];
}

@end
