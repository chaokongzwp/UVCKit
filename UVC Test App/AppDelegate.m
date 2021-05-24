#import "AppDelegate.h"




@implementation AppDelegate 

- (IBAction)leftPTZAction:(id)sender {
	[uvcController panTilt:UVC_PAN_TILT_LEFT];
}

- (IBAction)rightPTZAction:(id)sender {
	[uvcController panTilt:UVC_PAN_TILT_RIGHT];
}

- (IBAction)upPTZAction:(id)sender {
	[uvcController panTilt:UVC_PAN_TILT_UP];
}

- (IBAction)downPTZAction:(id)sender {
	[uvcController panTilt:UVC_PAN_TILT_DOWN];
}


- (void)mouseDown:(NSEvent *)event sender:(nonnull id)sender{
	if (sender == upPanTiltButton) {
		[uvcController panTilt:UVC_PAN_TILT_UP];
	} else if (sender == downPanTiltButton) {
		[uvcController panTilt:UVC_PAN_TILT_DOWN];
	}else if (sender == rightPanTiltButton) {
		[uvcController panTilt:UVC_PAN_TILT_RIGHT];
	}else if (sender == leftPanTiltButton) {
		[uvcController panTilt:UVC_PAN_TILT_LEFT];
	}
}

- (void)mouseUp:(NSEvent *)event sender:(nonnull id)sender{
	[uvcController panTilt:UVC_PAN_TILT_CANCEL];
}

- (void) controlElementChanged:(id)sender{
	if (sender == zoomElement){
		[uvcController setZoom:[sender val]];
	}
}

- (id) init	{
	if (self = [super init])	{
		displayLink = nil;
		sharedContext = nil;
		pixelFormat = nil;
		vidSrc = nil;
		uvcController = nil;
		
		
		//	generate the GL display mask for all displays
		CGError					cgErr = kCGErrorSuccess;
		CGDirectDisplayID		dspys[10];
		CGDisplayCount			count = 0;
		GLuint					glDisplayMask = 0;
		cgErr = CGGetActiveDisplayList(10,dspys,&count);
		if (cgErr == kCGErrorSuccess)	{
			int					i;
			for (i=0;i<count;++i)
				glDisplayMask = glDisplayMask | CGDisplayIDToOpenGLDisplayMask(dspys[i]);
		}
		//	create a GL pixel format based on desired properties + GL display mask
		NSOpenGLPixelFormatAttribute		attrs[] = {
			NSOpenGLPFAAccelerated,
			NSOpenGLPFAScreenMask,glDisplayMask,
			NSOpenGLPFANoRecovery,
			NSOpenGLPFAAllowOfflineRenderers,
			0};
		pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
		//	make the shared GL context.  everybody shares this, so we can share GL resources.
		sharedContext = [[NSOpenGLContext alloc]
			initWithFormat:pixelFormat
			shareContext:nil];
		//	make the CV texture cache (off the shared context)
		CVReturn			cvErr = kCVReturnSuccess;
		cvErr = CVOpenGLTextureCacheCreate(NULL, NULL, [sharedContext CGLContextObj], [pixelFormat CGLPixelFormatObj], NULL, &_textureCache);
		if (cvErr != kCVReturnSuccess)
			NSLog(@"\t\tERR %d- unable to create CVOpenGLTextureCache in %s",cvErr,__func__);
		//	make a displaylink, which will drive rendering
		cvErr = CVDisplayLinkCreateWithOpenGLDisplayMask(glDisplayMask, &displayLink);
		if (cvErr)	{
			NSLog(@"\t\terr %d creating display link in %s",cvErr,__func__);
			displayLink = NULL;
		}
		else
			CVDisplayLinkSetOutputCallback(displayLink, displayLinkCallback, (__bridge void * _Nullable)(self));
		//	make the video source (which needs the CV texture cache)
		vidSrc = [[AVCaptureVideoSource alloc] init];
		[vidSrc setDelegate:self];
		
		return self;
	}
//	[self release];
	return nil;
}

- (void) awakeFromNib	{
	//	populate the camera pop-up button
	[self populateCamPopUpButton];
	[subMediaTypePUB removeAllItems];
	[dimensionPUB removeAllItems];
	
	[zoomElement setTitle:@"Zoom"];
	
	upPanTiltButton.delegate = self;
	downPanTiltButton.delegate = self;
	rightPanTiltButton.delegate = self;
	leftPanTiltButton.delegate = self;
//	backgroudView
	backgroudView.wantsLayer = true;///设置背景颜色

	backgroudView.layer.backgroundColor = [NSColor blackColor].CGColor;
}
- (void) populateCamPopUpButton	{
	[camPUB removeAllItems];
	
	NSMenuItem		*tmpItem = [[NSMenuItem alloc] initWithTitle:@"Select a camera!" action:nil keyEquivalent:@""];
	[[camPUB menu] addItem:tmpItem];
//	[tmpItem release];
	tmpItem = nil;
	
	NSArray		*devices = [vidSrc arrayOfSourceMenuItems];
	for (NSMenuItem *itemPtr in devices)
		[[camPUB menu] addItem:itemPtr];
	
	[camPUB selectItemAtIndex:0];
}

- (UVCCaptureDeviceFormat *)updateDimensionPopUpButton:(NSString *)subMediaType{
	NSArray<UVCCaptureDeviceFormat *> *dimensionList = subMediaTypesInfo[subMediaType];
	NSMutableArray		*returnMe = [NSMutableArray arrayWithCapacity:0];
	UVCCaptureDeviceFormat *activeFormat = [vidSrc activeFormatInfo];
	
	for (UVCCaptureDeviceFormat *dimension in dimensionList)	{
		NSMenuItem		*newItem = [[NSMenuItem alloc] initWithTitle:dimension.formatDesc action:nil keyEquivalent:@""];
		[newItem setRepresentedObject:dimension];
		[returnMe addObject:newItem];
	}
	
	[dimensionPUB removeAllItems];
	unsigned long selectItem = returnMe.count - 1;
	for (unsigned long i = 0; i < returnMe.count;i++){
		NSMenuItem *item = returnMe[i];
		[[dimensionPUB menu] addItem:item];

		if ([[item title] isEqualToString:activeFormat.formatDesc]) {
			selectItem = i;
		}
	}
	
	[dimensionPUB selectItemAtIndex:selectItem];
	return dimensionList[selectItem];
}

- (void)updateSubMediaTypesPopUpButton{
	NSMutableArray		*returnMe = [NSMutableArray arrayWithCapacity:0];
	for (NSString *subMediaType in subMediaTypesInfo.allKeys)	{
		NSMenuItem		*newItem = [[NSMenuItem alloc] initWithTitle:subMediaType action:nil keyEquivalent:@""];
		[newItem setRepresentedObject:subMediaTypesInfo[subMediaType]];
		[returnMe addObject:newItem];
	}
	UVCCaptureDeviceFormat *activeFormat = [vidSrc activeFormatInfo];
	[subMediaTypePUB removeAllItems];
	int selectItem = 0;
	for (int i = 0; i < returnMe.count;i++){
		NSMenuItem *item = returnMe[i];
		[[subMediaTypePUB menu] addItem:item];
		if ([[item title] isEqualToString:activeFormat.subMediaType]) {
			selectItem = i;
		}
	}
	
	[subMediaTypePUB selectItemAtIndex:selectItem];
	
	[self updateDimensionPopUpButton:activeFormat.subMediaType];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification	{
	//	start the displaylink
//	CVDisplayLinkStart(displayLink);
}

- (IBAction) camPUBUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	NSMenuItem		*selectedItem = [sender selectedItem];
	if (selectedItem == nil)
		return;
	id				repObj = [selectedItem representedObject];
	if (repObj == nil)
		return;
	
//	NSLog(@"\t\trepObj is an instance of %@, and is \"%@\"",[repObj class],repObj);
	[vidSrc loadDeviceWithUniqueID:[selectedItem representedObject]];
	uvcController = [[VVUVCController alloc] initWithDeviceIDString:repObj];
	if (uvcController==nil)
		NSLog(@"\t\tERR: couldn't create VVUVCController, %s",__func__);
	else	{
		//[uvcController _autoDetectProcessingUnitID];
//		[uvcController openSettingsWindow];
		
		if ([uvcController zoomSupported])	{
			[zoomElement setMin:(int)[uvcController minZoom]];
			[zoomElement setMax:(int)[uvcController maxZoom]];
			[zoomElement setVal:(int)[uvcController zoom]];
		}
		[zoomElement setEnabled:[uvcController zoomSupported]];
	}
	subMediaTypesInfo= [vidSrc getMediaSubTypes];
	[self updateSubMediaTypesPopUpButton];
	
	[vidSrc setPreviewLayer:backgroudView];
}

- (IBAction)subMediaType:(id)sender {
	NSMenuItem		*selectedItem = [sender selectedItem];
	if (selectedItem == nil)
		return;
	
	UVCCaptureDeviceFormat *format = [self updateDimensionPopUpButton:selectedItem.title];
	
	[vidSrc updateDeviceFormat:format];
	[vidSrc setPreviewLayer:backgroudView];
}

- (IBAction)dimension:(id)sender {
	NSMenuItem		*selectedItem = [sender selectedItem];
	if (selectedItem == nil)
		return;
	UVCCaptureDeviceFormat *repObj = [selectedItem representedObject];
	if (repObj == nil)
		return;
	
	[vidSrc updateDeviceFormat:repObj];
	[vidSrc setPreviewLayer:backgroudView];
}


- (void) renderCallback	{
	CVOpenGLTextureRef		newTex = [vidSrc safelyGetRetainedTextureRef];
	if (newTex == nil)
		return;
	
	[glView drawTextureRef:newTex];
	
	CVOpenGLTextureRelease(newTex);
	newTex = nil;
}
- (NSOpenGLContext *) sharedContext	{
	return sharedContext;
}
- (NSOpenGLPixelFormat *) pixelFormat	{
	return pixelFormat;
}


/*===================================================================================*/
#pragma mark --------------------- AVCaptureVideoSourceDelegate
/*------------------------------------*/


- (void) listOfStaticSourcesUpdated:(id)videoSource	{
	NSLog(@"%s",__func__);
}


@end




CVReturn displayLinkCallback(CVDisplayLinkRef displayLink, 
	const CVTimeStamp *inNow, 
	const CVTimeStamp *inOutputTime, 
	CVOptionFlags flagsIn, 
	CVOptionFlags *flagsOut, 
	void *displayLinkContext)
{
	@autoreleasepool {
		[(__bridge AppDelegate *)displayLinkContext renderCallback];
	}
	
	return kCVReturnSuccess;
}

