//
//  RootViewController.m
//  UZTextView
//
//  Created by sonson on 2013/07/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "RootViewController.h"

#import <Accounts/Accounts.h>
#import <Social/Social.h>

#import "TextCell.h"
#import "UZTextView.h"
#import "Tweet.h"
#import "SEImageCache.h"
#import "WebViewController.h"
#import "TweetViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (NSMutableAttributedString*)parse:(NSString*)text {
	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:text];
	NSError *error = nil;
	NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:@"(http[s]?://[a-zA-Z0-9/.,?_+~=%&:;!#\\-]+)|(@[a-zA-Z0-9_]+)|(#[a-zA-Z0-9_]+)"
															 options:0
															   error:&error];
	NSArray *array = [reg matchesInString:text options:0 range:NSMakeRange(0, text.length)];
	for (NSTextCheckingResult *result in array) {
		if ([result numberOfRanges]) {
			if ([result rangeAtIndex:1].length) {
				// http
				[attrString setAttributes:@{NSLinkAttributeName:[text substringWithRange:[result range]], @"type":@"link"} range:[result range]];
			}
			if ([result rangeAtIndex:2].length) {
				// reply
				[attrString setAttributes:@{NSLinkAttributeName:[text substringWithRange:[result range]], @"type":@"reply"} range:[result range]];
			}
			if ([result rangeAtIndex:3].length) {
				// hash
				[attrString setAttributes:@{NSLinkAttributeName:[text substringWithRange:[result range]], @"type":@"hash"} range:[result range]];
			}
		}
	}
	return attrString;
}

- (void)selectionDidBeginTextView:(UZTextView*)textView {
	self.tableView.scrollEnabled = NO;
}

- (void)selectionDidEndTextView:(UZTextView*)textView {
	self.tableView.scrollEnabled = YES;
}

- (void)textView:(UZTextView *)textview didClickLinkAttribute:(id)value {
	NSLog(@"%@", value);
	if ([value[@"type"] isEqualToString:@"link"]) {
		_URLString = [value objectForKey:@"NSLink"];
	}
	if ([value[@"type"] isEqualToString:@"reply"]) {
		NSString *name = [[value objectForKey:@"NSLink"] substringFromIndex:1];
		_URLString = [NSString stringWithFormat:@"https://twitter.com/%@", name];
	}
	if ([value[@"type"] isEqualToString:@"hash"]) {
		NSString *hash = [[value objectForKey:@"NSLink"] substringFromIndex:1];
		_URLString = [NSString stringWithFormat:@"https://twitter.com/search?q=%%23%@", hash];
	}
	[self performSegueWithIdentifier:@"WebViewControllerSegue" sender:nil];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSString*)path {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [NSString stringWithFormat:@"%@/tweets.json", documentsDirectory];
}

- (void)updateWithData:(NSData*)data {
	NSError *parseError = nil;
	NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
	NSMutableArray *buf = [NSMutableArray array];
	for (id obj in result) {
		Tweet *tweet = [[Tweet alloc] init];
		[buf addObject:tweet];
		tweet.info = obj;
		tweet.text = obj[@"text"];
		tweet.attributedString = [self parse:tweet.text];
	}
	_tweets = [NSArray arrayWithArray:buf];
	[self updateLayout];
	dispatch_async(dispatch_get_main_queue(), ^(void){
		[self.tableView reloadData];
	});
}

- (void)updateLayout {
	float width = 226;
	if ([[self.tableView visibleCells] count]) {
		TextCell *cell = (TextCell*)[[self.tableView visibleCells] objectAtIndex:0];
		width = cell.textView.frame.size.width;
	}
	for (Tweet *tweet in _tweets) {
		float height = [UZTextView sizeForAttributedString:tweet.attributedString withBoundWidth:width].height + 36;
		tweet.height = height < 58 ? 58 : height;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	ACAccountStore *accountStore = [[ACAccountStore alloc]init];
	ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
	[accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
		if (granted) {
			NSArray *accounts = [accountStore accountsWithAccountType:accountType];
			if (accounts.count > 0) {
				ACAccount *account = accounts[0];
				NSURL *requestURL = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/home_timeline.json"];
				NSDictionary *params = @{@"count": @"200", @"include_entities": @"true"};
				SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
														requestMethod:SLRequestMethodGET
																  URL:requestURL
														   parameters:params];
				request.account = account;
				[request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
					if (error) {
						if ([[NSFileManager defaultManager] isReadableFileAtPath:[self path]]) {
							NSData *data = [NSData dataWithContentsOfFile:[self path]];
							[self updateWithData:data];
						}
					}
					else {
						[self updateWithData:responseData];
						[responseData writeToFile:[self path] atomically:NO];
					}
				}];
			}
		}
	}];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self updateLayout];
	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"WebViewControllerSegue"]) {
		WebViewController *controller = (WebViewController*)[((UINavigationController*)segue.destinationViewController) topViewController];
		controller.URL = [NSURL URLWithString:_URLString];
		_URLString = nil;
	}
	if ([segue.identifier isEqualToString:@"TweetViewControllerSegue"]) {
		Tweet *tweet = [_tweets objectAtIndex:self.tableView.indexPathForSelectedRow.row];
		TweetViewController *controller = (TweetViewController*)segue.destinationViewController;
		controller.tweet = tweet;
	}
}

- (IBAction)dismissViewController:(UIStoryboardSegue*)segue {
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	Tweet *tweet = [_tweets objectAtIndex:indexPath.row];
	return tweet.height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_tweets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    TextCell *cell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
	Tweet *tweet = [_tweets objectAtIndex:indexPath.row];
	[cell.nameButton setTitle:tweet.info[@"user"][@"screen_name"] forState:UIControlStateNormal];
	cell.textView.attributedString = tweet.attributedString;
	cell.textView.delegate = self;
	[cell.nameButton sizeToFit];
	
	NSURL *iconURL = [NSURL URLWithString:tweet.info[@"user"][@"profile_image_url_https"]];
    UIImage *iconImage = [[SEImageCache sharedInstance] imageForURL:iconURL
                                                       defaultImage:[NSImage imageNamed:@"default_user_icon"]
                                                    completionBlock:^(NSImage *image, NSError *error)
                          {
                              if (image && [cell.profileIconURL isEqual:iconURL]) {
                                  cell.iconImageView.image = image;
                              }
                          }];
	cell.iconImageView.image = iconImage;
	cell.profileIconURL = iconURL;
	
	cell.textView.selectedRange = NSMakeRange(0, 2);
	
    return cell;
}

@end
