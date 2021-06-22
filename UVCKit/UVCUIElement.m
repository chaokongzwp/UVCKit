#import "UVCUIElement.h"




@implementation UVCUIElement
- (id) initWithFrame:(NSRect)f	{
	if (self = [super initWithFrame:f])	{
		delegate = nil;
		enabled = YES;
		valSlider = nil;
		valField = nil;
		val = 0;
		min = 0;
		max = 0;
		
		[self setTitleFont:[NSFont systemFontOfSize:9]];
		[self setBorderType:NSNoBorder];
		[self setBoxType:NSBoxSecondary];
		
		NSView			*contentView = [self contentView];
		
		valSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(0,0,200,20)];
		[[valSlider cell] setControlSize:NSMiniControlSize];
		[valSlider setContinuous:YES];
		[valSlider setTarget:self];
		[valSlider setAction:@selector(uiItemUsed:)];
		valSlider.trackFillColor = [NSColor blueColor];
		
		valField = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,200,20)];
		[valField setFont:[NSFont systemFontOfSize:9]];
		NSNumberFormatter	*formatter = [[NSNumberFormatter alloc] init];
		[valField setFormatter:formatter];;
		[valField setTarget:self];
		[valField setAction:@selector(uiItemUsed:)];
		
		[contentView addSubview:valSlider];
		[contentView addSubview:valField];
		[self _resizeContents];
		return self;
	}

	return nil;
}

- (void) dealloc {
	if (valSlider != nil) {
		[valSlider removeFromSuperview];
		valSlider = nil;
	}
	
	if (valField != nil) {
		[valField removeFromSuperview];
		valField = nil;
	}
}

- (void) setEnabled:(BOOL)n {
	if (enabled == n)
		return;
	enabled = n;
	if (enabled)	{
		[valSlider setEnabled:YES];
		[valField setEnabled:YES];
	}
	else	{
		[valSlider setEnabled:NO];
		[valField setEnabled:NO];
	}
}

- (void) _resizeContents {
	NSRect		contentBounds = [[self contentView] bounds];
	
	NSRect		sliderRect;
	NSRect		txtRect = contentBounds;
	txtRect.size = NSMakeSize(50,16);
	sliderRect.size = NSMakeSize(contentBounds.size.width-txtRect.size.width-2, txtRect.size.height);
	sliderRect.origin = NSMakePoint(0,0);
	txtRect.origin = NSMakePoint(contentBounds.size.width-txtRect.size.width, 0);
	[valSlider setFrame:sliderRect];
	[valField setFrame:txtRect];
	[valSlider setAutoresizingMask:NSViewWidthSizable];
	[valField setAutoresizingMask:NSViewMinXMargin];
}

- (void) uiItemUsed:(id)sender	{
	if (sender == valSlider) {
		val = [valSlider intValue];
		[valField setIntValue:val];
	} else if (sender == valField) {
		val = [valField intValue];
		[valSlider setIntValue:val];
	}
	
	if (delegate != nil) {
		[delegate controlElementChanged:self];
	}
}


- (void) setVal:(int)n	{
	val = n;
	[valField setIntValue:n];
	[valSlider setIntValue:n];
}

- (int) val	{
	return val;
}

- (void) setMin:(int)n	{
	min = n;
	NSNumberFormatter		*fmt = [valField formatter];
	[fmt setMinimum:[NSNumber numberWithInt:n]];
	[valSlider setMinValue:n];
}

- (int) min	{
	return min;
}

- (void) setMax:(int)n	{
	max = n;
	NSNumberFormatter		*fmt = [valField formatter];
	[fmt setMaximum:[NSNumber numberWithInt:n]];
	[valSlider setMaxValue:n];
}

- (int) max	{
	return max;
}
@end
