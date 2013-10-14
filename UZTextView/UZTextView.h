//
//  UZTextView.h
//  Text
//
//  Created by sonson on 2013/06/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UZTextView;

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

@interface UZTextView : UIView
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
