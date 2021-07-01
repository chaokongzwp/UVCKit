//
//  UVCControllerUIBox.m
//  UVCKit
//
//  Created by 朝空 on 2021/6/29.
//  Copyright © 2021 Vidvox. All rights reserved.
//

#import "UVCControllerUIBox.h"

@implementation UVCControllerUIBox

- (id) initWithFrame:(NSRect)f	{
	if (self = [super initWithFrame:f])	{
		enabled = YES;
		valSlider = nil;
		valLabel = nil;
		val = 0;
		min = 0;
		max = 0;
		
		
		self.titlePosition = NSNoTitle;
		[self setBorderType:NSNoBorder];
		[self setBoxType:NSBoxSecondary];
		
		NSView			*contentView = [self contentView];
		
		valSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(0,0,400,28)];
		[[valSlider cell] setControlSize:NSMiniControlSize];
		[valSlider setContinuous:YES];
		[valSlider setTarget:self];
		[valSlider setAction:@selector(uiItemUsed:)];
		valSlider.trackFillColor = [NSColor blueColor];
		
		valLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,200,28)];
		[valLabel setFont:[NSFont systemFontOfSize:14]];
		
		NSNumberFormatter	*formatter = [[NSNumberFormatter alloc] init];
		[valLabel setFormatter:formatter];;
		[valLabel setTarget:self];
		[valLabel setAction:@selector(uiItemUsed:)];
		valLabel.bezeled = NO;
		valLabel.backgroundColor = [NSColor clearColor];
		[valLabel setStringValue:@"100"];
		
		titleField = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,200,28)];
		[titleField setFont:[NSFont systemFontOfSize:14]];
		[titleField setStringValue:@"test test"];
		
		checkBoxButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 28, 28)];
		[checkBoxButton setButtonType:NSSwitchButton];
		
		[contentView addSubview:valSlider];
		[contentView addSubview:valLabel];
		[contentView addSubview:checkBoxButton];
		[contentView addSubview:titleField];
		[self _resizeContents];
		return self;
	}

	return nil;
}

- (void)setTitle:(NSString *)title{
	[titleField setStringValue:title];
}

- (void) setEnabled:(BOOL)n {
	if (enabled == n)
		return;
	enabled = n;
	if (enabled)	{
		[valSlider setEnabled:YES];
		[valLabel setEnabled:YES];
	}
	else	{
		[valSlider setEnabled:NO];
		[valLabel setEnabled:NO];
	}
}

- (void) _resizeContents {
	NSRect		contentBounds = [[self contentView] bounds];
	NSRect		sliderRect;
	NSRect		titleRect = NSMakeRect(0, 0, 200, contentBounds.size.height);
	NSRect		txtRect = contentBounds;
	NSRect      checkBoxRect = NSMakeRect(0, 0, 16, contentBounds.size.height);
	
	txtRect.size = NSMakeSize(16, contentBounds.size.height);
	sliderRect.size = NSMakeSize(contentBounds.size.width-titleRect.size.width-txtRect.size.width-12-checkBoxRect.size.width, contentBounds.size.height);
	
	sliderRect.origin = NSMakePoint(200 + 4, 0);
	txtRect.origin = NSMakePoint(contentBounds.size.width-txtRect.size.width - 4 - checkBoxRect.size.width, 0);
	checkBoxRect.origin = NSMakePoint(contentBounds.size.width - checkBoxRect.size.width, 0);
	
	[titleField setFrame:titleRect];
	[valSlider setFrame:sliderRect];
	[valLabel setFrame:txtRect];
	[checkBoxButton setFrame:checkBoxRect];
}

- (void) uiItemUsed:(id)sender	{
	if (sender == valSlider) {
		val = [valSlider intValue];
		[valLabel setIntValue:val];
	} else if (sender == valLabel) {
		val = [valLabel intValue];
		[valSlider setIntValue:val];
	}
	
	if (self.delegate != nil) {
		[self.delegate controlChanged:self];
	}
}


- (void) setVal:(int)n	{
	val = n;
	[valLabel setIntValue:n];
	[valSlider setIntValue:n];
}

- (int) val	{
	return val;
}

- (void) setMin:(int)n	{
	min = n;
	NSNumberFormatter		*fmt = [valLabel formatter];
	[fmt setMinimum:[NSNumber numberWithInt:n]];
	[valSlider setMinValue:n];
}

- (int) min	{
	return min;
}

- (void) setMax:(int)n	{
	max = n;
	NSNumberFormatter		*fmt = [valLabel formatter];
	[fmt setMaximum:[NSNumber numberWithInt:n]];
	[valSlider setMaxValue:n];
}

- (int) max	{
	return max;
}

@end
