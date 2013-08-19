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
@class UZCursorView;

@protocol UZTextViewDelegate <NSObject>
- (void)textView:(UZTextView*)textview didClickLinkAttribute:(id)value;
- (void)selectionDidBeginTextView:(UZTextView*)textView;
- (void)selectionDidEndTextView:(UZTextView*)textView;
@end

@interface UZTextView : UIView
@property (nonatomic, assign) id <UZTextViewDelegate> delegate;
@property (nonatomic, copy) NSAttributedString *attributedString;
@property (nonatomic, readonly) CGSize contentSize;
@property (nonatomic, assign) float durationToCancelSuperViewScrolling;
+ (CGSize)sizeForAttributedString:(NSAttributedString*)attributedString withBoundWidth:(float)width;
- (void)prepareForReuse;
@end
