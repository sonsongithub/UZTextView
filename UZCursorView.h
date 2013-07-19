//
//  UZCursorView.h
//  UZTextView
//
//  Created by sonson on 2013/07/19.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _UZTextViewCursorDirection {
	UZTextViewUpCursor		= 0,
	UZTextViewDownCursor	= 1
}UZTextViewCursorDirection;

@interface UZCursorView : UIView {
	UZTextViewCursorDirection	_direction;
	float						_cursorCirclrRadius;
	float						_cursorLineWidth;
}
- (id)initWithCursorDirection:(UZTextViewCursorDirection)direction;
@end
