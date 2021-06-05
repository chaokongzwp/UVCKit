#import <Cocoa/Cocoa.h>
#import <VVUVCKit/VVUVCKit.h>
#import <USBBusProber/USBBusProber.h>
#import "AVCaptureVideoSource.h"
#import "CVGLView.h"
#import <VVUVCKit/VVUVCUIElement.h>
#import "UVCButton.h"



@interface AppDelegate : NSObject <NSApplicationDelegate,AVCaptureVideoSourceDelegate, VVUVCUIElementDelegate, UVCMouseDelegate>	{
	CVDisplayLinkRef			displayLink;
	NSOpenGLContext				*sharedContext;
	NSOpenGLPixelFormat			*pixelFormat;
	
	AVCaptureVideoSource		*vidSrc;	//	uses AVCapture API to get video from camera & play it back in the gl view
	VVUVCController				*uvcController;	//	this is the example of how to use this class.  ironic that it's such a small part of the demo app.
	
	IBOutlet NSPopUpButton		*camPUB;	//	pop-up button with the list of available cameras
	IBOutlet CVGLView			*glView;	//	the gl view used to display GL textures received from the camera
	
	__weak IBOutlet UVCButton *rightPanTiltButton;
	
	__weak IBOutlet UVCButton *upPanTiltButton;
	
	__weak IBOutlet UVCButton *downPanTiltButton;
	__weak IBOutlet UVCButton *leftPanTiltButton;
	
	IBOutlet VVUVCUIElement *zoomElement;
	
	__weak IBOutlet NSView *mainView;
	__weak IBOutlet NSPopUpButton *dimensionPUB;
	__weak IBOutlet NSPopUpButton *subMediaTypePUB;
	__weak IBOutlet NSView *backgroudView;
	NSDictionary<NSString *, NSArray<UVCCaptureDeviceFormat *> *> * subMediaTypesInfo;
	
	__weak IBOutlet NSPathControl *pathControlWidget;
	__weak IBOutlet NSPathCell *pathControl;
	NSTimer *checkDeviceChange;
}

- (IBAction) camPUBUsed:(id)sender;
- (void) renderCallback;

- (void) populateCamPopUpButton;

- (NSOpenGLContext *) sharedContext;
- (NSOpenGLPixelFormat *) pixelFormat;

@end



CVReturn displayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext);
