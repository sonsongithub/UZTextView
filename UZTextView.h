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
 * Delegate
 */
- (void)textView:(UZTextView*)textview didClickLinkAttribute:(id)value;

/**
 * Delegate
 */
- (void)selectionDidBeginTextView:(UZTextView*)textView;

/**
 * Delegate
 */
- (void)selectionDidEndTextView:(UZTextView*)textView;
@end

@interface UZTextView : UIView
/**
 * Delegate
 */
@property (nonatomic, assign) id <UZTextViewDelegate> delegate;

/**
 * String
 */
@property (nonatomic, copy) NSAttributedString *attributedString;

/**
 * Size.
 */
@property (nonatomic, readonly) CGSize contentSize;

/**
 * Duration to 
 */
@property (nonatomic, assign) float durationToCancelSuperViewScrolling;

/**
 * Returns size of content which is passed as NSAttributedString being bound to the width user specified.
 * \param attributedString s
 * \param width d
 * \return Size of content as CGSize.
 */
+ (CGSize)sizeForAttributedString:(NSAttributedString*)attributedString withBoundWidth:(float)width;

/**
 * Prepares for reusing an object. You have to call this method before you set another attributed string to the object.
 */
- (void)prepareForReuse;
@end
