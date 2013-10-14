//
//  Tweet.h
//  UZTextView
//
//  Created by sonson on 2013/07/16.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tweet : NSObject

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSAttributedString *attributedString;
@property (nonatomic, strong) NSDictionary *info;
@property (nonatomic, strong) NSArray *highlightRanges;
@property (nonatomic, assign) float height;

@end
