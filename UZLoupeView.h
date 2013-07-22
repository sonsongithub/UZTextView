//
//  UZLoupeView.h
//  UZTextView
//
//  Created by sonson on 2013/07/10.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UZLoupeView : UIView {
	float		_loupeRadius;
	UIImage		*_image;
}
- (id)initWithRadius:(float)radius;
- (void)updateAtLocation:(CGPoint)location textView:(UIView*)textView;
- (void)updateLoupeWithImage:(UIImage*)image;
- (void)setVisible:(BOOL)visible animated:(BOOL)animated;
@end
