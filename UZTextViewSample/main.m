//
//  main.m
//  UZTextView
//
//  Created by sonson on 2013/06/16.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"


typedef int (*PYStdWriter)(void *, const char *, int);
static PYStdWriter _oldStdWrite;

int __pyStderrWrite(void *inFD, const char *buffer, int size)
{
    if ( strncmp(buffer, "AssertMacros:", 13) == 0 ) {
        return 0;
    }
    return _oldStdWrite(inFD, buffer, size);
}

int main(int argc, char * argv[]) {
		_oldStdWrite = stderr->_write;
		stderr->_write = __pyStderrWrite;
	@autoreleasepool {
	    return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
	}
}
