#import "AppDelegate.h"
#import <UVCKit/UVCUtils.h>
#import <UVCKit/UVCUIController.h>

typedef NS_ENUM(NSUInteger, UVCUpdateState) {
    UVCUpdateStateNone = 0,
    UVCUpdateStateStart = 1,
    UVCUpdateStateDownloadBinFileSuccess = 2,
    UVCUpdateStateRestarting = 3,
    UVCUpdateStateSuccess = 4
};


typedef enum : NSUInteger {
	ChildWindows_HIDEN,
	ChildWindows_GPL,
	ChildWindows_CTRL,
} ChildWindowsStateEn;

@interface AppDelegate()<NSWindowDelegate>
@property (nonatomic, copy) NSString *updateDeviceId;
@property (nonatomic, copy) NSString *updateBinFile;
@property (nonatomic, assign) UVCUpdateState updateState;
@property (nonatomic, strong) IBOutlet NSMenu *customMenu;
@property (weak) IBOutlet NSPanel *ctrlWindow;
@property (weak) IBOutlet NSPanel *gplWindow;
@property (unsafe_unretained) IBOutlet NSTextView *gplTextView;
@property (weak) IBOutlet NSToolbarItem *uvcSettingMenu;
@property (weak) IBOutlet NSView *settingView;
@property (nonatomic, assign) ChildWindowsStateEn childWindowsState;


// setting
@property (weak) IBOutlet NSButton *flipHorizontalButton;
@property (weak) IBOutlet NSButton *flipVerticalButton;


// image ctrl
@property (weak) IBOutlet NSSlider *brightnessSlider;
@property (weak) IBOutlet NSTextField *brightnessLabel;
@property (weak) IBOutlet NSButton *brightnessSwitchButton;
@property (weak) IBOutlet NSSlider *contrastSlider;
@property (weak) IBOutlet NSTextField *contrastLabel;
@property (weak) IBOutlet NSButton *contrastSwitchButton;
@property (weak) IBOutlet NSTextField *hueLabel;
@property (weak) IBOutlet NSSlider *hueSlider;
@property (weak) IBOutlet NSButton *hueSwitchButton;
@property (weak) IBOutlet NSTextField *saturateLabel;
@property (weak) IBOutlet NSSlider *saturateSlider;
@property (weak) IBOutlet NSButton *saturateSwitchButton;
@property (weak) IBOutlet NSTextField *sharpnessLabel;
@property (weak) IBOutlet NSSlider *sharpnessSlider;
@property (weak) IBOutlet NSTextField *gammaLabel;
@property (weak) IBOutlet NSButton *sharpnessSwitch;
@property (weak) IBOutlet NSSlider *gammaSlider;
@property (weak) IBOutlet NSButton *gammaSwitch;
@property (weak) IBOutlet NSTextField *whiteBalanceLabel;
@property (weak) IBOutlet NSButton *whiteBalanceSwitch;
@property (weak) IBOutlet NSSlider *whiteBalanceSlider;
@property (weak) IBOutlet NSTextField *backlightLabel;
@property (weak) IBOutlet NSButton *backlightSwitch;
@property (weak) IBOutlet NSSlider *backlightContrastSlider;
@property (weak) IBOutlet NSTextField *gainLabel;
@property (weak) IBOutlet NSSlider *gainSlider;
@property (weak) IBOutlet NSButton *gainSwitch;
@property (weak) IBOutlet NSButton *enableColorSwitch;
@property (weak) IBOutlet NSPopUpButton *anitFickerSelector;


// camera ctrl
@property (weak) IBOutlet NSSlider *zoomSlider;
@property (weak) IBOutlet NSButton *zoomSwitch;
@property (weak) IBOutlet NSTextField *zoomLabel;
@property (weak) IBOutlet NSSlider *focusSlider;
@property (weak) IBOutlet NSButton *focusSwitch;
@property (weak) IBOutlet NSTextField *focusLabel;
@property (weak) IBOutlet NSSlider *exposureSlider;
@property (weak) IBOutlet NSButton *exposureSwitch;
@property (weak) IBOutlet NSTextField *exposureLabel;
@property (weak) IBOutlet NSTextField *irisLabel;
@property (weak) IBOutlet NSSlider *irisSlider;
@property (weak) IBOutlet NSButton *irisSwitch;
@property (weak) IBOutlet NSTextField *panoramaLabel;
@property (weak) IBOutlet NSSlider *panoramaSlider;
@property (weak) IBOutlet NSButton *panoramaSwitch;
@property (weak) IBOutlet NSTextField *tiltLabel;
@property (weak) IBOutlet NSSlider *tiltSlider;
@property (weak) IBOutlet NSButton *tiltSwitch;
@property (weak) IBOutlet NSTextField *rollLabel;
@property (weak) IBOutlet NSSlider *rollSlider;
@property (weak) IBOutlet NSButton *rollSwitch;
@property (weak) IBOutlet NSButton *lowBrightnessCompensateSwitch;
@end

@implementation AppDelegate
- (void)flipSet{
    if (self.flipHorizontalButton.state == NSControlStateValueOn && self.flipVerticalButton.state == NSControlStateValueOn) {
        [uvcController setUVCExtensionSettingValue:FlipHorizontalOnAndFlipVerticalOn];
    } else if (self.flipHorizontalButton.state == NSControlStateValueOff && self.flipVerticalButton.state == NSControlStateValueOn) {
        [uvcController setUVCExtensionSettingValue:FlipHorizontalOffAndFlipVerticalOn];
    } else if (self.flipHorizontalButton.state == NSControlStateValueOn && self.flipVerticalButton.state == NSControlStateValueOff) {
        [uvcController setUVCExtensionSettingValue:FlipHorizontalOnAndFlipVerticalOff];
    } else if (self.flipHorizontalButton.state == NSControlStateValueOff && self.flipVerticalButton.state == NSControlStateValueOff) {
        [uvcController setUVCExtensionSettingValue:FlipHorizontalOffAndFlipVerticalOff];
    }
}

// setting
- (void)settingPageUpdate{
    UVCExtensionSettingValue flipValue= [uvcController getFlipValue];
    switch (flipValue) {
        case FlipHorizontalOnAndFlipVerticalOn:
            [self.flipHorizontalButton setState:NSControlStateValueOn];
            [self.flipVerticalButton setState:NSControlStateValueOn];
            break;
        
        case FlipHorizontalOffAndFlipVerticalOn:
            [self.flipHorizontalButton setState:NSControlStateValueOff];
            [self.flipVerticalButton setState:NSControlStateValueOn];
            break;
            
        case FlipHorizontalOnAndFlipVerticalOff:
            [self.flipHorizontalButton setState:NSControlStateValueOn];
            [self.flipVerticalButton setState:NSControlStateValueOff];
            break;
            
        case FlipHorizontalOffAndFlipVerticalOff:
            [self.flipHorizontalButton setState:NSControlStateValueOff];
            [self.flipVerticalButton setState:NSControlStateValueOff];
            break;
            
        default:
            break;
    }
}

- (IBAction)resetCameraAction:(id)sender {
    if ([uvcController setUVCExtensionSettingValue:UVCFactoryReset]) {
        [self imageCtrlPageUpdate];
        [self cameraCtrlPageUpdate];
    }
}

- (IBAction)flipVerticalAction:(id)sender {
    [self flipSet];
}

- (IBAction)flipHorizontalAction:(id)sender {
    [self flipSet];
}

// imageCtrl
- (void)imageCtrlPageUpdate{
    _brightnessSlider.minValue = [uvcController minBright];
    _brightnessSlider.maxValue = [uvcController maxBright];
    _brightnessSlider.altIncrementValue = 1;
    [_brightnessSlider setIntegerValue:[uvcController bright]];
    [_brightnessLabel setStringValue:@(_brightnessSlider.intValue).stringValue];
    
    _contrastSlider.minValue = [uvcController minContrast];
    _contrastSlider.maxValue = [uvcController maxContrast];
    _contrastSlider.altIncrementValue = 1;
    [_contrastSlider setIntegerValue:[uvcController contrast]];
    [_contrastLabel setStringValue:@(_contrastSlider.intValue).stringValue];
    
    [_hueSlider setIntegerValue:[uvcController hue]];
    _hueSlider.minValue = [uvcController minHue];
    _hueSlider.maxValue = [uvcController maxHue];
    _hueSlider.altIncrementValue = 1;
    [_hueLabel setStringValue:@(_hueSlider.intValue).stringValue];
    
    [_saturateSlider setIntegerValue:[uvcController saturation]];
    _saturateSlider.minValue = [uvcController minSaturation];
    _saturateSlider.maxValue = [uvcController maxSaturation];
    _saturateSlider.altIncrementValue = 1;
    [_saturateLabel setStringValue:@(_saturateSlider.intValue).stringValue];
    
    _sharpnessSlider.minValue = [uvcController minSharpness];
    _sharpnessSlider.maxValue = [uvcController maxSharpness];
    _sharpnessSlider.altIncrementValue = 1;
    [_sharpnessSlider setIntegerValue:[uvcController sharpness]];
    [_sharpnessLabel setStringValue:@(_sharpnessSlider.intValue).stringValue];
    
    _gammaSlider.minValue = [uvcController minGamma];
    _gammaSlider.maxValue = [uvcController maxGamma];
    _gammaSlider.altIncrementValue = 1;
    [_gammaSlider setIntegerValue:[uvcController gamma]];
    [_gammaLabel setStringValue:@(_gammaSlider.intValue).stringValue];
    
    
    [_whiteBalanceSwitch setState:[uvcController isAutoWhiteBalance]?NSControlStateValueOn:NSControlStateValueOff];
    _whiteBalanceSlider.minValue = [uvcController minWhiteBalance];
    _whiteBalanceSlider.maxValue = [uvcController maxWhiteBalance];
    _whiteBalanceSlider.altIncrementValue = 1;
    [_whiteBalanceSlider setIntegerValue:[uvcController whiteBalance]];
    [_whiteBalanceLabel setStringValue:@(_whiteBalanceSlider.intValue).stringValue];
    if ([uvcController isAutoWhiteBalance]) {
        _whiteBalanceSlider.enabled = false;
    } else {
        _whiteBalanceSlider.enabled = true;
    }
    
    _backlightContrastSlider.minValue = [uvcController minBacklight];
    _backlightContrastSlider.maxValue = [uvcController maxBacklight];
    _backlightContrastSlider.altIncrementValue = 1;
    [_backlightContrastSlider setIntegerValue:[uvcController backlight]];
    [_backlightLabel setStringValue:@(_backlightContrastSlider.intValue).stringValue];
    
    _gainSlider.minValue = [uvcController minGain];
    _gainSlider.maxValue = [uvcController maxGain];
    _gainSlider.altIncrementValue = 1;
    [_gainSlider setIntegerValue:[uvcController gain]];
    [_gainLabel setStringValue:@(_gainSlider.intValue).stringValue];
    
    [_anitFickerSelector selectItemAtIndex:[uvcController powerLine]];
}

- (IBAction)brightnessSlideAction:(id)sender {
    [uvcController setBright:_brightnessSlider.intValue];
    [_brightnessLabel setStringValue:@(_brightnessSlider.intValue).stringValue];
}

- (IBAction)brightnessAutoAction:(id)sender {
}

- (IBAction)contrastSlideAction:(id)sender {
    [uvcController setContrast:_contrastSlider.intValue];
    [_contrastLabel setStringValue:@(_contrastSlider.intValue).stringValue];
}

- (IBAction)contrastAutoAction:(id)sender {
}


- (IBAction)hueSlideAction:(id)sender {
    [uvcController setHue:_hueSlider.intValue];
    [_hueLabel setStringValue:@(_hueSlider.intValue).stringValue];
}

- (IBAction)hueAutoAction:(id)sender {
}


- (IBAction)saturateSlideAction:(id)sender {
    [uvcController setSaturation:_saturateSlider.intValue];
    [_saturateLabel setStringValue:@(_saturateSlider.intValue).stringValue];
}

- (IBAction)saturateAutoAction:(id)sender {
}


- (IBAction)sharpnessSlideAction:(id)sender {
    [uvcController setSharpness:_sharpnessSlider.intValue];
    [_sharpnessLabel setStringValue:@(_sharpnessSlider.intValue).stringValue];
}

- (IBAction)sharpnessAutoAction:(id)sender {
}


- (IBAction)gammaSlideAction:(id)sender {
    [uvcController setGamma:_gammaSlider.intValue];
    [_gammaLabel setStringValue:@(_gammaSlider.intValue).stringValue];
}

- (IBAction)gammaAutoAction:(id)sender {
}


- (IBAction)whiteBalanceAction:(id)sender {
    [uvcController setWhiteBalance:_whiteBalanceSlider.intValue];
    [_whiteBalanceLabel setStringValue:@(_whiteBalanceSlider.intValue).stringValue];
}

- (IBAction)whiteBalanceAutoAction:(id)sender {
    if (_whiteBalanceSwitch.state == NSControlStateValueOn){
        [uvcController setAutoWhiteBalance:true];
        _whiteBalanceSlider.enabled = false;
    } else {
        [uvcController setAutoWhiteBalance:false];
        [uvcController setWhiteBalance:_whiteBalanceSlider.intValue];
        _whiteBalanceSlider.enabled = true;
    }
}

- (IBAction)backlightContracstAction:(id)sender {
    [uvcController setBacklight:_backlightContrastSlider.intValue];
    [_backlightLabel setStringValue:@(_backlightContrastSlider.intValue).stringValue];
}

- (IBAction)backlightAutoAction:(id)sender {
}


- (IBAction)gainSlideAction:(id)sender {
    [uvcController setGain:_gainSlider.intValue];
    [_gainLabel setStringValue:@(_gainSlider.intValue).stringValue];
}

- (IBAction)gainAutoAction:(id)sender {
}

- (IBAction)antiFickerPopUpButton:(id)sender {
    NSPopUpButton *pop = sender;
    [uvcController setPowerLine:(int)pop.indexOfSelectedItem];
}

- (IBAction)imageCtrlDefaultAction:(id)sender {
    [uvcController rollbackImageCtrlParams];
    [self imageCtrlPageUpdate];
}

- (IBAction)imageCtrlApplyAction:(id)sender {
    [uvcController saveImageCtrlParamToCache];
    [self imageCtrlPageUpdate];
}

- (IBAction)imageCtrlCancelAction:(id)sender {
    [uvcController rollbackImageCtrlParams];
    [self imageCtrlPageUpdate];
}

// camera Ctrl
- (void)cameraCtrlPageUpdate{
    [_zoomLabel setIntegerValue:[uvcController zoom]];
    _zoomSlider.minValue = [uvcController minZoom];
    _zoomSlider.maxValue = [uvcController maxZoom];
    _zoomSlider.altIncrementValue = 1;
    [_zoomSlider setIntegerValue:[uvcController zoom]];
    [_zoomLabel setStringValue:@(_zoomSlider.intValue).stringValue];
    
    _focusSlider.minValue = [uvcController minFocus];
    _focusSlider.maxValue = [uvcController maxFocus];
    _focusSlider.altIncrementValue = 1;
    [_focusSlider setIntegerValue:[uvcController focus]];
    [_focusLabel setStringValue:@(_focusSlider.intValue).stringValue];
    
    _exposureSlider.minValue = [uvcController minExposureTime];
    _exposureSlider.maxValue = [uvcController maxExposureTime];
    _exposureSlider.altIncrementValue = 1;
    [_exposureSlider setIntegerValue:[uvcController exposureTime]];
    [_exposureLabel setStringValue:@(_exposureSlider.intValue).stringValue];
    [_exposureSwitch setState:[uvcController isExposureAutoMode]?NSControlStateValueOn:NSControlStateValueOff];
    if ([uvcController isExposureAutoMode]){
        _exposureSlider.enabled = false;
    } else {
        _exposureSlider.enabled = true;
    }
    
    _irisSlider.minValue = [uvcController minIris];
    _irisSlider.maxValue = [uvcController maxIris];
    _irisSlider.altIncrementValue = 1;
    [_irisSlider setIntegerValue:[uvcController iris]];
    [_irisLabel setStringValue:@(_irisSlider.intValue).stringValue];
    
    _panoramaSlider.minValue = [uvcController minAbsPan]/3600;
    _panoramaSlider.maxValue = [uvcController maxAbsPan]/3600;
    _panoramaSlider.altIncrementValue = 1;
    [_panoramaSlider setIntegerValue:[uvcController absPan]/3600];
    [_panoramaLabel setStringValue:@(_panoramaSlider.intValue).stringValue];
    
    _tiltSlider.minValue = [uvcController minAbsTilt]/3600;
    _tiltSlider.maxValue = [uvcController maxAbsTilt]/3600;
    _tiltSlider.altIncrementValue = 1;
    [_tiltSlider setIntegerValue:[uvcController absTilt]/3600];
    [_tiltLabel setStringValue:@(_tiltSlider.intValue).stringValue];
    
    _rollSlider.minValue = [uvcController minRoll];
    _rollSlider.maxValue = [uvcController maxRoll];
    _rollSlider.altIncrementValue = 1;
    [_rollSlider setIntegerValue:[uvcController roll]];
    [_rollLabel setStringValue:@(_rollSlider.intValue).stringValue];
}

- (IBAction)cameraCtrlDefautAction:(id)sender {
    [uvcController resetDefaultCameraCtrlParams];
    [self cameraCtrlPageUpdate];
}

- (IBAction)cameraCtrlCancelAction:(id)sender {
    [uvcController rollbackCameraCtrlParams];
    [self cameraCtrlPageUpdate];
}

- (IBAction)cameraCtrlApplyAction:(id)sender {
    [uvcController saveCameraCtrlParamToCache];
    [self cameraCtrlPageUpdate];
}

- (IBAction)zoomSliderAction:(id)sender {
    [uvcController setZoom:_zoomSlider.intValue];
    [_zoomLabel setStringValue:@(_zoomSlider.intValue).stringValue];
}

- (IBAction)zoomSwitchAction:(id)sender {
}

- (IBAction)focusSliderAction:(id)sender {
    [uvcController setFocus:_focusSlider.intValue];
    [_focusLabel setStringValue:@(_focusSlider.intValue).stringValue];
}

- (IBAction)focusSwitchAction:(id)sender {
}

- (IBAction)exposureSliderAction:(id)sender {
    [uvcController setExposureTime:_exposureSlider.intValue];
    [_exposureLabel setStringValue:@(_exposureSlider.intValue).stringValue];
}

- (IBAction)exposureSwitchAction:(id)sender {
    if (_exposureSwitch.state == NSControlStateValueOn) {
        [uvcController setAutoExposureMode:UVC_AEMode_AperturePriority];
        _exposureSlider.enabled = false;
    } else {
        [uvcController setAutoExposureMode:UVC_AEMode_Manual];
        [uvcController setExposureTime:_exposureSlider.intValue];
        _exposureSlider.enabled = true;
    }
}

- (IBAction)irisSliderAction:(id)sender {
    [uvcController setIris:_irisSlider.intValue];
    [_irisLabel setStringValue:@(_irisSlider.intValue).stringValue];
}

- (IBAction)irisAutoAction:(id)sender {
}

- (IBAction)panoramaSliderAction:(id)sender {
    [uvcController setAbsPan:_panoramaSlider.intValue*3600];
    [_panoramaLabel setStringValue:@(_panoramaSlider.intValue).stringValue];
}

- (IBAction)panoramaAutoAction:(id)sender {
}

- (IBAction)tiltSliderAction:(id)sender {
    [uvcController setAbsTilt:_tiltSlider.intValue*3600];
    [_tiltLabel setStringValue:@(_tiltSlider.intValue).stringValue];
}

- (IBAction)tiltAutoAction:(id)sender {
}

- (IBAction)rollSliderAction:(id)sender {
    [uvcController setRoll:_rollSlider.intValue];
    [_rollLabel setStringValue:@(_rollSlider.intValue).stringValue];
}

- (IBAction)rollAutoAction:(id)sender {
}

- (IBAction)lowBrightnessCompensateAction:(id)sender {
}

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
        [uvcController setRelativeZoomControl:0xFF];
	} else if (sender == zoom_out){
		[zoom_out setImage:[NSImage imageNamed:@"zoom-out_blue"]];
        [uvcController setRelativeZoomControl:1];
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
        [uvcController setZoom:0];
        [uvcController resetPanTilt];
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
//	[uvcController openSettingsWindow];
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

		vidSrc = nil;
		uvcController = nil;

		vidSrc = [[UVCCaptureVideoSource alloc] init];
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
		[UVCUtils showAlert:@"Failed to start upgrade mode! !" title:@"Exception" window:mainView.window completionHandler:nil];
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
	
	mainWindow.delegate = self;
	self.gplWindow.delegate = self;
	self.ctrlWindow.delegate = self;
	[self.gplWindow close];
	[self.ctrlWindow close];
}


- (IBAction)openMenuAction:(id)sender {
	NSLog(@"openMenuAction %@", self.uvcSettingMenu.view);
	NSPoint point = mainWindow.contentView.frame.origin;
	point.x = mainWindow.contentView.frame.size.width - 64;
	point.y = mainWindow.contentView.frame.size.height ;
	[self.customMenu popUpMenuPositioningItem:nil atLocation:point inView:mainWindow.contentView];
}

- (void)windowWillClose:(NSNotification *)nofi{
	NSWindow *window = nofi.object;
	if (window == mainWindow){
		[[NSApplication sharedApplication] terminate:nil];
	} else if (window == self.gplWindow || window == self.ctrlWindow){
		self.childWindowsState = ChildWindows_HIDEN;
        if (self.ctrlWindow == window){
            [uvcController rollbackCameraCtrlParams];
            [self cameraCtrlPageUpdate];
            [uvcController rollbackImageCtrlParams];
            [self imageCtrlPageUpdate];
        }
	}
}

- (void)windowDidMiniaturize:(NSNotification *)nofi{
	[self.gplWindow close];
	[self.ctrlWindow close];
}

- (void)windowDidDeminiaturize:(NSNotification *)notification{
	if (self.childWindowsState == ChildWindows_CTRL) {
		[_ctrlWindow makeKeyAndOrderFront:nil];
	} else if (self.childWindowsState == ChildWindows_GPL){
		[_gplWindow makeKeyAndOrderFront:nil];
	}
}

- (void)windowDidMove:(NSNotification *)nofi{
	NSLog(@"%@", nofi);
	NSWindow *window = nofi.object;
	if (![window isKeyWindow] || self.childWindowsState == ChildWindows_HIDEN) {
		return;
	}
	
	if (nofi.object == mainWindow){
		NSPoint point = mainWindow.frame.origin;
		point.x = mainWindow.frame.size.width + point.x;
		
		if (self.childWindowsState == ChildWindows_CTRL) {
			[_ctrlWindow setFrameOrigin:point];
		} else {
			[_gplWindow setFrameOrigin:point];
		}
	} else if (nofi.object == self.gplWindow || nofi.object == self.ctrlWindow){
		NSWindow *window = nofi.object;
		NSPoint point = window.frame.origin;
		point.x =  point.x - mainWindow.frame.size.width;
		
		[mainWindow setFrameOrigin:point];
	}
}


- (IBAction)openGPL:(id)sender {
	NSPoint point = mainWindow.frame.origin;
	point.x = mainWindow.frame.size.width + point.x;
	
	[_ctrlWindow setFrameOrigin:point];
	[_gplWindow setFrameOrigin:point];
	[_gplWindow makeKeyAndOrderFront:nil];
	[_ctrlWindow close];
	
	self.childWindowsState = ChildWindows_GPL;
}

- (IBAction)openCtrl:(id)sender {
	NSPoint point = mainWindow.frame.origin;
	point.x = mainWindow.frame.size.width + point.x;
	
	[_ctrlWindow setFrameOrigin:point];
	[_gplWindow setFrameOrigin:point];
	
	[_ctrlWindow makeKeyAndOrderFront:nil];
	[_gplWindow close];
	
	self.childWindowsState = ChildWindows_CTRL;
}


- (void) populateCamPopUpButton	{
	NSXLog(@"populateCamPopUpButton");
	[camPUB removeAllItems];
	
	NSArray		*devicesMenuItems = [vidSrc arrayOfSourceMenuItems];
	for (NSMenuItem *itemPtr in devicesMenuItems){
		[[camPUB menu] addItem:itemPtr];
	}
	if (devicesMenuItems.count == 0) {
		NSMenuItem		*newItem = [[NSMenuItem alloc] initWithTitle:@"choose camera" action:nil keyEquivalent:@""];
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
            [UVCUtils showAlert:@"Please check the new version number of the device!" title:@"End of update" window:mainView.window completionHandler:nil];
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
	[self.gplWindow close];
	[self.ctrlWindow close];
	
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
    [UVCUtils showAlert:errMsg title:@"Exception" window:mainView.window completionHandler:nil];
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
            [versionTextView setString:@"During the upgrade, please do not plug and unplug any usb devices, and do not disconnect the camera!"];
            break;
        
        case UVCUpdateStateDownloadBinFileSuccess:
            [versionTextView setString:@"During the upgrade, please do not plug and unplug any usb devices, and do not disconnect the camera! \n1. The bin file is successfully transferred, and the upgrade is in progress...."];
            break;
            
        case UVCUpdateStateRestarting:
            [versionTextView setString:@"During the upgrade, please do not plug and unplug any usb devices, and do not disconnect the camera! \n1. The bin file is successfully transferred \n2. The upgrade is successful, the device is restarting..."];
            break;
            
        case UVCUpdateStateSuccess:
            [versionTextView setString:@"During the upgrade, please do not plug and unplug any usb devices, and do not disconnect the camera! \n1. The bin file was transferred successfully \n2. The update file was successful\n3. The version was upgraded successfully"];
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
        
        [self updateDeviceBinFail:@"Failed to download the update file, please restart the device and try again! !"];
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
	[uvcController closeSettingsWindow];
    uvcController = [[UVCController alloc] initWithDeviceIDString:deviceId];
    if (uvcController==nil){
        NSXLog(@"Couldn't create UVCController");
        [versionTextView setString:@""];
    } else    {
        if ([uvcController zoomSupported]) {
            [uvcController resetPanTilt];
            [uvcController setZoom:0];
        }
		
		[UVCUIController updateController:uvcController];
		[uvcController closeSettingsWindow];
        [self imageCtrlPageUpdate];
        [self cameraCtrlPageUpdate];
        [self settingPageUpdate];
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
	uvcController = [[UVCController alloc] initWithDeviceIDString:[vidSrc currentDeivceId]];
	if (uvcController==nil){
		NSXLog(@"Couldn't create UVCController");
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
	uvcController = [[UVCController alloc] initWithDeviceIDString:[vidSrc currentDeivceId]];
	if (uvcController==nil){
		NSXLog(@"Couldn't create UVCController");
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
@end

