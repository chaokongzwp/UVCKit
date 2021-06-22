#import "AppDelegate.h"
#import <VVUVCKit/UVCUtils.h>

typedef NS_ENUM(NSUInteger, UVCUpdateState) {
    UVCUpdateStateNone = 0,
    UVCUpdateStateStart = 1,
    UVCUpdateStateDownloadBinFileSuccess = 2,
    UVCUpdateStateRestarting = 3,
    UVCUpdateStateSuccess = 4
};



@interface AppDelegate()
@property (nonatomic, copy) NSString *updateDeviceId;
@property (nonatomic, copy) NSString *updateBinFile;
@property (nonatomic, assign) UVCUpdateState updateState;
@end

@implementation AppDelegate
- (void)mouseDown:(NSEvent *)event sender:(nonnull id)sender{
    if ([self isInUpdating]) {
        return;
    }
    
	if (sender == upPanTiltButton) {
		[upPanTiltButton setImage:[NSImage imageNamed:@"arrow-up-filling_blue"]];
		[uvcController panTilt:UVC_PAN_TILT_UP];
	} else if (sender == downPanTiltButton) {
		[downPanTiltButton setImage:[NSImage imageNamed:@"arrow-down-filling_blue"]];
		[uvcController panTilt:UVC_PAN_TILT_DOWN];
	}else if (sender == rightPanTiltButton) {
		[rightPanTiltButton setImage:[NSImage imageNamed:@"arrow-right-filling_blue"]];
		[uvcController panTilt:UVC_PAN_TILT_RIGHT];
	}else if (sender == leftPanTiltButton) {
		[leftPanTiltButton setImage:[NSImage imageNamed:@"arrow-left-filling_blue"]];
		[uvcController panTilt:UVC_PAN_TILT_LEFT];
	} else if (sender == zoom_in){
		[zoom_in setImage:[NSImage imageNamed:@"zoom-in_blue"]];
		[uvcController setRelativeZoomControl:1];
	} else if (sender == zoom_out){
		[zoom_out setImage:[NSImage imageNamed:@"zoom-out_blue"]];
		[uvcController setRelativeZoomControl:0xFF];
    } else if (resetHomeButton == sender) {
        [resetHomeButton setImage:[NSImage imageNamed:@"home-filling_blue"]];
    }
}

- (void)mouseUp:(NSEvent *)event sender:(nonnull id)sender{
    if ([self isInUpdating]) {
        return;
    }
    
	if (sender == zoom_in || sender == zoom_out){
		[uvcController setRelativeZoomControl:0];
	} else if (resetHomeButton == sender) {
        [uvcController resetPanTilt];
        [uvcController setZoom:0];
    } else {
		[uvcController panTilt:UVC_PAN_TILT_CANCEL];
	}
	
	if (sender == upPanTiltButton) {
		[upPanTiltButton setImage:[NSImage imageNamed:@"arrow-up-filling"]];
	} else if (sender == downPanTiltButton) {
		[downPanTiltButton setImage:[NSImage imageNamed:@"arrow-down-filling"]];
	}else if (sender == rightPanTiltButton) {
		[rightPanTiltButton setImage:[NSImage imageNamed:@"arrow-right-filling"]];
	}else if (sender == leftPanTiltButton) {
		[leftPanTiltButton setImage:[NSImage imageNamed:@"arrow-left-filling"]];
	} else if (sender == zoom_in){
		[zoom_in setImage:[NSImage imageNamed:@"zoom-in"]];
	} else if (sender == zoom_out){
		[zoom_out setImage:[NSImage imageNamed:@"zoom-out"]];
	}  else if (resetHomeButton == sender) {
        [resetHomeButton setImage:[NSImage imageNamed:@"home-filling"]];
    }
}

- (IBAction)otherCameraSetting:(id)sender {
	[uvcController openSettingsWindow];
}

- (IBAction)saveLogAction:(id)sender {
	if ([logMenu.title isEqualToString:@"Save Log"]) {
		[UVCUtils openLog];
		[UVCUtils showAlert:[UVCUtils logPath] title:@"Log存储路径" window:mainView.window completionHandler:nil];
		logMenu.title = @"Close Log";
	} else {
		logMenu.title = @"Save Log";
		[UVCUtils closeLog];
	}
}

- (id) init	{
	if (self = [super init])	{
		if ([UVCUtils isLogOn]){
			[UVCUtils openLog];
		}
		displayLink = nil;
		sharedContext = nil;
		pixelFormat = nil;
		vidSrc = nil;
		uvcController = nil;

		vidSrc = [[AVCaptureVideoSource alloc] init];
		[vidSrc setDelegate:self];
		
		return self;
	}

	return nil;
}

- (IBAction)versionAction:(id)sender {
	[versionTextView setString:[uvcController getExtensionVersion]];
}

- (IBAction)startUpgradeAction:(id)sender {
	if (firmwareFileTextfield.stringValue == nil || firmwareFileTextfield.stringValue.length == 0) {
		return;
	}
	
	if([uvcController setUpdateMode]){
		self.updateDeviceId = [vidSrc currentDeivceId];
		self.updateState = UVCUpdateStateStart;
		upgradeProgressIndicator.minValue = 0;
		upgradeProgressIndicator.maxValue = 100;
		upgradeProgressIndicator.doubleValue = 0;
		upgradeProgressIndicator.hidden = NO;
		[upgradeProgressIndicator startAnimation:upgradeProgressIndicator];
		[self updateIndicator];
	} else {
		self.updateState = UVCUpdateStateNone;
		self.updateDeviceId = nil;
		[UVCUtils showAlert:@"启动升级模式失败！！" title:@"异常提示" window:mainView.window completionHandler:nil];
	}
}


- (void) awakeFromNib	{
	NSXLog(@"awakeFromNib");
	if ([UVCUtils isLogOn]){
		logMenu.title = @"Close Log";
	} else {
		logMenu.title = @"Save Log";
	}
	//	populate the camera pop-up button
	[self populateCamPopUpButton];
	[subMediaTypePUB removeAllItems];
	[dimensionPUB removeAllItems];
	
	upPanTiltButton.delegate = self;
	downPanTiltButton.delegate = self;
	rightPanTiltButton.delegate = self;
	leftPanTiltButton.delegate = self;
	zoom_in.delegate = self;
	zoom_out.delegate = self;
    resetHomeButton.delegate = self;
	
//	backgroudView
	backgroudView.wantsLayer = true;///设置背景颜色
	backgroudView.layer.backgroundColor = [NSColor blackColor].CGColor;
}

- (void) populateCamPopUpButton	{
	NSXLog(@"populateCamPopUpButton");
	[camPUB removeAllItems];
	
	NSArray		*devicesMenuItems = [vidSrc arrayOfSourceMenuItems];
	for (NSMenuItem *itemPtr in devicesMenuItems){
		[[camPUB menu] addItem:itemPtr];
	}
	if (devicesMenuItems.count == 0) {
		NSMenuItem		*newItem = [[NSMenuItem alloc] initWithTitle:@"选择摄像头" action:nil keyEquivalent:@""];
		[[camPUB menu] addItem:newItem];
	}
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
		if ([[item title] isEqualToString:activeFormat.alias]) {
			selectItem = i;
		}
	}
	
	[subMediaTypePUB selectItemAtIndex:selectItem];
	
	[self updateDimensionPopUpButton:activeFormat.alias];
}

- (BOOL)isInUpdating{
    return self.updateDeviceId != nil;
}

- (void)getNextStepValue{
    int max = 0;
    float delta = 0;
//    NSXLog(@"getNextStepValue updateState %lu doubleValue %f", (unsigned long)self.updateState, upgradeProgressIndicator.doubleValue);
    switch (self.updateState) {
        case UVCUpdateStateStart:
            max = 8;
            delta = 0.4;
            break;
        
        case UVCUpdateStateDownloadBinFileSuccess:
            max = 78;
            delta = 0.2;
            break;
            
        case UVCUpdateStateRestarting:
            max = 95;
            delta = 0.1;
            break;
            
        case UVCUpdateStateSuccess:
            upgradeProgressIndicator.doubleValue = 100;
            self.updateState = UVCUpdateStateNone;
            self.updateDeviceId = nil;
            [UVCUtils showAlert:@"请检查设备新版本号！" title:@"更新结束" window:mainView.window completionHandler:nil];
            return;
            
        default:
            break;
    }
    
    if (upgradeProgressIndicator.doubleValue > max) {
        // do nothing
    } else {
        upgradeProgressIndicator.doubleValue = upgradeProgressIndicator.doubleValue + delta;
    }
    
    return;
}

- (void)updateIndicator{
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC);
    dispatch_after(time, dispatch_get_main_queue(), ^{
        if(self.updateDeviceId){
            [self getNextStepValue];
            [self updateIndicator];
        }
    });
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
	return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification	{
	NSXLog(@"applicationDidFinishLaunching");
	dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC);

	dispatch_after(time, dispatch_get_main_queue(), ^{
		NSXLog(@" waited at lease three seconds");
		NSMenuItem        *selectedItem = [camPUB selectedItem];
		[self handleSelectedCamera:selectedItem];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processAddDeviceEventWithNotification:) name:AVCaptureDeviceWasConnectedNotification object:nil];
		 
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processRemoveDeviceEventWithNotification:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
        
        // Notification for Mountingthe USB device
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(deviceMounted:)  name: NSWorkspaceDidMountNotification object: nil];

         // Notification for Un-Mountingthe USB device
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(deviceUnmounted:)  name: NSWorkspaceDidUnmountNotification object: nil];
	});
}

- (void)updateDeviceBinFail:(NSString *)errMsg{
    self.updateState = UVCUpdateStateNone;
    self.updateDeviceId = nil;
    [UVCUtils showAlert:errMsg title:@"异常提示" window:mainView.window completionHandler:nil];
}

- (void)setAllButtonState:(BOOL)enable{
    dimensionPUB.enabled = enable;
    subMediaTypePUB.enabled = enable;
    leftPanTiltButton.enabled = enable;
    rightPanTiltButton.enabled = enable;
    upPanTiltButton.enabled = enable;
    downPanTiltButton.enabled = enable;
    zoom_in.enabled = enable;
    zoom_out.enabled = enable;
    camPUB.enabled = enable;
    resetHomeButton.enabled = enable;
    upgradeButton.enabled = enable;
}

- (void)setUpdateState:(UVCUpdateState)updateState{
    _updateState = updateState;
    NSXLog(@"setUpdateState %lu", (unsigned long)updateState);
    [self setAllButtonState:NO];
    switch (updateState) {
        case UVCUpdateStateStart:
            [versionTextView setString:@"升级中，请勿插拔任何usb设备，请勿断开摄像头！"];
            break;
        
        case UVCUpdateStateDownloadBinFileSuccess:
            [versionTextView setString:@"升级中，请勿插拔任何usb设备，请勿断开摄像头！\n1. bin文件传输成功，升级中...."];
            break;
            
        case UVCUpdateStateRestarting:
            [versionTextView setString:@"升级中，请勿插拔任何usb设备，请勿断开摄像头！\n1. bin文件传输成功 \n2.升级成功，设备重启中..."];
            break;
            
        case UVCUpdateStateSuccess:
            [versionTextView setString:@"升级中，请勿插拔任何usb设备，请勿断开摄像头！\n1. bin文件传输成功 \n2.更新文件成功\n3.版本升级成功"];
            break;
        
        default:
            [self setAllButtonState:YES];
            break;
    }
}

- (void)deviceMounted:(NSNotification *)noti{
    NSXLog(@"deviceMounted %@", noti);
    if (self.updateDeviceId && self.updateState == UVCUpdateStateStart) {
        NSURL *dir = noti.userInfo[NSWorkspaceVolumeURLKey];
        if ([self copyFile:firmwareFileTextfield.stringValue toTargetDir:dir.path]) {
            if ([self createUpdateTagFileInDir:dir.path]){
                self.updateState = UVCUpdateStateDownloadBinFileSuccess;
                return;
            }
        }
        
        [self updateDeviceBinFail:@"下载更新文件失败，请重启设备，重试一下！！"];
    }
}

- (void)deviceUnmounted:(NSNotification *)noti{
    NSXLog(@"deviceUnmounted %@", noti);
    if (self.updateDeviceId && self.updateState == UVCUpdateStateDownloadBinFileSuccess) {
        self.updateState = UVCUpdateStateRestarting;
    }
}

- (void)processAddDeviceEventWithNotification:(NSNotification *)noti{
    NSXLog(@"processAddDeviceEventWithNotification %@", noti);
    AVCaptureDevice *device = noti.object;
    NSXLog(@"processAddDeviceEventWithNotification %@", device);
    NSXLog(@"processAddDeviceEventWithNotification %@", device.activeFormat.mediaType);
    if (![device.activeFormat.mediaType isEqualToString:@"vide"]){
        // Fallback on earlier versions
        return;
    }
    
    if ([self.updateDeviceId isEqualToString:device.uniqueID]) {
        self.updateState = UVCUpdateStateSuccess;
        [self reloadDeviceWithId:self.updateDeviceId];
        return;
    }
    
    NSMenuItem        *newItem = [[NSMenuItem alloc] initWithTitle:device.localizedName action:nil keyEquivalent:@""];
    [newItem setRepresentedObject:device.uniqueID];
    [[camPUB menu] addItem:newItem];
}

- (void)processRemoveDeviceEventWithNotification:(NSNotification *)noti{
    NSXLog(@"processRemoveDeviceEventWithNotification %@", noti);
    
    AVCaptureDevice *device = noti.object;
    if ([device.uniqueID isEqualToString:self.updateDeviceId]) {
        return;
    }

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


- (void)reloadDeviceWithId:(NSString *)deviceId{
    [vidSrc loadDeviceWithUniqueID:deviceId];
    uvcController = [[VVUVCController alloc] initWithDeviceIDString:deviceId];
    if (uvcController==nil){
        NSXLog(@"\t\tERR: couldn't create VVUVCController, %s",__func__);
        [versionTextView setString:@""];
		[uvcController closeSettingsWindow];
    } else    {
        if ([uvcController zoomSupported]) {
            [uvcController resetPanTilt];
            [uvcController setZoom:0];
        }
    }
	
	[versionTextView setString:@""];
    subMediaTypesInfo= [vidSrc getMediaSubTypes];
    [self updateSubMediaTypesPopUpButton];
    [vidSrc setPreviewLayer:backgroudView];
}

- (void)handleSelectedCamera:(NSMenuItem *)selectedItem{
    if (selectedItem == nil)
        return;
    id    repObj = [selectedItem representedObject];
    if (repObj == nil || [[vidSrc currentDeivceId] isEqualToString:repObj])
        return;
    
    [self reloadDeviceWithId:repObj];
}

- (IBAction) camPUBUsed:(id)sender	{
	//NSXLog(@"%s",__func__);
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
                NSXLog(@"--->%@",url.path);
                handle(url.path);
                break;
            }
        }
    }];
}

- (BOOL)copyFile:(NSString *)file toTargetDir:(NSString *)dir{
    NSXLog(@"copyFile %@ to %@", file, dir);
    dir = [dir stringByAppendingString:@"/fw.bin"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err = nil;
    if ([fm fileExistsAtPath:dir]){
        if (![fm removeItemAtPath:dir error:&err]){
            NSXLog(@"removeItemAtPath %@ fail %@", dir, err);
            return NO;
        }
    }
    
    if (![fm copyItemAtPath:file toPath:dir error:&err]){
        NSXLog(@"copyFile %@ to %@ fail %@", file, dir,err);
        return NO;
    }
    return YES;
}

- (BOOL)createUpdateTagFileInDir:(NSString *)dir{
    //创建文件管理对象
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *createDirPath = [NSString stringWithFormat:@"%@/update",dir];
    NSError *err = nil;
    BOOL isYES = [fm createDirectoryAtPath:createDirPath withIntermediateDirectories:YES attributes:nil error:&err];
       
    if (isYES) {
        NSXLog(@"创建 [%@] 成功", dir);
    } else {
        NSXLog(@"创建 [%@] 失败 [%@]", dir, err);
    }
    
    return isYES;
}

- (IBAction)searchFirmwareFileAction:(id)sender {
    if ([self isInUpdating]) {
        return;
    }
    NSOpenPanel *panel = [NSOpenPanel openPanel];

    [panel setCanChooseFiles:YES];//是否能选择文件file
    [panel setCanChooseDirectories:NO];//是否能打开文件夹
    [panel setAllowsMultipleSelection:NO];//是否允许多选file
    panel.allowedFileTypes =@[@"bin", @"img"];

    [panel beginWithCompletionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            for (NSURL *url in [panel URLs]) {
                NSXLog(@"--->%@",url.path);
                NSFileManager *fm = [NSFileManager defaultManager];
                // YES 存在   NO 不存在
                BOOL isYES = [fm fileExistsAtPath:url.path];
                [firmwareFileTextfield setStringValue:url.path];
                NSXLog(@"%d", isYES);
                break;
            }
        }
    }];
}

- (BOOL)isSameFormat:(UVCCaptureDeviceFormat *)format{
	UVCCaptureDeviceFormat *current = [vidSrc activeFormatInfo];
	
	if ([current.subMediaType isEqualToString:format.subMediaType]
		&& (current.height == format.height)
		&& (current.width == format.width)) {
		return YES;
	}
	
	return NO;
}


- (IBAction)subMediaType:(id)sender {
	NSMenuItem		*selectedItem = [sender selectedItem];
	if (selectedItem == nil)
		return;
	
	UVCCaptureDeviceFormat *format = [self updateDimensionPopUpButton:selectedItem.title];
	if ([self isSameFormat:format]) {
		return;
	}
	
	[vidSrc loadDeviceWithUniqueID:[vidSrc currentDeivceId] format:format];
	uvcController = [[VVUVCController alloc] initWithDeviceIDString:[vidSrc currentDeivceId]];
	if (uvcController==nil){
		NSXLog(@"\t\tERR: couldn't create VVUVCController, %s",__func__);
		[versionTextView setString:@""];
	} else    {
		if ([uvcController zoomSupported])    {
			[uvcController resetPanTilt];
			[uvcController setZoom:0];
		}
	}
	subMediaTypesInfo= [vidSrc getMediaSubTypes];
	[self updateSubMediaTypesPopUpButton];
	[vidSrc setPreviewLayer:backgroudView];
}

- (IBAction)dimension:(id)sender {
	NSMenuItem		*selectedItem = [sender selectedItem];
	if (selectedItem == nil)
		return;
	UVCCaptureDeviceFormat *repObj = [selectedItem representedObject];
	if (repObj == nil){
		return;
	}
	
	if ([self isSameFormat:repObj]) {
		return;
	}
	
	[vidSrc loadDeviceWithUniqueID:[vidSrc currentDeivceId] format:repObj];
	[vidSrc setPreviewLayer:backgroudView];
	uvcController = [[VVUVCController alloc] initWithDeviceIDString:[vidSrc currentDeivceId]];
	if (uvcController==nil){
		NSXLog(@"\t\tERR: couldn't create VVUVCController, %s",__func__);
		[versionTextView setString:@""];
	} else    {
		if ([uvcController zoomSupported])    {
			[uvcController resetPanTilt];
			[uvcController setZoom:0];
		}
	}
	subMediaTypesInfo= [vidSrc getMediaSubTypes];
	[self updateSubMediaTypesPopUpButton];
	[vidSrc setPreviewLayer:backgroudView];
}


/*===================================================================================*/
#pragma mark --------------------- AVCaptureVideoSourceDelegate
/*------------------------------------*/
- (void) listOfStaticSourcesUpdated:(id)videoSource	{
	NSXLog(@"%s",__func__);
}
@end

