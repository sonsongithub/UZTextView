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

- (void)textView:(UZTextView*)textview didClickLinkAttribute:(id)value;

@end

@interface UZTextView : UIView {
	NSLayoutManager *_layoutManager;
	NSTextContainer *_textContainer;
	NSTextStorage *_textStorage;
	
	BOOL _isSelecting;
	BOOL _isTapping;
	
	NSUInteger _from;
	NSUInteger _end;
	UITouch *_touch;
}

@property (nonatomic, assign) id <UZTextViewDelegate> delegate;
@property (nonatomic, strong) NSAttributedString *attributedString;

@end
