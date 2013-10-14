//
//  UZTextView.h
//  Text
//
//  Created by sonson on 2013/06/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@class UZLoupeView;
@class UZCursorView;

/** Type of cursor view's direction. */
typedef NS_ENUM(NSUInteger, UZTextViewGlyphEdgeType) {
	/** The cursor is at the left edge of a selected range.  */
	UZTextViewLeftEdge				= 0,
	/** The cursor is at the right edge of a selected range.  */
	UZTextViewRightEdge				= 1
};

/** Status of the current selection range of UZTextView class. */
typedef NS_ENUM(NSUInteger, UZTextViewStatus) {
	/** User does not select any text. */
	UZTextViewNoSelection			= 0,
	/** User selects some text. */
	UZTextViewSelected				= 1,
	/** User is moving the left cursor of a selected range. */
	UZTextViewEditingFromSelection	= 2,
	/** User is moving the right cursor of a selected range. */
	UZTextViewEditingToSelection	= 3,
};

@class UZTextView;

/**
 * UZTextViewDelegate protocol is order to receive selecting, scrolling-related messages for UZTextView objcects.
 * All of the methods in this protocol are optional. 
 * You can use the methods in order to lock parent view's scroll while user selects text on UZTextView object.
 */
@protocol UZTextViewDelegate <NSObject>
/**
 * Tells the delegate that a link attribute has been tapped.
 * \param textView The text view in which the link is tapped.
 * \param value The link attribute data which is specified as NSAttributedString's methods.
 */
- (void)textView:(UZTextView*)textView didClickLinkAttribute:(id)value;

/**
 * Tells the delegate that selecting of the specified text view has begun.
 *
 * You can use this delegate method in order to make its parent view disabled scrolling.
 * \param textView The text view in which selecting began.
 */
- (void)selectionDidBeginTextView:(UZTextView*)textView;

/**
 * Tells the delegate that selecting of the specified text view has ended.
 *
 * You can use this delegate method in order to make its parent view enabled scrolling.
 * \param textView The text view in which selecting ended.
 */
- (void)selectionDidEndTextView:(UZTextView*)textView;
@end

/**
 The UZTextView class implements the behavior for a scrollable, multiline, selectable, clickable text region. 
 The class supports the display of text using custom style and link information.
 
 Create subclass of the class and use UZTextView internal category methods if you want to expand the UZTextView class.
 */
@interface UZTextView : UIView {
	// CoreText
	CTFramesetterRef				_framesetter;
    CTFrameRef						_frame;
	CGRect							_contentRect;
	CFStringTokenizerRef			_tokenizer;
	
	// Tap link attribute
	NSRange							_tappedLinkRange;
	id								_tappedLinkAttribute;
	
	// Highlighted text
	NSArray							*_highlightRanges;
	
	// Tap
	UILongPressGestureRecognizer	*_longPressGestureRecognizer;
	CFTimeInterval					_minimumPressDuration;
	
	// parameter
	NSUInteger						_head;
	NSUInteger						_tail;
	NSUInteger						_headWhenBegan;
	NSUInteger						_tailWhenBegan;
	
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
/**
 * Receiver's delegate.
 * The delegate is sent messages when contents are selected and tapped.
 *
 * See UZTextViewDelegate Protocol Reference for the optional methods this delegate may implement.
 */
@property (nonatomic, assign) id <UZTextViewDelegate> delegate;

/**
 * The contents of the string to be drawn in this view.
 */
@property (nonatomic, copy) NSAttributedString *attributedString;

/**
 * The bounding size required to draw the string.
 */
@property (nonatomic, readonly) CGSize contentSize;

/**
 * The current selection range of the receiver.
 */
@property (nonatomic, assign) NSRange selectedRange;

/**
 * The duration (in seconds) of a wait before text selection will start.
 */
@property (nonatomic, assign) CFTimeInterval minimumPressDuration;

/**
 * Ranges to be highlighted.
 */
@property (nonatomic, copy) NSArray *highlightRanges;

/**
 * Returns the bounding size required to draw the string.
 * \param attributedString Contents of the string to be drawn.
 * \param width The width constraint to apply when computing the string’s bounding rectangle.
 * \return A rectangle whose size component indicates the width and height required to draw the entire contents of the string.
 */
+ (CGSize)sizeForAttributedString:(NSAttributedString*)attributedString withBoundWidth:(float)width;

/**
 * Prepares for reusing an object. You have to call this method before you set another attributed string to the object.
 */
- (void)prepareForReuse;
@end

@interface UZTextView(internal)

- (CGRect)rectForTappingPoint:(CGPoint)point withMargin:(float)margin;

- (void)setCursorHidden:(BOOL)hidden;

- (void)updateLayout;

- (NSRange)selectedRange;

- (void)showUIMenu;

- (BOOL)cancelSelectedText;

- (CGRect)fragmentRectForCursorAtIndex:(int)index side:(UZTextViewGlyphEdgeType)side;

- (NSArray*)fragmentRectsForGlyphFromIndex:(int)fromIndex toIndex:(int)toIndex;

- (CGRect)fragmentRectForSelectedStringFromIndex:(int)fromIndex toIndex:(int)toIndex;

- (void)drawSelectedLinkFragments;

- (void)drawSelectedTextFragmentRectsFromIndex:(int)fromIndex toIndex:(int)toIndex color:(UIColor*)color;

- (void)drawSelectedTextFragmentRectsFromIndex:(int)fromIndex toIndex:(int)toIndex;

- (void)drawStringRectForDebug;

- (void)drawContent;

- (void)didChangeLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer;

- (void)prepareForInitialization;

- (NSRange)rangeOfLinkStringAtPoint:(CGPoint)point;

- (void)setSelectionWithPoint:(CGPoint)point;

- (CFIndex)indexForPoint:(CGPoint)point;
@end
