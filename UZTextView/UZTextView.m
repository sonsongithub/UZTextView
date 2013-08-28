//
//  UZTextView.m
//  Text
//
//  Created by sonson on 2013/06/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "UZTextView.h"

#import <CoreText/CoreText.h>

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
	UZTextViewSelected				= 1,
	UZTextViewEditingFromSelection	= 2,
	UZTextViewEditingToSelection	= 3,
}UZTextViewStatus;

@interface UZTextView() {
	// CoreText
	CTFramesetterRef				_framesetter;
    CTFrameRef						_frame;
	CGRect							_contentRect;
	CFStringTokenizerRef			_tokenizer;
	
	// Tap link attribute
	NSRange							_tappedLinkRange;
	id								_tappedLinkAttribute;
	
	// Tap
	UILongPressGestureRecognizer	*_longPressGestureRecognizer;
	
	// parameter
	NSUInteger						_head;
	NSUInteger						_tail;
	NSUInteger						_headWhenBegan;
	NSUInteger						_tailWhenBegan;
	
	CFIndex							_testCaret;
	
	UZTextViewStatus				_status;
	BOOL							_isLocked;
	
	// child view
	UZLoupeView						*_loupeView;
	UZCursorView					*_leftCursor;
	UZCursorView					*_rightCursor;
	
	// tap event control
	CGPoint							_locationWhenTapBegan;
	
	// invaliables
	float							_cursorMargin;
	float							_tintAlpha;
	float							_durationToCancelSuperViewScrolling;
}
@end
	
@implementation UZTextView

- (void)releaseCoreText {
	if (_frame) {
		CFRelease(_frame);
		_frame = nil;
	}
	if (_framesetter) {
		CFRelease(_framesetter);
		_framesetter = nil;
	}
}

- (void)releaseTokenizer {
	if (_tokenizer) {
		CFRelease(_tokenizer);
		_tokenizer = NULL;
	}
}

#pragma mark - Class method to estimate attributed string size

+ (CGSize)sizeForAttributedString:(NSAttributedString*)attributedString withBoundWidth:(float)width {
	// CoreText
	CTFramesetterRef _framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
	CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter,
                                                                    CFRangeMake(0, attributedString.length),
                                                                    NULL,
                                                                    CGSizeMake(width, CGFLOAT_MAX),
                                                                    NULL);
	CFRelease(_framesetter);
	return frameSize;
}

#pragma mark - Instance method

- (void)setCursorHidden:(BOOL)hidden {
	[_leftCursor setFrame:[self fragmentRectForCursorAtIndex:_head side:UZTextViewLeftEdge]];
	[_rightCursor setFrame:[self fragmentRectForCursorAtIndex:_tail side:UZTextViewRightEdge]];
	_leftCursor.hidden = hidden;
	_rightCursor.hidden = hidden;
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
	[self prepareForReuse];
	
	_attributedString = attributedString;
	
	// CoreText
	if (_framesetter)
        CFRelease(_framesetter);
	
	[self releaseTokenizer];
    
    CFAttributedStringRef p = (__bridge CFAttributedStringRef)attributedString;
    if (p) {
        _framesetter = CTFramesetterCreateWithAttributedString(p);
    }
	else {
        p = CFAttributedStringCreate(NULL, CFSTR(""), NULL);
        _framesetter = CTFramesetterCreateWithAttributedString(p);
        CFRelease(p);
    }
	if (_frame) {
        CFRelease(_frame);
    }
    
	CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter,
                                                                    CFRangeMake(0, _attributedString.length),
                                                                    NULL,
                                                                    CGSizeMake(226, CGFLOAT_MAX),
                                                                    NULL);
	_contentRect = CGRectZero;
	_contentRect.size = frameSize;
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, _contentRect);
	_frame = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, 0), path, NULL);
	CGPathRelease(path);
	
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
		NSArray *rects = [self fragmentRectsForGlyphFromIndex:index toIndex:index];
		CGRect rect = CGRectZero;
		if ([rects count]) {
			rect = [[rects objectAtIndex:0] CGRectValue];
			rect.size.width = 0;
		}
		return CGRectInset(rect, -_cursorMargin, -_cursorMargin);
	}
	else {
		NSArray *rects = [self fragmentRectsForGlyphFromIndex:index toIndex:index];
		CGRect rect = CGRectZero;
		if ([rects count]) {
			rect = [[rects objectAtIndex:0] CGRectValue];
			rect.origin.x += rect.size.width;
			rect.size.width = 0;
		}
		return CGRectInset(rect, -_cursorMargin, -_cursorMargin);
	}
}

- (NSArray*)fragmentRectsForGlyphFromIndex:(int)fromIndex toIndex:(int)toIndex {
	if (!(fromIndex <= toIndex && fromIndex >=0 && toIndex >=0))
		return @[];
	
	CFArrayRef lines = CTFrameGetLines(_frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, 0), lineOrigins);
	
	NSMutableArray *fragmentRects = [NSMutableArray array];
	
	NSRange range = NSMakeRange(fromIndex, toIndex - fromIndex + 1);
	
	if (range.length <= 0)
		range.length = 1;
    
    for (NSInteger index = 0; index < lineCount; index++) {
        CGPoint origin = lineOrigins[index];
        CTLineRef line = CFArrayGetValueAtIndex(lines, index);
        
		CGRect rect = CGRectZero;
		CFRange stringRange = CTLineGetStringRange(line);
		NSRange intersectionRange = NSIntersectionRange(range, NSMakeRange(stringRange.location, stringRange.length));
		CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        CGFloat width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        
        CGRect lineRect = CGRectMake(origin.x,
                                     ceilf(origin.y - descent),
                                     width,
                                     ceilf(ascent + descent));
        lineRect.origin.y = _contentRect.size.height - CGRectGetMaxY(lineRect);
		
		if (intersectionRange.length > 0) {
			CGFloat startOffset = CTLineGetOffsetForStringIndex(line, intersectionRange.location, NULL);
			CGFloat endOffset = CTLineGetOffsetForStringIndex(line, NSMaxRange(intersectionRange), NULL);
			
			rect = lineRect;
			rect.origin.x += startOffset;
			rect.size.width -= (rect.size.width - endOffset);
			rect.size.width = rect.size.width - startOffset;
			[fragmentRects addObject:[NSValue valueWithCGRect:rect]];
		}
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
	int tappedIndex = [self indexForPoint:_locationWhenTapBegan];
	NSDictionary *dict = [self.attributedString attributesAtIndex:tappedIndex effectiveRange:&range];
	if (dict[NSLinkAttributeName]) {
		NSLogRange(range);
		
		
		NSArray *rects = [self fragmentRectsForGlyphFromIndex:tappedIndex toIndex:tappedIndex+1];
		CGRect rect = CGRectZero;
		if ([rects count]) {
			rect = [[rects objectAtIndex:0] CGRectValue];
			rect.size.width = 0;
		}

		if (CGRectContainsPoint(rect, _locationWhenTapBegan)) {
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
	for (NSValue *rectValue in fragmentRects) {
		CGContextFillRect(context, [rectValue CGRectValue]);
	}
}

- (void)drawContent {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// draw text
	CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0, _contentRect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CTFrameDraw(_frame, context);
	CGContextRestoreGState(context);
	
	// draw selected strings
	if (_status > 0)
		[self drawSelectedTextFragmentRectsFromIndex:_head toIndex:_tail];
	
	// draw tapped link range background
	if (_tappedLinkRange.length > 0)
		[self drawSelectedTextFragmentRectsFromIndex:_tappedLinkRange.location toIndex:_tappedLinkRange.location + _tappedLinkRange.length - 1];
}

#pragma mark - UILongPressGesture

- (void)didChangeLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
	DNSLogMethod
	DNSLog(@"%d", gestureRecognizer.state);
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		[self setSelectionWithPoint:[gestureRecognizer locationInView:self]];
		_status = UZTextViewSelected;
		[self setCursorHidden:YES];
		[self setNeedsDisplay];
		[_loupeView setVisible:YES animated:YES];
		[_loupeView updateAtLocation:[gestureRecognizer locationInView:self] textView:self];
    }
	else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
		[self setSelectionWithPoint:[gestureRecognizer locationInView:self]];
		[self setCursorHidden:YES];
		[self setNeedsDisplay];
		[_loupeView setVisible:YES animated:YES];
		[_loupeView updateAtLocation:[gestureRecognizer locationInView:self] textView:self];
    }
	else if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
		[self setCursorHidden:NO];
		[self setNeedsDisplay];
		[_loupeView setVisible:NO animated:YES];
		[_loupeView updateAtLocation:[gestureRecognizer locationInView:self] textView:self];
    }
}

#pragma mark - Preparation

- (void)prepareForInitialization {
	// init invaliables
	_cursorMargin = 14;
	_tintAlpha = 0.5;
	_durationToCancelSuperViewScrolling = 0.25;
	
	_longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didChangeLongPressGesture:)];
	_longPressGestureRecognizer.minimumPressDuration = 0.75;
	[self addGestureRecognizer:_longPressGestureRecognizer];
	
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
	
	_leftCursor.hidden = YES;
	_rightCursor.hidden = YES;
	_locationWhenTapBegan = CGPointZero;
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

#pragma mark - CoreText

- (NSRange)rangeOfLinkStringAtPoint:(CGPoint)point {
	__block NSRange resultRange = NSMakeRange(0, 0);
	
	_tappedLinkAttribute = nil;
	
    CFIndex index = [self indexForPoint:point];
    if (index == kCFNotFound)
        return resultRange;
    
	NSUInteger length = self.attributedString.length;
    [self.attributedString enumerateAttribute:NSLinkAttributeName
                                      inRange:NSMakeRange(0, length)
                                      options:0
                                   usingBlock:^(id value, NSRange range, BOOL *stop)
     {
         if (value && NSLocationInRange(index, range)) {
			 resultRange = range;
			 _tappedLinkAttribute = value;
         }
     }];
	return resultRange;
}

- (void)setSelectionWithPoint:(CGPoint)point {
    CFIndex index = [self indexForPoint:point];
    if (index == kCFNotFound)
        return;
    
    CFStringRef string = (__bridge CFStringRef)self.attributedString.string;
    CFRange range = CFRangeMake(0, CFStringGetLength(string));
  
	if (_tokenizer == NULL) {
		_tokenizer = CFStringTokenizerCreate(
                                                             NULL,
                                                             string,
                                                             range,
                                                             kCFStringTokenizerUnitWordBoundary,
                                                             NULL);
	}
    CFStringTokenizerTokenType tokenType = CFStringTokenizerGoToTokenAtIndex(_tokenizer, 0);
    while (tokenType != kCFStringTokenizerTokenNone || range.location + range.length < CFStringGetLength(string)) {
        range = CFStringTokenizerGetCurrentTokenRange(_tokenizer);
        CFIndex first = range.location;
        CFIndex second = range.location + range.length - 1;
        if (first != kCFNotFound && first <= index && index <= second) {
			_head = first;
			_tail = second;
			DNSLog(@"%d->%d", _head, _tail);
        }
        
        tokenType = CFStringTokenizerAdvanceToNextToken(_tokenizer);
    }
}

- (CFIndex)indexForPoint:(CGPoint)point {
	CFArrayRef lines = CTFrameGetLines(_frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, 0), lineOrigins);
	
	CGRect previousLineRect = CGRectZero;
    
    for (NSInteger index = 0; index < lineCount; index++) {
        CGPoint origin = lineOrigins[index];
        CTLineRef line = CFArrayGetValueAtIndex(lines, index);
		
		CFRange lineCFRange = CTLineGetStringRange(line);
		NSRange lineRange = NSMakeRange(lineCFRange.location, lineCFRange.length);
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        CGFloat width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        
        CGRect lineRect = CGRectMake(origin.x,
                                     ceilf(origin.y - descent),
                                     width,
                                     ceilf(ascent + descent));
		lineRect.origin.y = _contentRect.size.height - CGRectGetMaxY(lineRect);
		previousLineRect = lineRect;		if (CGRectContainsPoint(lineRect, point)) {
			CFIndex result = CTLineGetStringIndexForPosition(line, point);
			DNSLog(@"candidate=%ld", result);
			DNSLogRange(lineRange);
			if (result != kCFNotFound && NSLocationInRange(result, lineRange))
				return result;
		}
    }
	return kCFNotFound;
}

#pragma mark - Touch event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	DNSLogMethod
	UITouch *touch = [touches anyObject];
	[self setNeedsDisplay];
	[[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
	
	_headWhenBegan = _head;
	_tailWhenBegan = _tail;
	if (CGRectContainsPoint([self fragmentRectForCursorAtIndex:_head side:UZTextViewLeftEdge], [touch locationInView:self])) {
		_status = UZTextViewEditingFromSelection;
		[_loupeView setVisible:YES animated:YES];
		[_loupeView updateAtLocation:[touch locationInView:self] textView:self];
		if ([self.delegate respondsToSelector:@selector(selectionDidBeginTextView:)])
			[self.delegate selectionDidBeginTextView:self];
		[self setCursorHidden:NO];
	}
	else if (CGRectContainsPoint([self fragmentRectForCursorAtIndex:_tail side:UZTextViewRightEdge], [touch locationInView:self])) {
		_status = UZTextViewEditingToSelection;
		[_loupeView setVisible:YES animated:YES];
		[_loupeView updateAtLocation:[touch locationInView:self] textView:self];
		if ([self.delegate respondsToSelector:@selector(selectionDidBeginTextView:)])
			[self.delegate selectionDidBeginTextView:self];
		[self setCursorHidden:NO];
	}
	else {
		_tappedLinkRange = [self rangeOfLinkStringAtPoint:[touch locationInView:self]];
		[self setNeedsDisplay];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	DNSLogMethod
	UITouch *touch = [touches anyObject];
	if (_status == UZTextViewEditingFromSelection) {
		int newHead = [self indexForPoint:[touch locationInView:self]];
		if (newHead != kCFNotFound) {
			if (newHead <= _tail) {
				_head = newHead;
				[_loupeView updateAtLocation:[touch locationInView:self] textView:self];
			}
		}
		[self setCursorHidden:NO];
	}
	else if (_status == UZTextViewEditingToSelection) {
		int newTail = [self indexForPoint:[touch locationInView:self]];
		[self setCursorHidden:NO];
		if (newTail != kCFNotFound) {
			if (newTail >= _head) {
				_tail = newTail;
				[_loupeView updateAtLocation:[touch locationInView:self] textView:self];
			}
		}
		[self setCursorHidden:NO];
	}
	_tappedLinkRange = NSMakeRange(0, 0);
	_tappedLinkAttribute = nil;
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	DNSLogMethod
	if (_tappedLinkAttribute) {
		DNSLog(@"%@", _tappedLinkAttribute);
	}
	
	_tappedLinkRange = NSMakeRange(0, 0);
	
	if (_status == UZTextViewEditingFromSelection) {
		[_loupeView setVisible:NO animated:YES];
	}
	else if (_status == UZTextViewEditingToSelection) {
		[_loupeView setVisible:NO animated:YES];
	}
	
	if (_status > 0)
		_status = UZTextViewSelected;
	
	if ([self.delegate respondsToSelector:@selector(selectionDidEndTextView:)])
		[self.delegate selectionDidEndTextView:self];
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

- (CGSize)contentSize {
	return _contentRect.size;
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
