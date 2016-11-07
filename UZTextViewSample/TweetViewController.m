//
//  TweetViewController.m
//  UZTextView
//
//  Created by sonson on 2013/07/25.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "TweetViewController.h"

#import "UZTextView.h"
#import "Tweet.h"
#import "SEImageCache.h"
#import "WebViewController.h"

@interface TweetViewController  () <UZTextViewDelegate>

@end

@implementation TweetViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.textView.backgroundColor = [UIColor whiteColor];
	self.textView.attributedString = self.tweet.attributedString;
    self.textView.delegate = self;
	
	NSURL *iconURL = [NSURL URLWithString:self.tweet.info[@"user"][@"profile_image_url_https"]];
    UIImage *iconImage = [[SEImageCache sharedInstance] imageForURL:iconURL
                                                       defaultImage:[NSImage imageNamed:@"default_user_icon"]
                                                    completionBlock:^(NSImage *image, NSError *error)
                          {
                              if (image) {
								  self.iconImageView.image = image;
                              }
                          }];
	self.iconImageView.image = iconImage;
	[self.nameButton setTitle:self.tweet.info[@"user"][@"screen_name"] forState:UIControlStateNormal];
	[self.nameButton sizeToFit];
}

- (void)textView:(UZTextView* __nonnull)textView didLongTapLinkAttribute:(id __nullable)value {
}

- (void)selectionDidBeginTextView:(UZTextView*)textView {
}

- (void)selectionDidEndTextView:(UZTextView*)textView {
}

- (void)textView:(UZTextView *)textview didClickLinkAttribute:(id)value {
	_URLString = [value objectForKey:@"NSLink"];
	[self performSegueWithIdentifier:@"WebViewControllerSegue" sender:nil];
}

- (void)didTapTextDoesNotIncludeLinkTextView:(UZTextView*)textView {
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"WebViewControllerSegue"]) {
		WebViewController *controller = (WebViewController*)[((UINavigationController*)segue.destinationViewController) topViewController];
		controller.URL = [NSURL URLWithString:_URLString];
		_URLString = nil;
	}
}

- (IBAction)dismissViewController:(UIStoryboardSegue*)segue {
}

@end
