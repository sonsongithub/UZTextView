//
//  UZTextView.m
//  Text
//
//  Created by sonson on 2013/06/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "UZTextView.h"

#define NSLogRect(p) NSLog(@"%f,%f,%f,%f",p.origin.x, p.origin.y, p.size.width, p.size.height)
#define NSLogRange(p) NSLog(@"%d,%d",p.location, p.length)

@implementation UZTextView

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
			[[UIColor colorWithRed:1 green:0 blue:0 alpha:0.1] setFill];
			
			NSUInteger start = range.location;
			NSUInteger end = range.location + range.length;
			
			// estimate regions to render
			for (int i = start; i <= end;) {
				NSRange effectiveRange;
				CGRect lineRect = [_layoutManager lineFragmentRectForGlyphAtIndex:i effectiveRange:(NSRangePointer)&effectiveRange];
				
				NSUInteger left = effectiveRange.location > start ? effectiveRange.location : start;
				NSUInteger right = effectiveRange.location + effectiveRange.length <= end ? effectiveRange.location + effectiveRange.length : end;
				
				CGRect r1 = [_layoutManager boundingRectForGlyphRange:NSMakeRange(left, 1) inTextContainer:_textContainer];
				CGRect r2 = [_layoutManager boundingRectForGlyphRange:NSMakeRange(right, 1) inTextContainer:_textContainer];
				
				CGRect r;
				if (r1.origin.y != r2.origin.y)
					r = CGRectMake(r1.origin.x, r1.origin.y, lineRect.origin.x + lineRect.size.width - r1.origin.x, r1.size.height);
				else
					r = CGRectMake(r1.origin.x, r1.origin.y, r2.origin.x + r2.size.width - r1.origin.x, r1.size.height);
				
				CGContextFillRect(context, r);
				
				// forward glyph index pointer, i
				i = effectiveRange.location + effectiveRange.length + 1;
			}
			
		}
	}
}

- (void)drawSelectedTextFragments {
	if (!_isSelecting)
		return;
	
	// re-order start and end index.
	NSUInteger start = _from < _end ? _from : _end;
	NSUInteger end = _from > _end ? _from : _end;
	
	// set drawing color
	[[UIColor colorWithRed:0 green:1 blue:0 alpha:0.1] setFill];
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	NSLog(@"start=%d => end=%d", start, end);
	
	// estimate regions to render
	for (int i = start; i <= end;) {
		NSRange effectiveRange;
		CGRect lineRect = [_layoutManager lineFragmentRectForGlyphAtIndex:i effectiveRange:(NSRangePointer)&effectiveRange];
		NSLog(@"effectiveRange");
		NSLog(@"i=%d", i);
		NSLog(@"start=%d => end=%d", effectiveRange.location, effectiveRange.location + effectiveRange.length	);
		
		NSUInteger left = effectiveRange.location >= i ? effectiveRange.location : i;
		NSUInteger right = effectiveRange.location + effectiveRange.length <= end ? effectiveRange.location + effectiveRange.length : end;
		
		CGGlyph leftGlyph = [_layoutManager glyphAtIndex:left];
		CGGlyph rightGlyph = [_layoutManager glyphAtIndex:right];
		
		NSLog(@"G:%d=>%d", leftGlyph, rightGlyph);
		NSLog(@"I:%d=>%d", left, right);
		
		if (rightGlyph == 65535)
			right-=2;
		else
			right--;
		
		CGRect r1 = [_layoutManager boundingRectForGlyphRange:NSMakeRange(left, 1) inTextContainer:_textContainer];
		CGRect r2 = [_layoutManager boundingRectForGlyphRange:NSMakeRange(right, 1) inTextContainer:_textContainer];
		
		CGRect r;
//		if (r1.origin.y != r2.origin.y)
//			r = CGRectMake(r1.origin.x, r1.origin.y, lineRect.origin.x + lineRect.size.width - r1.origin.x, r1.size.height);
//		else
			r = CGRectMake(r1.origin.x, r1.origin.y, r2.origin.x + r2.size.width - r1.origin.x, r1.size.height);

		CGContextFillRect(context, r);
		
		// forward glyph index pointer, i
		i = effectiveRange.location + effectiveRange.length + 1;
	}
	
	// render cursor, for debug
	CGRect left_cursol = [_layoutManager boundingRectForGlyphRange:NSMakeRange(start, 1) inTextContainer:_textContainer];
	CGRect right_cursol = [_layoutManager boundingRectForGlyphRange:NSMakeRange(end, 1) inTextContainer:_textContainer];
	[[UIColor colorWithRed:0 green:1 blue:0 alpha:0.8] setFill];
	CGContextFillRect(context, left_cursol);
	CGContextFillRect(context, right_cursol);
}

- (void)searchLinkAttribute {
	
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
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	_end = [_layoutManager glyphIndexForPoint:[touch locationInView:self] inTextContainer:_textContainer];
	_isTapping = NO;
	[self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		_layoutManager = [[NSLayoutManager alloc] init];
		_textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
		_textStorage = [[NSTextStorage alloc] init];
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

- (void)drawRect:(CGRect)rect {
    // Drawing code
	[_textContainer setSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
	[_layoutManager drawGlyphsForGlyphRange:NSMakeRange(0, self.attributedString.length) atPoint:CGPointMake(0, 0)];
	[self drawSelectedTextFragments];
	[self drawSelectedLinkFragments];
}

@end
