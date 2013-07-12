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

typedef enum _UZTextViewGlyphEdgeType {
	UZTextViewLeftEdge		= 0,
	UZTextViewRightEdge		= 1
}UZTextViewGlyphEdgeType;

typedef enum _UZTextViewCursorDirection {
	UZTextViewUpCursor		= 0,
	UZTextViewDownCursor	= 1
}UZTextViewCursorDirection;

@implementation UZTextView

- (CGRect)rectToTapAtIndex:(int)index side:(UZTextViewGlyphEdgeType)side {
	if (side == UZTextViewLeftEdge) {
		CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(index, 1) inTextContainer:_textContainer];
		rect.size.width = 0;
		return CGRectInset(rect, -10, -10);
	}
	else {
		CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(index, 1) inTextContainer:_textContainer];
		if ([_layoutManager glyphAtIndex:index] != NEW_LINE_GLYPH)
			rect.origin.x += rect.size.width;
		rect.size.width = 0;
		return CGRectInset(rect, -10, -10);
	}
}

- (BOOL)clickFromAtPoint:(CGPoint)point {
	return CGRectContainsPoint([self rectToTapAtIndex:_from side:UZTextViewLeftEdge], point);
}

- (BOOL)clickEndAtPoint:(CGPoint)point {
	return CGRectContainsPoint([self rectToTapAtIndex:_end side:UZTextViewRightEdge], point);
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

#pragma mark - Draw

- (NSArray*)fragmentRectsForGlyphFromIndex:(int)fromIndex toIndex:(int)toIndex {
	if (!(fromIndex <= toIndex && fromIndex >=0 && toIndex >=0))
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

//- (void)drawSelectedLinkFragments {
//	NSRange range;
//	NSDictionary *dict = [self.attributedString attributesAtIndex:_from effectiveRange:&range];
//	if (dict[NSLinkAttributeName]) {
//		NSLogRange(range);
//		CGRect glyphrect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(_from, 1) inTextContainer:_textContainer];
//		
//		CGPoint p = [_touch locationInView:self];
//		if (CGRectContainsPoint(glyphrect, p)) {
//			CGContextRef context = UIGraphicsGetCurrentContext();
//			
//			[[self.tintColor colorWithAlphaComponent:0.5] setFill];
//			
//			NSUInteger start = range.location;
//			NSUInteger end = range.location + range.length;
//			
//			NSArray *fragmentRects = [self fragmentRectsForGlyphFromIndex:start toIndex:end];
//			
//			for (NSValue *rectValue in fragmentRects) {
//				CGContextFillRect(context, [rectValue CGRectValue]);
//			}
//		}
//	}
//}

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

- (void)drawCursorInsideRect:(CGRect)rect direction:(UZTextViewCursorDirection)direction {
	CGContextRef context = UIGraphicsGetCurrentContext();
	float radius = 4;
	float width = 2;
	CGRect lineRect;
	CGPoint circleCenter;
	
	if (direction == UZTextViewUpCursor) {
		circleCenter = CGPointMake(CGRectGetMidX(rect), rect.origin.y + radius);
		lineRect = CGRectMake(circleCenter.x - width/2, circleCenter.y + radius, width, rect.size.height - radius * 3);
	}
	else {
		circleCenter = CGPointMake(CGRectGetMidX(rect), rect.origin.y + rect.size.height - radius);
		lineRect = CGRectMake(circleCenter.x - width/2, rect.origin.y + radius, width, rect.size.height - radius * 3);
	}
	CGContextAddArc(context, circleCenter.x, circleCenter.y, radius, 0, 2 * M_PI, 0);
	CGContextClosePath(context);
	[[self.tintColor colorWithAlphaComponent:1] setFill];
	CGContextFillPath(context);
	CGContextFillRect(context, lineRect);
}

- (void)drawCursor {
	// Re-order start and end index.
	NSUInteger start = _from < _end ? _from : _end;
	NSUInteger end = _from > _end ? _from : _end;
	
	CGRect startRect = [self rectToTapAtIndex:start side:UZTextViewLeftEdge];
	CGRect endRect = [self rectToTapAtIndex:end side:UZTextViewRightEdge];
	
	[self drawCursorInsideRect:startRect direction:UZTextViewUpCursor];
	[self drawCursorInsideRect:endRect direction:UZTextViewDownCursor];
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

#pragma mark - Touch event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	[self setNeedsDisplay];
	[[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
	
	if (_status == UZTextViewSelected) {
		if ([self clickFromAtPoint:[touch locationInView:self]]) {
			_status = UZTextViewEditingFromSelection;
			[_loupeView animate];
			return;
		}
		if ([self clickEndAtPoint:[touch locationInView:self]]) {
			_status = UZTextViewEditingToSelection;
			[_loupeView animate];
			return;
		}
	}
	_status = UZTextViewNoSelection;
	_locationWhenTapBegan = [touch locationInView:self];
	[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	if (_status == UZTextViewNoSelection) {
		if (fabs(_locationWhenTapBegan.x - [touch locationInView:self].y) + fabs(_locationWhenTapBegan.y - [touch locationInView:self].y) > 4) {
			_from = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
			_end = _from;
			[_loupeView animate];
			_status = UZTextViewSelecting;
		}
	}
	if (_status == UZTextViewSelecting) {
		_end = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
	}
	else if (_status == UZTextViewEditingFromSelection) {
		_from = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
	}
	else if (_status == UZTextViewEditingToSelection) {
		_end = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
	}
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	if (_status == UZTextViewSelecting) {
		_end = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		[_loupeView hideanimate];
	}
	else if (_status == UZTextViewEditingFromSelection) {
		_from = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		[_loupeView hideanimate];
	}
	else if (_status == UZTextViewEditingToSelection) {
		_end = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		[_loupeView hideanimate];
	}
	
	if (_status == UZTextViewNoSelection) {
	}
	else {
		NSUInteger start = _from < _end ? _from : _end;
		NSUInteger end = _from > _end ? _from : _end;
		_from = start;
		_end = end;
		_status = UZTextViewSelected;
		
		NSArray *fragmentRects = [self fragmentRectsForGlyphFromIndex:start toIndex:end];
		CGRect r = [[fragmentRects objectAtIndex:0] CGRectValue];
		for (NSValue *rectValue in fragmentRects) {
			r = CGRectUnion(r, [rectValue CGRectValue]);
		}
		[self becomeFirstResponder];
		[[UIMenuController sharedMenuController] setTargetRect:r inView:self];
		[[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
	}
	[self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	
}

- (void)copy:(id)sender {
	[UIPasteboard generalPasteboard].string = [self.attributedString.string substringWithRange:NSMakeRange(_from, _end)];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(copy:)) {
		return YES;
	}
	return NO;
}

#pragma mark - initialize

- (void)prepareForInit {
	// Initialization code
	_layoutManager = [[NSLayoutManager alloc] init];
	_textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
	_textStorage = [[NSTextStorage alloc] init];
	[_layoutManager addTextContainer:_textContainer];
	_loupeView = [[UZLoupeView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	[self addSubview:_loupeView];
}

#pragma mark - Override

- (void)layoutSubviews {
	[super layoutSubviews];
	[self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self)
		[self prepareForInit];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
    if (self)
		[self prepareForInit];
	return self;
}

- (void)drawRect:(CGRect)rect {
	// draw background color
	CGContextRef context = UIGraphicsGetCurrentContext();
	[[UIColor whiteColor] setFill];
	CGContextFillRect(context, rect);
	
	// draw main content
	[self drawContent];
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

@end
