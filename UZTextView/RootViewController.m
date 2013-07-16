//
//  RootViewController.m
//  UZTextView
//
//  Created by sonson on 2013/07/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "RootViewController.h"

#import "TextCell.h"
#import "UZTextView.h"

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

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    TextCell *cell = (TextCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
	
	NSString *string = @"hoge\rhoge\rhttp://www.yahoo.co.jp\r\rあれから吉田悠一012345678901234567890123456789012345678901234567890123456789hoge>>190";
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
	[attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Arial"size:20] range:NSMakeRange(0, string.length)];
	
	[attributedString addAttribute:NSLinkAttributeName value:@"http://www.yahoo.co.jp" range:NSMakeRange(10, 22)];
	[attributedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleNone) range:NSMakeRange(10, 22)];
	
	cell.textView.attributedString = attributedString;
	cell.textView.delegate = self;
	
    return cell;
}

@end
