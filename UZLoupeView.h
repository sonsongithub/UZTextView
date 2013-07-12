//
//  UZLoupeView.h
//  UZTextView
//
//  Created by sonson on 2013/07/10.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UZTextView;

@interface UZLoupeView : UIView {
	UZTextView	*_textView;
	float		_radius;
	UIImage		*_image;
}
- (void)update:(UIImage*)image;
- (void)setVisible:(BOOL)visible animated:(BOOL)animated;
@end
