#import <Cocoa/Cocoa.h>
#import "UVCUIElement.h"
#import "UVCController.h"



@interface UVCUIController : NSObject <VVUVCUIElementDelegate, NSTextViewDelegate> {
	IBOutlet id				device;
	__weak IBOutlet NSView *mainView;
	IBOutlet NSPopUpButton	*autoExpButton;
	IBOutlet NSButton		*expPriorityButton;
	IBOutlet NSButton		*autoFocusButton;
	__weak IBOutlet NSTextField *bmRequestType;
	__weak IBOutlet NSTextField *bRequest;
	__weak IBOutlet NSTextField *wValue;
	__weak IBOutlet NSTextField *wIndex;
	__weak IBOutlet NSTextField *wLength;
	__weak IBOutlet NSTextField *data;
	__weak IBOutlet NSButton *sendCommand;
	IBOutlet NSButton		*autoHueButton;
	IBOutlet NSButton		*autoWBButton;
	IBOutlet UVCUIElement		*expElement;
	IBOutlet UVCUIElement		*irisElement;
	IBOutlet UVCUIElement		*focusElement;
	IBOutlet UVCUIElement		*zoomElement;
	IBOutlet UVCUIElement		*backlightElement;
	IBOutlet UVCUIElement		*brightElement;
	IBOutlet UVCUIElement		*contrastElement;
	IBOutlet UVCUIElement		*powerElement;
	IBOutlet UVCUIElement		*gammaElement;
	IBOutlet UVCUIElement		*hueElement;
	IBOutlet UVCUIElement		*satElement;
	IBOutlet UVCUIElement		*sharpElement;
	IBOutlet UVCUIElement		*gainElement;
	IBOutlet UVCUIElement		*wbElement;
}

- (IBAction) buttonUsed:(id)sender;
- (IBAction) popUpButtonUsed:(id)sender;
- (IBAction) resetToDefaults:(id)sender;
- (void) _pushCameraControlStateToUI;
+ (void)updateController:(UVCController *)controller;
@end
