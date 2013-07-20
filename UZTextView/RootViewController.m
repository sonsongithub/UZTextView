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

@interface RootViewController ()

@end

@implementation RootViewController

- (void)selectionDidBeginTextView:(UZTextView*)textView {
	self.tableView.scrollEnabled = NO;
}

- (void)selectionDidEndTextView:(UZTextView*)textView {
	self.tableView.scrollEnabled = YES;
}

- (void)textView:(UZTextView *)textview didClickLinkAttribute:(id)value {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Clicked"
														message:[value objectForKey:@"NSLink"]
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
	[alertView show];
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
	NSLog(@"%@", result);
	NSMutableArray *buf = [NSMutableArray array];
	for (id obj in result) {
		NSLog(@"%@", obj[@"text"]);
		Tweet *tweet = [[Tweet alloc] init];
		[buf addObject:tweet];
		tweet.text = obj[@"text"];
		tweet.attributedString = [[NSMutableAttributedString alloc] initWithString:tweet.text];
		tweet.height = [UZTextView sizeForAttributedString:tweet.attributedString withBoundWidth:320].height;
	}
	_tweets = [NSArray arrayWithArray:buf];
	[self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if ([[NSFileManager defaultManager] isReadableFileAtPath:[self path]]) {
		NSData *data = [NSData dataWithContentsOfFile:[self path]];
		[self updateWithData:data];
	}
	else {
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
						[self updateWithData:responseData];
						[responseData writeToFile:[self path] atomically:NO];
					}];
				}
			}
		}];
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
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
	
	cell.textView.attributedString = tweet.attributedString;
	cell.textView.delegate = self;
	
    return cell;
}

@end
