//
//  ViewController.m
//  ParagraphStyle
//
//  Created by sonson on 2013/11/15.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "ViewController.h"

#import "UZTextView.h"

@interface ViewController () {
	IBOutlet UZTextView *_textView;
	
	IBOutlet UISlider *_maximumLineHeightSlider;
	IBOutlet UISlider *_minimumLineHeightSlider;
	IBOutlet UISlider *_lineSpacingSlider;
	IBOutlet UISlider *_paragraphSpacingSlider;
	IBOutlet UISlider *_paragraphSpacingBeforeSlider;
	IBOutlet UISlider *_lineHeightMultipleSlider;
	IBOutlet UISlider *_fontSizeSlider;
	
	IBOutlet UILabel *_maximumLineHeightLabel;
	IBOutlet UILabel *_minimumLineHeightLabel;
	IBOutlet UILabel *_lineSpacingLabel;
	IBOutlet UILabel *_paragraphSpacingLabel;
	IBOutlet UILabel *_paragraphSpacingBeforeLabel;
	IBOutlet UILabel *_lineHeightMultipleLabel;
	IBOutlet UILabel *_fontSizeLabel;
}
@end

@implementation ViewController

- (void)updateAttributes {
	NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"あのイーハトーヴォの\nすきとおった風、\n夏でも底に冷たさをもつ青いそら、\nうつくしい森で飾られたモーリオ市、\n郊外のぎらぎらひかる草の波。\n祇辻飴葛蛸鯖鰯噌庖箸\nABCDEFGHIJKLM\n\nabcdefghijklm\n1234567890いろはにほへと　ちりぬるを わかよたれそ　つねならむ うゐのおくやま　けふこえて あさきゆめみし　ゑひもせす 色はにほへど　散りぬるを 我が世たれぞ　常ならむ 有為の奥山　　今日越えて 浅き夢見じ　　酔ひもせず"];
	
	NSMutableParagraphStyle *style = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
	
	style.maximumLineHeight = _maximumLineHeightSlider.value;
	style.minimumLineHeight = _minimumLineHeightSlider.value;
	style.lineSpacing = _lineSpacingSlider.value;
	style.paragraphSpacing = _paragraphSpacingSlider.value;
	style.paragraphSpacingBefore = _paragraphSpacingBeforeSlider.value;
	style.lineHeightMultiple = _lineHeightMultipleSlider.value;
	
	UIFont *font = [UIFont systemFontOfSize:_fontSizeSlider.value];
	
	style.maximumLineHeight = _fontSizeSlider.value;
	style.minimumLineHeight = _fontSizeSlider.value;
	
	[string addAttributes:@{NSFontAttributeName:font, NSParagraphStyleAttributeName:style} range:NSMakeRange(0, string.length)];
	
	UIEdgeInsets margin = UIEdgeInsetsMake(10, 10, 10, 10);
	CGSize s = [UZTextView sizeForAttributedString:string withBoundWidth:_textView.frame.size.width margin:margin];
	_textView.margin = margin;
	
	CGRect r = _textView.frame;
	r.size.height = s.height;
	_textView.frame = r;
	
	_textView.attributedString = string;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self updateAttributes];
}

- (IBAction)maximumLineHeight:(id)sender {
	_maximumLineHeightLabel.text = [@(_maximumLineHeightSlider.value) stringValue];
	[self updateAttributes];
}

- (IBAction)minimumLineHeight:(id)sender {
	_minimumLineHeightLabel.text = [@(_minimumLineHeightSlider.value) stringValue];
	[self updateAttributes];
}

- (IBAction)lineSpacing:(id)sender {
	_lineSpacingLabel.text = [@(_lineSpacingSlider.value) stringValue];
	[self updateAttributes];
}

- (IBAction)paragraphSpacing:(id)sender {
	_paragraphSpacingLabel.text = [@(_paragraphSpacingSlider.value) stringValue];
	[self updateAttributes];
}

- (IBAction)paragraphSpacingBefore:(id)sender {
	_paragraphSpacingBeforeLabel.text = [@(_paragraphSpacingBeforeSlider.value) stringValue];
	[self updateAttributes];
}

- (IBAction)lineHeightMultiple:(id)sender {
	_lineHeightMultipleLabel.text = [@(_lineHeightMultipleSlider.value) stringValue];
	[self updateAttributes];
}

- (IBAction)fontSize:(id)sender {
	_fontSizeLabel.text = [@(_fontSizeSlider.value) stringValue];
	[self updateAttributes];
}

@end
