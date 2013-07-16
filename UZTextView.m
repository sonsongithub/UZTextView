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

#pragma mark - Instance method

- (CGRect)rectToTapAtIndex:(int)index side:(UZTextViewGlyphEdgeType)side {
	if (side == UZTextViewLeftEdge) {
		CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(index, 1) inTextContainer:_textContainer];
		rect.size.width = 0;
		return CGRectInset(rect, -_cursorMargin, -_cursorMargin);
	}
	else {
		CGRect rect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(index, 1) inTextContainer:_textContainer];
		if ([_layoutManager glyphAtIndex:index] != NEW_LINE_GLYPH)
			rect.origin.x += rect.size.width;
		rect.size.width = 0;
		return CGRectInset(rect, -_cursorMargin, -_cursorMargin);
	}
}

- (void)pushSnapshotToLoupeViewAtLocation:(CGPoint)location {
	// Create UIImage from source view controller's view.
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(_loupeRadius, _loupeRadius), NO, 0);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[[UIColor whiteColor] setFill];
	CGContextFillRect(ctx, CGRectMake(0, 0, _loupeRadius, _loupeRadius));
	CGContextScaleCTM(ctx, 1, 1);
	CGContextTranslateCTM(ctx, -location.x + _loupeRadius/2, -location.y+_loupeRadius/2);
	// Drawing code
	[self drawContent];
	UIImage *sourceViewImage = UIGraphicsGetImageFromCurrentImageContext();
	[_loupeView update:sourceViewImage];
	UIGraphicsEndImageContext();
	[_loupeView setCenter:CGPointMake(location.x, location.y - _loupeRadius/2)];
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
	_attributedString = attributedString;
	
	[_textStorage setAttributedString:attributedString];
	
	[_layoutManager setTextStorage:_textStorage];
	
	[_textStorage addLayoutManager:_layoutManager];
	
	CGRect r = [_layoutManager lineFragmentRectForGlyphAtIndex:self.attributedString.length-1 effectiveRange:NULL];
	
	CGRect currentRect = self.frame;
	currentRect.size = CGSizeMake(r.size.width, r.size.height + r.origin.y);
	self.frame = currentRect;
	[self setNeedsLayout];
	[self setNeedsDisplay];
}

#pragma mark - Layout information

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

- (CGRect)selectedStringRectFromIndex:(int)fromIndex toIndex:(int)toIndex {
	NSArray *fragmentRects = [self fragmentRectsForGlyphFromIndex:fromIndex toIndex:toIndex];
	CGRect unifiedRect = [[fragmentRects objectAtIndex:0] CGRectValue];
	for (NSValue *rectValue in fragmentRects) {
		unifiedRect = CGRectUnion(unifiedRect, [rectValue CGRectValue]);
	}
	return unifiedRect;
}

#pragma mark - Draw

- (void)drawSelectedLinkFragments {
	NSRange range;
	if (CGPointEqualToPoint(_locationWhenTapBegan, CGPointZero))
		return;
	int tappedIndex = [_layoutManager glyphIndexForPoint:_locationWhenTapBegan inTextContainer:_textContainer];
	NSDictionary *dict = [self.attributedString attributesAtIndex:tappedIndex effectiveRange:&range];
	if (dict[NSLinkAttributeName]) {
		NSLogRange(range);
		CGRect glyphrect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(tappedIndex, 1) inTextContainer:_textContainer];

		if (CGRectContainsPoint(glyphrect, _locationWhenTapBegan)) {
			CGContextRef context = UIGraphicsGetCurrentContext();

			[[self.tintColor colorWithAlphaComponent:_tintAlpha] setFill];

			NSUInteger start = range.location;
			NSUInteger end = range.location + range.length;

			NSArray *fragmentRects = [self fragmentRectsForGlyphFromIndex:start toIndex:end];

			for (NSValue *rectValue in fragmentRects) {
				CGContextFillRect(context, [rectValue CGRectValue]);
			}
		}
	}
}

- (void)drawSelectedTextFragmentRectsFromIndex:(int)fromIndex toIndex:(int)toIndex {
	// Set drawing color
	[[self.tintColor colorWithAlphaComponent:_tintAlpha] setFill];
	CGContextRef context = UIGraphicsGetCurrentContext();
	NSArray *fragmentRects = [self fragmentRectsForGlyphFromIndex:fromIndex toIndex:toIndex];
	for (NSValue *rectValue in fragmentRects)
		CGContextFillRect(context, [rectValue CGRectValue]);
}

- (void)drawCursorInsideRect:(CGRect)rect direction:(UZTextViewCursorDirection)direction {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect lineRect;
	CGPoint circleCenter;
	
	if (direction == UZTextViewUpCursor) {
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

- (void)drawCursorAtIndex:(int)index side:(UZTextViewGlyphEdgeType)edgeType direction:(UZTextViewCursorDirection)direction {
	CGRect rect = [self rectToTapAtIndex:index side:edgeType];
	[self drawCursorInsideRect:rect direction:direction];
}

- (void)drawCursorsAtFromIndex:(int)fromIndex atToIndex:(int)toIndex {
	[self drawCursorAtIndex:fromIndex side:UZTextViewLeftEdge direction:UZTextViewUpCursor];
	[self drawCursorAtIndex:toIndex side:UZTextViewRightEdge direction:UZTextViewDownCursor];
}

- (void)drawContent {
	// Drawing code
	[_textContainer setSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
	[_layoutManager drawGlyphsForGlyphRange:NSMakeRange(0, self.attributedString.length) atPoint:CGPointMake(0, 0)];
	
	int fromToRender = _from < _end ? _from : _end;
	int toToRender = _from < _end ? _end : _from;
	
	if (_status == UZTextViewSelecting) {
		[self drawSelectedTextFragmentRectsFromIndex:fromToRender toIndex:toToRender];
	}
	if (_status == UZTextViewSelected || _status == UZTextViewEditingToSelection || _status == UZTextViewEditingFromSelection) {
		[self drawSelectedTextFragmentRectsFromIndex:fromToRender toIndex:toToRender];
		[self drawCursorsAtFromIndex:fromToRender atToIndex:toToRender];
	}
	if (_status == UZTextViewNoSelection)
		[self drawSelectedLinkFragments];
}

#pragma mark - Touch event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog(@"touchesBegan");
	UITouch *touch = [touches anyObject];
	[self setNeedsDisplay];
	[[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
	
	if (_status == UZTextViewSelected) {
		_fromWhenBegan = _from;
		_endWhenBegan = _end;
		if (CGRectContainsPoint([self rectToTapAtIndex:_from side:UZTextViewLeftEdge], [touch locationInView:self])) {
			_status = UZTextViewEditingFromSelection;
			[_loupeView setVisible:YES animated:YES];
			[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
			if ([self.delegate respondsToSelector:@selector(selectionDidBeginTextView:)])
				[self.delegate selectionDidBeginTextView:self];
			return;
		}
		if (CGRectContainsPoint([self rectToTapAtIndex:_end side:UZTextViewRightEdge], [touch locationInView:self])) {
			_status = UZTextViewEditingToSelection;
			[_loupeView setVisible:YES animated:YES];
			[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
			if ([self.delegate respondsToSelector:@selector(selectionDidBeginTextView:)])
				[self.delegate selectionDidBeginTextView:self];
			return;
		}
	}
	_status = UZTextViewNoSelection;
	_locationWhenTapBegan = [touch locationInView:self];
	_tapDurationTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(tapDurationTimerFired:) userInfo:nil repeats:NO];
}

- (void)tapDurationTimerFired:(NSTimer*)timer {
	[_loupeView setVisible:YES animated:YES];
	[self pushSnapshotToLoupeViewAtLocation:_locationWhenTapBegan];
	if ([self.delegate respondsToSelector:@selector(selectionDidBeginTextView:)])
		[self.delegate selectionDidBeginTextView:self];
	_tapDurationTimer = nil;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog(@"touchesMoved");
	UITouch *touch = [touches anyObject];
	
	if (_status == UZTextViewNoSelection) {
		if (fabs(_locationWhenTapBegan.x - [touch locationInView:self].y) + fabs(_locationWhenTapBegan.y - [touch locationInView:self].y) > 4) {
			_from = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
			_end = _from;
			[_loupeView setVisible:YES animated:YES];
			_status = UZTextViewSelecting;
			if ([self.delegate respondsToSelector:@selector(selectionDidBeginTextView:)])
				[self.delegate selectionDidBeginTextView:self];
		}
	}
	if (_status == UZTextViewSelecting) {
		_end = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
	}
	else if (_status == UZTextViewEditingFromSelection) {
		int prev_from = _from;
		_from = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		if (prev_from <= _end && _from > _end)
			_end = _endWhenBegan + 1;
		else if (prev_from >= _end && _from < _end)
			_end = _endWhenBegan;
		[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
	}
	else if (_status == UZTextViewEditingToSelection) {
		int prev_end = _end;
		_end = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		if (prev_end >= _from && _from > _end)
			_from = _fromWhenBegan - 1;
		else if (prev_end <= _from && _from < _end)
			_from = _fromWhenBegan;
		[self pushSnapshotToLoupeViewAtLocation:[touch locationInView:self]];
	}
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog(@"touchesEnded");
	[_tapDurationTimer invalidate];
	_tapDurationTimer = nil;
	[_loupeView setVisible:NO animated:YES];
	
	if ([self.delegate respondsToSelector:@selector(selectionDidEndTextView:)])
		[self.delegate selectionDidEndTextView:self];
	
	if (_status == UZTextViewNoSelection) {
		// clicked
		int tappedIndex = [_layoutManager glyphIndexForPoint:_locationWhenTapBegan inTextContainer:_textContainer];
		NSDictionary *dict = [self.attributedString attributesAtIndex:tappedIndex effectiveRange:NULL];
		if (dict[NSLinkAttributeName]) {
			CGRect glyphrect = [_layoutManager boundingRectForGlyphRange:NSMakeRange(tappedIndex, 1) inTextContainer:_textContainer];
			if (CGRectContainsPoint(glyphrect, _locationWhenTapBegan)) {
				if ([self.delegate respondsToSelector:@selector(textView:didClickLinkAttribute:)]) {
					[self.delegate textView:self didClickLinkAttribute:dict];
				}
			}
		}
	}
	else {
		// dragged
		NSUInteger start = _from < _end ? _from : _end;
		NSUInteger end = _from > _end ? _from : _end;
		_from = start;
		_end = end;
		_status = UZTextViewSelected;
		
		[self becomeFirstResponder];
		[[UIMenuController sharedMenuController] setTargetRect:[self selectedStringRectFromIndex:_from toIndex:_end] inView:self];
		[[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
	}
	_locationWhenTapBegan = CGPointZero;
	[self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog(@"touchesCancelled");
	[self touchesEnded:touches withEvent:event];
}

#pragma mark - for UIMenuController

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (void)copy:(id)sender {
	[UIPasteboard generalPasteboard].string = [self.attributedString.string substringWithRange:NSMakeRange(_from, _end - _from)];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(copy:)) {
		return YES;
	}
	return NO;
}

#pragma mark - initialize

- (void)prepareForInit {
	// init invaliables
	_loupeRadius = 100;
	_cursorMargin = 14;
	_tintAlpha = 0.5;
	_cursorCirclrRadius = 6;
	_cursorLineWidth = 2;
	
	// Initialization code
	_layoutManager = [[NSLayoutManager alloc] init];
	_textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
	_textStorage = [[NSTextStorage alloc] init];
	[_layoutManager addTextContainer:_textContainer];
	_loupeView = [[UZLoupeView alloc] initWithFrame:CGRectMake(0, 0, _loupeRadius, _loupeRadius)];
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

@end
