//
//  UZTextView.m
//  Text
//
//  Created by sonson on 2013/06/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "UZTextView.h"

#import "UZLoupeView.h"
#import "UZCursorView.h"

#define NEW_LINE_GLYPH 65535

#define NSLogRect(p) NSLog(@"%f,%f,%f,%f",p.origin.x, p.origin.y, p.size.width, p.size.height)
#define NSLogRange(p) NSLog(@"%d,%d",p.location, p.length)

typedef enum _UZTextViewGlyphEdgeType {
	UZTextViewLeftEdge		= 0,
	UZTextViewRightEdge		= 1
}UZTextViewGlyphEdgeType;

typedef enum _UZTextViewStatus {
	UZTextViewNoSelection			= 0,
	UZTextViewSelecting				= 1,
	UZTextViewSelected				= 2,
	UZTextViewEditingFromSelection	= 3,
	UZTextViewEditingToSelection	= 4,
}UZTextViewStatus;

@interface UZTextView() {
	// text manager
	NSLayoutManager		*_layoutManager;
	NSTextContainer		*_textContainer;
	NSTextStorage		*_textStorage;
	
	// parameter
	NSUInteger			_head;
	NSUInteger			_tail;
	NSUInteger			_headWhenBegan;
	NSUInteger			_tailWhenBegan;
	
	UZTextViewStatus	_status;
	BOOL				_isLocked;
	
	//
	NSTimer				*_tapDurationTimer;
	
	// child view
	UZLoupeView			*_loupeView;
	UZCursorView		*_leftCursor;
	UZCursorView		*_rightCursor;
	
	// tap event control
	CGPoint				_locationWhenTapBegan;
	
	// invaliables
	float				_cursorMargin;
	float				_tintAlpha;
	float				_durationToCancelSuperViewScrolling;
}
@end
	
@implementation UZTextView

#pragma mark - Class method to estimate attributed string size

+ (CGSize)sizeForAttributedString:(NSAttributedString*)attributedString withBoundWidth:(float)width {
	NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
	NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(width, CGFLOAT_MAX)];
	NSTextStorage *textStorage = [[NSTextStorage alloc] init];
	[layoutManager addTextContainer:textContainer];
	
	[textStorage setAttributedString:attributedString];
	
	[layoutManager setTextStorage:textStorage];
	
	[textStorage addLayoutManager:layoutManager];
	
	CGRect r = [layoutManager lineFragmentRectForGlyphAtIndex:attributedString.length-1 effectiveRange:NULL];
	return CGSizeMake(width, r.size.height + r.origin.y);
}

#pragma mark - Instance method

- (void)setCursorHidden:(BOOL)hidden {
	int headForRendering = _head < _tail ? _head : _tail;
	int tailForRendering = _head < _tail ? _tail : _head;
	[_leftCursor setFrame:[self fragmentRectForCursorAtIndex:headForRendering side:UZTextViewLeftEdge]];
	[_rightCursor setFrame:[self fragmentRectForCursorAtIndex:tailForRendering side:UZTextViewRightEdge]];
	_leftCursor.hidden = hidden;
	_rightCursor.hidden = hidden;
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
	[self prepareForReuse];
	_layoutManager = [[NSLayoutManager alloc] init];
	_textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
	_textStorage = [[NSTextStorage alloc] init];
	[_layoutManager addTextContainer:_textContainer];
	
	_attributedString = attributedString;
	
	[_textStorage setAttributedString:attributedString];
	
	[_layoutManager setTextStorage:_textStorage];
	
	[_textStorage addLayoutManager:_layoutManager];
	
	CGRect r = [_layoutManager lineFragmentRectForGlyphAtIndex:self.attributedString.length-1 effectiveRange:NULL];
	
	CGRect currentRect = self.frame;
	currentRect.size = CGSizeMake(self.frame.size.width, r.size.height + r.origin.y);
	self.frame = currentRect;
	_contentSize = currentRect.size;
	[self setNeedsLayout];
	[self setNeedsDisplay];
}

- (void)setSelectedRange:(NSRange)selectedRange {
	if (selectedRange.location >= self.attributedString.length)
		return;
	if (selectedRange.length > self.attributedString.length || selectedRange.location + selectedRange.length - 1 <= 0)
		return;
	_head = selectedRange.location;
	_tail = selectedRange.location + selectedRange.length - 1;
	_status = UZTextViewSelected;
	[self setCursorHidden:NO];
	[self setNeedsDisplay];
}

- (NSRange)selectedRange {
	return NSMakeRange(_head, _tail - _head + 1);
}

#pragma mark - Layout information

- (CGRect)fragmentRectForCursorAtIndex:(int)index side:(UZTextViewGlyphEdgeType)side {
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
		
		if (left <= right) {
			// Get regions of right and left glyph
			CGRect r1 = [_layoutManager boundingRectForGlyphRange:NSMakeRange(left, 1) inTextContainer:_textContainer];
			CGRect r2 = [_layoutManager boundingRectForGlyphRange:NSMakeRange(right, 1) inTextContainer:_textContainer];
			
			// Get line region by combining right and left regions.
			CGRect r = CGRectMake(r1.origin.x, r1.origin.y, r2.origin.x + r2.size.width - r1.origin.x, r1.size.height);
			
			[fragmentRects addObject:[NSValue valueWithCGRect:r]];
		}
		// forward glyph index pointer, i
		i = effectiveRange.location + effectiveRange.length;
	}
	return [NSArray arrayWithArray:fragmentRects];
}

- (CGRect)fragmentRectForSelectedStringFromIndex:(int)fromIndex toIndex:(int)toIndex {
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

			NSArray *fragmentRects = [self fragmentRectsForGlyphFromIndex:range.location toIndex:range.location + range.length - 1];

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

- (void)drawContent {
	// Drawing code
	[_textContainer setSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
	[_layoutManager drawGlyphsForGlyphRange:NSMakeRange(0, self.attributedString.length) atPoint:CGPointMake(0, 0)];
	
	int headForRendering = _head < _tail ? _head : _tail;
	int tailForRendering = _head < _tail ? _tail : _head;
	
	if (_status == UZTextViewSelecting || _status == UZTextViewSelected || _status == UZTextViewEditingToSelection || _status == UZTextViewEditingFromSelection) {
		[self drawSelectedTextFragmentRectsFromIndex:headForRendering toIndex:tailForRendering];
	}
	if (_status == UZTextViewNoSelection)
		[self drawSelectedLinkFragments];
}

#pragma mark - Preparation

- (void)prepareForInitialization {
	// init invaliables
	_cursorMargin = 14;
	_tintAlpha = 0.5;
	_durationToCancelSuperViewScrolling = 0.25;
	
	// Initialization code
	_loupeView = [[UZLoupeView alloc] initWithRadius:60];
	[self addSubview:_loupeView];
	
	_leftCursor = [[UZCursorView alloc] initWithCursorDirection:UZTextViewUpCursor];
	_leftCursor.userInteractionEnabled = NO;
	[self addSubview:_leftCursor];
	
	_rightCursor = [[UZCursorView alloc] initWithCursorDirection:UZTextViewDownCursor];
	_rightCursor.userInteractionEnabled = NO;
	[self addSubview:_rightCursor];
}

- (void)prepareForReuse {
	_status = UZTextViewNoSelection;
	_head = 0;
	_tail = 0;
	_headWhenBegan = 0;
	_tailWhenBegan = 0;
	
	[self invalidateTapDurationTimer];
	_leftCursor.hidden = YES;
	_rightCursor.hidden = YES;
	_locationWhenTapBegan = CGPointZero;
}

#pragma mark - NSTimer callbacks

- (void)tapDurationTimerFired:(NSTimer*)timer {
	_isLocked = NO;
	[_loupeView setVisible:YES animated:YES];
	[_loupeView updateAtLocation:_locationWhenTapBegan textView:self];
	if ([self.delegate respondsToSelector:@selector(selectionDidBeginTextView:)])
		[self.delegate selectionDidBeginTextView:self];
	_tapDurationTimer = nil;
}

- (void)invalidateTapDurationTimer {
	[_tapDurationTimer invalidate];
	_tapDurationTimer = nil;
}

#pragma mark - for UIMenuController

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (void)copy:(id)sender {
	NSLog(@"%@", [self.attributedString.string substringWithRange:self.selectedRange]);
	[UIPasteboard generalPasteboard].string = [self.attributedString.string substringWithRange:self.selectedRange];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(copy:)) {
		return YES;
	}
	return NO;
}

#pragma mark - Touch event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	_isLocked = YES;
	UITouch *touch = [touches anyObject];
	[self setNeedsDisplay];
	[[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
	
	if (_status == UZTextViewSelected) {
		_headWhenBegan = _head;
		_tailWhenBegan = _tail;
		if (CGRectContainsPoint([self fragmentRectForCursorAtIndex:_head side:UZTextViewLeftEdge], [touch locationInView:self])) {
			_isLocked = NO;
			_status = UZTextViewEditingFromSelection;
			[_loupeView setVisible:YES animated:YES];
			[_loupeView updateAtLocation:[touch locationInView:self] textView:self];
			if ([self.delegate respondsToSelector:@selector(selectionDidBeginTextView:)])
				[self.delegate selectionDidBeginTextView:self];
			[self setCursorHidden:NO];
			return;
		}
		if (CGRectContainsPoint([self fragmentRectForCursorAtIndex:_tail side:UZTextViewRightEdge], [touch locationInView:self])) {
			_isLocked = NO;
			_status = UZTextViewEditingToSelection;
			[_loupeView setVisible:YES animated:YES];
			[_loupeView updateAtLocation:[touch locationInView:self] textView:self];
			if ([self.delegate respondsToSelector:@selector(selectionDidBeginTextView:)])
				[self.delegate selectionDidBeginTextView:self];
			[self setCursorHidden:NO];
			return;
		}
	}
	[self setCursorHidden:YES];
	_status = UZTextViewNoSelection;
	_locationWhenTapBegan = [touch locationInView:self];
	_tapDurationTimer = [NSTimer scheduledTimerWithTimeInterval:_durationToCancelSuperViewScrolling target:self selector:@selector(tapDurationTimerFired:) userInfo:nil repeats:NO];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	[self invalidateTapDurationTimer];
	
	if (_isLocked)
		return;
	
	if (_status == UZTextViewNoSelection) {
		_head = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		_tail = _head;
		[_loupeView setVisible:YES animated:YES];
		_status = UZTextViewSelecting;
		if ([self.delegate respondsToSelector:@selector(selectionDidBeginTextView:)])
			[self.delegate selectionDidBeginTextView:self];
		[self setCursorHidden:YES];
	}
	if (_status == UZTextViewSelecting) {
		_tail = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		[_loupeView updateAtLocation:[touch locationInView:self] textView:self];
	}
	else if (_status == UZTextViewEditingFromSelection) {
		[self setCursorHidden:NO];
		int prev_from = _head;
		_head = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		if (prev_from <= _tail && _head > _tail)
			_tail = _tailWhenBegan + 1;
		else if (prev_from >= _tail && _head < _tail)
			_tail = _tailWhenBegan;
		[_loupeView updateAtLocation:[touch locationInView:self] textView:self];
	}
	else if (_status == UZTextViewEditingToSelection) {
		[self setCursorHidden:NO];
		int prev_end = _tail;
		_tail = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
		if (prev_end >= _head && _head > _tail)
			_head = _headWhenBegan - 1;
		else if (prev_end <= _head && _head < _tail)
			_head = _headWhenBegan;
		[_loupeView updateAtLocation:[touch locationInView:self] textView:self];
	}
	
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[self invalidateTapDurationTimer];
	
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
		NSUInteger tempHead = _head < _tail ? _head : _tail;
		NSUInteger tempTail = _head > _tail ? _head : _tail;
		_head = tempHead;
		_tail = tempTail;
		_status = UZTextViewSelected;
		
		[self setCursorHidden:NO];
		
		[self becomeFirstResponder];
		[[UIMenuController sharedMenuController] setTargetRect:[self fragmentRectForSelectedStringFromIndex:_head toIndex:_tail] inView:self];
		[[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
	}
	_locationWhenTapBegan = CGPointZero;
	[self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesEnded:touches withEvent:event];
}

#pragma mark - Override

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (CGRectContainsPoint(self.bounds, point)) {
		NSMutableArray *rects = [NSMutableArray array];
		
		[rects addObjectsFromArray:[self fragmentRectsForGlyphFromIndex:0 toIndex:self.attributedString.length-1]];
		[rects addObject:[NSValue valueWithCGRect:[self fragmentRectForCursorAtIndex:_head side:UZTextViewLeftEdge]]];
		[rects addObject:[NSValue valueWithCGRect:[self fragmentRectForCursorAtIndex:_tail side:UZTextViewRightEdge]]];
		
		for (NSValue *rectValue in rects) {
			if (CGRectContainsPoint([rectValue CGRectValue], point))
				return [super hitTest:point withEvent:event];
		}
		
		[self setCursorHidden:YES];
		_status = UZTextViewNoSelection;
		[self setNeedsDisplay];
    }
    return nil;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self)
		[self prepareForInitialization];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
    if (self)
		[self prepareForInitialization];
	return self;
}

- (void)drawRect:(CGRect)rect {
	// draw main content
	[self drawContent];
}

@end