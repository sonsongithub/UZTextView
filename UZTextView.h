//
//  UZTextView.h
//  Text
//
//  Created by sonson on 2013/06/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UZTextView;
@class UZLoupeView;

typedef enum _UZTextViewStatus {
	UZTextViewNoSelection			= 0,
	UZTextViewSelecting				= 1,
	UZTextViewSelected				= 2,
	UZTextViewEditingFromSelection	= 3,
	UZTextViewEditingToSelection	= 4,
}UZTextViewStatus;

@protocol UZTextViewDelegate <NSObject>

- (void)textView:(UZTextView*)textview didClickLinkAttribute:(id)value;

@end

@interface UZTextView : UIView {
	// text manager
	NSLayoutManager		*_layoutManager;
	NSTextContainer		*_textContainer;
	NSTextStorage		*_textStorage;
	
	// parameter
	UZTextViewStatus	_status;
	NSUInteger			_from;
	NSUInteger			_end;
	NSUInteger			_fromWhenBegan;
	NSUInteger			_endWhenBegan;
	
	// child view
	UZLoupeView			*_loupeView;
	
	// tap event control
	CGPoint				_locationWhenTapBegan;
	
	// invaliables
	float				_loupeRadius;
	float				_cursorMargin;
	float				_tintAlpha;
	float				_cursorCirclrRadius;
	float				_cursorLineWidth;
}

@property (nonatomic, assign) id <UZTextViewDelegate> delegate;
@property (nonatomic, strong) NSAttributedString *attributedString;

@end
