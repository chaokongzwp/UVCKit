#import <Cocoa/Cocoa.h>
#import "VVUVCUIElement.h"
#import "VVUVCController.h"



@interface VVUVCUIController : NSObject <VVUVCUIElementDelegate, NSTextViewDelegate> {
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
	IBOutlet VVUVCUIElement		*expElement;
	IBOutlet VVUVCUIElement		*irisElement;
	IBOutlet VVUVCUIElement		*focusElement;
	IBOutlet VVUVCUIElement		*zoomElement;
	IBOutlet VVUVCUIElement		*backlightElement;
	IBOutlet VVUVCUIElement		*brightElement;
	IBOutlet VVUVCUIElement		*contrastElement;
	IBOutlet VVUVCUIElement		*powerElement;
	IBOutlet VVUVCUIElement		*gammaElement;
	IBOutlet VVUVCUIElement		*hueElement;
	IBOutlet VVUVCUIElement		*satElement;
	IBOutlet VVUVCUIElement		*sharpElement;
	IBOutlet VVUVCUIElement		*gainElement;
	IBOutlet VVUVCUIElement		*wbElement;
}

- (IBAction) buttonUsed:(id)sender;
- (IBAction) popUpButtonUsed:(id)sender;
- (IBAction) resetToDefaults:(id)sender;
- (void) _pushCameraControlStateToUI;
+ (void)updateController:(VVUVCController *)controller;
@end
