#import <Cocoa/Cocoa.h>




@protocol UVCUIElementDelegate
- (void) controlElementChanged:(id)sender;
@end




@interface UVCUIElement : NSBox {
	IBOutlet id		delegate;

	BOOL			enabled;
	NSSlider		*valSlider;
	NSTextField		*valField;
	
	int				val;
	int				min;
	int				max;
}

- (void) setEnabled:(BOOL)n;

- (void) _resizeContents;

- (void) uiItemUsed:(id)sender;

//@property (assign,readwrite) id delegate;
@property (assign,readwrite) int val;
@property (assign,readwrite) int min;
@property (assign,readwrite) int max;

@end
