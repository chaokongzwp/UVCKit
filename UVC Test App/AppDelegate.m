#import "AppDelegate.h"

#import "UVCUtils.h"


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

- (IBAction)zoom_minus:(id)sender {
	if (uvcController.zoom > uvcController.minZoom){
		[uvcController setZoom:uvcController.zoom - 1];
	}
}

- (IBAction)zoom_plus:(id)sender {
	if (uvcController.zoom < uvcController.maxZoom){
		[uvcController setZoom:uvcController.zoom + 1];
	}
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
//	mainView.wantsLayer = true;
//	mainView.layer.backgroundColor = [NSColor whiteColor].CGColor;
}
- (void) populateCamPopUpButton	{
	[camPUB removeAllItems];
	
	NSArray		*devicesMenuItems = [vidSrc arrayOfSourceMenuItems];
	for (NSMenuItem *itemPtr in devicesMenuItems)
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
    NSMenuItem        *selectedItem = [camPUB selectedItem];
    [self handleSelectedCamera:selectedItem];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processAddDeviceEventWithNotification:) name:AVCaptureDeviceWasConnectedNotification object:nil];
     
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processRemoveDeviceEventWithNotification:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
}

- (void)processAddDeviceEventWithNotification:(NSNotification *)noti{
    NSLog(@"processAddDeviceEventWithNotification %@", noti);
    AVCaptureDevice *device = noti.object;
    NSLog(@"processAddDeviceEventWithNotification %@", device);
    NSLog(@"processAddDeviceEventWithNotification %@", device.activeFormat.mediaType);
    if (@available(macOS 10.15, *)) {
        NSLog(@"processAddDeviceEventWithNotification %@", device.deviceType);
    } else {
        // Fallback on earlier versions
    }
    
    if (![device.activeFormat.mediaType isEqualToString:@"vide"]){
        // Fallback on earlier versions
        return;
    }
    
    NSMenuItem        *newItem = [[NSMenuItem alloc] initWithTitle:device.localizedName action:nil keyEquivalent:@""];
    [newItem setRepresentedObject:device.uniqueID];
    [[camPUB menu] addItem:newItem];
}

- (void)processRemoveDeviceEventWithNotification:(NSNotification *)noti{
    NSLog(@"processRemoveDeviceEventWithNotification %@", noti);
    
    AVCaptureDevice *device = noti.object;
//    NSInteger selectIndex = camPUB.indexOfSelectedItem;
    BOOL isFind = NO;
    
    NSArray<NSMenuItem *> * menuItemList = camPUB.itemArray;
    NSInteger deleteIndex = 0;
    for (NSInteger i = 0; i < menuItemList.count; i++) {
        NSMenuItem *item = menuItemList[i];
        id    repObj = [item representedObject];
        if ([device.uniqueID isEqualToString:repObj]) {
            deleteIndex = i;
            isFind = YES;
            break;
        }
    }
    
    if (isFind) {
        [camPUB removeItemAtIndex:deleteIndex];
        NSMenuItem        *selectedItem = [camPUB selectedItem];
        [self handleSelectedCamera:selectedItem];
    }
}

- (void)handleSelectedCamera:(NSMenuItem *)selectedItem{
    if (selectedItem == nil)
        return;
    id    repObj = [selectedItem representedObject];
    if (repObj == nil || [[vidSrc currentDeivceId] isEqualToString:repObj])
        return;
    
    [vidSrc loadDeviceWithUniqueID:[selectedItem representedObject]];
    uvcController = [[VVUVCController alloc] initWithDeviceIDString:repObj];
    if (uvcController==nil){
        NSLog(@"\t\tERR: couldn't create VVUVCController, %s",__func__);
        [versionTextView setString:@""];
    } else    {
        //[uvcController _autoDetectProcessingUnitID];
//        [uvcController openSettingsWindow];
        
        if ([uvcController zoomSupported])    {
            [zoomElement setMin:(int)[uvcController minZoom]];
            [zoomElement setMax:(int)[uvcController maxZoom]];
            [zoomElement setVal:(int)[uvcController zoom]];
        }
        [zoomElement setEnabled:[uvcController zoomSupported]];
        [versionTextView setString:[uvcController getExtensionVersion]];
    }
    subMediaTypesInfo= [vidSrc getMediaSubTypes];
    [self updateSubMediaTypesPopUpButton];
    
    [vidSrc setPreviewLayer:backgroudView];
}

- (IBAction) camPUBUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	NSMenuItem		*selectedItem = [sender selectedItem];
    [self handleSelectedCamera:selectedItem];
}

- (void)getCameraDir:(void (^)(NSString * result))handle{
    NSOpenPanel *panel = [NSOpenPanel openPanel];

    [panel setCanChooseFiles:NO];//是否能选择文件file
    [panel setCanChooseDirectories:YES];//是否能打开文件夹
    [panel setAllowsMultipleSelection:NO];//是否允许多选file
    panel.allowedFileTypes =@[@"bin"];

    [panel beginWithCompletionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            for (NSURL *url in [panel URLs]) {
                NSLog(@"--->%@",url.path);
                handle(url.path);
                break;
            }
        }
    }];
}

- (void)copyFile:(NSString *)file toTargetDir:(NSString *)dir{
    NSLog(@"copyFile %@ to %@", file, dir);
    dir = [dir stringByAppendingString:@"/fw.bin"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err = nil;
    if ([fm fileExistsAtPath:dir]){
        if (![fm removeItemAtPath:dir error:&err]){
            NSLog(@"removeItemAtPath %@ fail %@", dir, err);
        }
    }
    
    if (![fm copyItemAtPath:file toPath:dir error:&err]){
        NSLog(@"copyFile %@ to %@ fail %@", file, dir,err);
    }
}

- (void)createUpdateTagFileInDir:(NSString *)dir{
    //创建文件管理对象
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *createDirPath = [NSString stringWithFormat:@"%@/update",dir];
    NSError *err = nil;
    BOOL isYES = [fm createDirectoryAtPath:createDirPath withIntermediateDirectories:YES attributes:nil error:&err];
       
    if (isYES) {
        NSLog(@"创建 [%@] 成功", dir);
    } else {
        NSLog(@"创建 [%@] 失败 [%@]", dir, err);
    }
}

- (IBAction)searchFirmwareFileAction:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];

    [panel setCanChooseFiles:YES];//是否能选择文件file
    [panel setCanChooseDirectories:NO];//是否能打开文件夹
    [panel setAllowsMultipleSelection:NO];//是否允许多选file
    panel.allowedFileTypes =@[@"bin"];

    [panel beginWithCompletionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            for (NSURL *url in [panel URLs]) {
                NSLog(@"--->%@",url.path);
                NSFileManager *fm = [NSFileManager defaultManager];
                // YES 存在   NO 不存在
                BOOL isYES = [fm fileExistsAtPath:url.path];
                [firmwareFileTextfield setStringValue:url.path];
                NSLog(@"%d", isYES);
                [uvcController setUpdateMode];
                
                [UVCUtils showAlert:@"选择摄像头更新文件夹！" title:@"请选择" window:mainView.window completionHandler:^{
                    [self getCameraDir:^(NSString *result) {
                        [self createUpdateTagFileInDir:result];
                        [self copyFile:url.path toTargetDir:result];
                    }];
                }];
                
                break;
            }
        }
    }];
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

