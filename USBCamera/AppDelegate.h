#import <Cocoa/Cocoa.h>
#import <UVCKit/UVCKit.h>
#import <USBBusProber/USBBusProber.h>
#import "UVCCaptureVideoSource.h"
#import <UVCKit/UVCUIElement.h>
#import "UVCButton.h"



@interface AppDelegate : NSObject <NSApplicationDelegate, UVCMouseDelegate>	{
	UVCCaptureVideoSource		*vidSrc;	//	uses AVCapture API to get video from camera & play it back in the gl view
	UVCController				*uvcController;	//	this is the example of how to use this class.  ironic that it's such a small part of the demo app.
	
	IBOutlet NSPopUpButton		*camPUB;	//	pop-up button with the list of available cameras	
	__weak IBOutlet NSButton *startUpgrade;
	__weak IBOutlet NSOpenGLView *glView;
	__weak IBOutlet NSMenuItem *logMenu;
	__weak IBOutlet UVCButton *rightPanTiltButton;
	__weak IBOutlet UVCButton *upPanTiltButton;
	__weak IBOutlet UVCButton *downPanTiltButton;
	__weak IBOutlet UVCButton *leftPanTiltButton;
    __weak IBOutlet NSButton *upgradeButton;
    __weak IBOutlet UVCButton *resetHomeButton;
    __weak IBOutlet UVCButton *zoom_out;
	__weak IBOutlet UVCButton *zoom_in;
	__weak IBOutlet NSView *mainView;
	__weak IBOutlet NSPopUpButton *dimensionPUB;
	__weak IBOutlet NSPopUpButton *subMediaTypePUB;
	__weak IBOutlet NSView *backgroudView;
	NSDictionary<NSString *, NSArray<UVCCaptureDeviceFormat *> *> * subMediaTypesInfo;
	NSTimer *checkDeviceChange;

	__unsafe_unretained IBOutlet NSTextView *versionTextView;
    __weak IBOutlet NSTextField *firmwareFileTextfield;
    __weak IBOutlet NSProgressIndicator *upgradeProgressIndicator;
}

- (IBAction) camPUBUsed:(id)sender;
- (void) populateCamPopUpButton;
@end
