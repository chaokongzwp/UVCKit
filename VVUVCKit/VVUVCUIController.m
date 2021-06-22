#import "VVUVCUIController.h"
#import "VVUVCController.h"
#import "UVCUtils.h"


BOOL checkHexStr(const char *hexStr, unsigned long len){
	for (unsigned long i = 0 ; i < len; i++) {
		if (hexStr[i] >= '0' && hexStr[i] <= '9') {
			continue;
		}
		
		if (hexStr[i] >= 'a' && hexStr[i] <= 'f') {
			continue;
		}
		
		return NO;
	}
	
	return YES;
}

unsigned long StringToHex(NSString *orig, unsigned int *outChar, unsigned long *outlen) {
	const char *str = [orig lowercaseString].UTF8String;

	char high = 0, low = 0;
	unsigned long tmplen = strlen(str), cnt = 0;
	if (tmplen > 2 && str[0] == '0' && str[1] == 'x') {
		str = str + 2;
		tmplen = tmplen - 2;
	}
	
	if (!checkHexStr(str, tmplen)) {
		*outlen = 0;
		return 0;
	}
	
	const char *p = str + tmplen - 1;
	while(cnt < (tmplen / 2)){
		low = ((*p > '9') && ((*p <= 'F') || (*p <= 'f'))) ? *p - 48 - 7 : *p - 48;
		high = (*(--p) > '9' && ((*p <= 'F') || (*p <= 'f'))) ? *(p) - 48 - 7 : *(p) - 48;
		outChar[cnt] = ((high & 0x0f) << 4 | (low & 0x0f));
		p--;
		cnt++;
	}
	
	if(tmplen % 2 != 0) outChar[cnt] = ((*p > '9') && ((*p <= 'F') || (*p <= 'f'))) ? *p - 48 - 7 : *p - 48;
	
	if(outlen != NULL) *outlen = tmplen / 2 + tmplen % 2;
	return tmplen / 2 + tmplen % 2;
}

@implementation VVUVCUIController


- (id) init	{
	if (self = [super init])	{
		return self;
	}
	return nil;
}

- (int)one:(NSString *)one{
	unsigned int outChar[128];
	unsigned long outlen = 0;
	memset(outChar, 0, 128*sizeof(int));
	StringToHex(one, outChar, &outlen);
	if (outlen != 1) {
		return -1;
	}
	
	return outChar[0];
}

- (int)two:(NSString *)two{
	unsigned int outChar[256];
	unsigned long outlen = 0;
	memset(outChar, 0, 256*sizeof(int));
	StringToHex(two, outChar, &outlen);
	if (outlen != 2) {
		return -1;
	}
	
	return outChar[1]<<8|outChar[0];
}

- (int)four:(NSString *)four{
	unsigned int outChar[1024];
	unsigned long outlen = 0;
	
	memset(outChar, 0, 1024*sizeof(int));
	StringToHex(four, outChar, &outlen);
	if (outlen != 4) {
		return -1;
	}
	
	return outChar[3]<<24|outChar[2]<<16|outChar[1]<<8|outChar[0];
}

- (void) awakeFromNib	{
	[expElement setTitle:@"Exposure Time"];
	[irisElement setTitle:@"Iris"];
	[focusElement setTitle:@"Focus"];
	[zoomElement setTitle:@"Zoom"];

	[backlightElement setTitle:@"Backlight Compensation"];
	[brightElement setTitle:@"Brightness"];
	[contrastElement setTitle:@"Contrast"];
	[gainElement setTitle:@"Gain"];
	[powerElement setTitle:@"Power Line Frequency"];
	[hueElement setTitle:@"Hue"];
	[satElement setTitle:@"Saturation"];
	[sharpElement setTitle:@"Sharpness"];
	[gammaElement setTitle:@"Gamma"];
	[wbElement setTitle:@"White Balance"];
}

- (IBAction)sendCommand:(id)sender {
	NSString *dataStr = [data stringValue];
	
	int					returnMe = 0;
	IOUSBDevRequest		controlRequest;
	returnMe = [self one:[bmRequestType stringValue]];
	if (returnMe == -1) {
		[UVCUtils showAlert:[NSString stringWithFormat:@"%@不满足16机制格式", [bmRequestType stringValue]] title:@"参数异常" window:mainView.window completionHandler:nil];
		return;
	}
	controlRequest.bmRequestType = returnMe;
	
	returnMe = [self one:[bRequest stringValue]];
	if (returnMe == -1) {
		[UVCUtils showAlert:[NSString stringWithFormat:@"%@不满足16机制格式", [bRequest stringValue]] title:@"参数异常" window:mainView.window completionHandler:nil];
		return;
	}
	controlRequest.bRequest = returnMe;
	
	returnMe = [self two:[wValue stringValue]];
	if (returnMe == -1) {
		[UVCUtils showAlert:[NSString stringWithFormat:@"%@不满足16机制格式", [wValue stringValue]] title:@"参数异常" window:mainView.window completionHandler:nil];
		return;
	}
	controlRequest.wValue = returnMe;
	
	returnMe = [self two:[wIndex stringValue]];
	if (returnMe == -1) {
		[UVCUtils showAlert:[NSString stringWithFormat:@"%@不满足16机制格式", [wIndex stringValue]] title:@"参数异常" window:mainView.window completionHandler:nil];
		return;
	}
	controlRequest.wIndex = returnMe;
	
	if ([wLength stringValue].length <= 2){
		controlRequest.wLength = [self one:[wLength stringValue]];
	} else {
		controlRequest.wLength = [self two:[wLength stringValue]];
	}
	
	controlRequest.wLenDone = 0;
	UInt8 *ret = malloc(controlRequest.wLength);
	NSArray *data = [dataStr componentsSeparatedByString:@" "];
	bzero(ret,controlRequest.wLength);
	if (data.count > controlRequest.wLength) {
		[UVCUtils showAlert:@"data长度超过wLength的值" title:@"参数异常" window:mainView.window completionHandler:nil];
		return;
	}
	
	for (int i = 0; i<data.count; i++) {
		returnMe = [self one:data[i]];
		if (returnMe == -1) {
			[UVCUtils showAlert:[NSString stringWithFormat:@"%@不满足16机制格式", dataStr] title:@"参数异常" window:mainView.window completionHandler:nil];
			return;
		}
		*(ret + i) = returnMe;
	}
	controlRequest.pData = ret;
	

	if (![device _sendControlRequest:&controlRequest]) {
		returnMe = -1;
	}else {
		returnMe = controlRequest.wLenDone;
	}
	
	NSString *retStr = @"";
	for (int i = 0; i < controlRequest.wLength; i++) {
		[retStr stringByAppendingFormat:@"0x%2X ", ret[i]];
	}
	
	if (returnMe <= 0)	{
		free(ret);
		ret = nil;
		controlRequest.pData = nil;
		[UVCUtils showAlert:@"请检查命令参数是否正确" title:@"请求失败" window:mainView.window completionHandler:nil];
		return;
	}
	
	[UVCUtils showAlert:retStr title:@"请求成功" window:mainView.window completionHandler:nil];
}


- (void) controlElementChanged:(id)sender	{
	NSLog(@"%s",__func__);
	if (sender == expElement)	{
		[device setExposureTime:[sender val]];
	}
	else if (sender == irisElement)	{
		[device setIris:[sender val]];
	}
	else if (sender == focusElement)	{
		[device setFocus:[sender val]];
	}
	else if (sender == zoomElement)	{
		[device setZoom:[sender val]];
	}
	else if (sender == backlightElement)	{
		[device setBacklight:[sender val]];
	}
	else if (sender == brightElement)	{
		[device setBright:[sender val]];
	}
	else if (sender == contrastElement)	{
		[device setContrast:[sender val]];
	}
	else if (sender == gainElement)	{
		[device setGain:[sender val]];
	}
	else if (sender == powerElement)	{
		[device setPowerLine:[sender val]];
	}
	else if (sender == hueElement)	{
		[device setHue:[sender val]];
	}
	else if (sender == satElement)	{
		[device setSaturation:[sender val]];
	}
	else if (sender == sharpElement)	{
		[device setSharpness:[sender val]];
	}
	else if (sender == gammaElement)	{
		[device setGamma:[sender val]];
	}
	else if (sender == wbElement)	{
		[device setWhiteBalance:[sender val]];
	}
	[self _pushCameraControlStateToUI];
}
- (IBAction) buttonUsed:(id)sender	{
	if (sender == expPriorityButton)	{
		[device setAutoExposurePriority:([sender intValue]==NSOnState) ? YES : NO];
	}
	else if (sender == autoFocusButton)	{
		if ([sender intValue] == NSOnState)	{
			[device setAutoFocus:YES];
		}
		else	{
			[device setAutoFocus:NO];
		}
		[self _pushCameraControlStateToUI];
	}
	else if (sender == autoHueButton)	{
		if ([sender intValue] == NSOnState)	{
			[device setAutoHue:YES];
		}
		else	{
			[device setAutoHue:NO];
		}
		[self _pushCameraControlStateToUI];
	}
	else if (sender == autoWBButton)	{
		if ([sender intValue] == NSOnState)	{
			[device setAutoWhiteBalance:YES];
		}
		else	{
			[device setAutoWhiteBalance:NO];
		}
		[self _pushCameraControlStateToUI];
	}
}
- (IBAction) popUpButtonUsed:(id)sender	{
	//NSLog(@"%s ... %d",__func__,[sender indexOfSelectedItem]);
	if (sender == autoExpButton)	{
		int		selectedIndex = (int)[sender indexOfSelectedItem];
		if (selectedIndex == 0)	{
			[device setAutoExposureMode:UVC_AEMode_Manual];
		}
		else if (selectedIndex == 1)	{
			[device setAutoExposureMode:UVC_AEMode_Auto];
		}
		else if (selectedIndex == 2)	{
			[device setAutoExposureMode:UVC_AEMode_ShutterPriority];
		}
		else if (selectedIndex == 3)	{
			[device setAutoExposureMode:UVC_AEMode_AperturePriority];
		}
		[self _pushCameraControlStateToUI];
	}
}


- (IBAction) resetToDefaults:(id)sender	{
	//NSLog(@"%s",__func__);
	[device resetParamsToDefaults];
	[self _pushCameraControlStateToUI];
}


- (void) _pushCameraControlStateToUI	{
	if ([device exposureTimeSupported])	{
		[expElement setMin:(int)[device minExposureTime]];
		[expElement setMax:(int)[device maxExposureTime]];
		[expElement setVal:(int)[device exposureTime]];
	}
	[expElement setEnabled:[device exposureTimeSupported]];

	if ([device irisSupported])	{
		[irisElement setMin:(int)[device minIris]];
		[irisElement setMax:(int)[device maxIris]];
		[irisElement setVal:(int)[device iris]];
	}
	[irisElement setEnabled:[device irisSupported]];

	if ([device zoomSupported])	{
		[zoomElement setMin:(int)[device minZoom]];
		[zoomElement setMax:(int)[device maxZoom]];
		[zoomElement setVal:(int)[device zoom]];
	}
	[zoomElement setEnabled:[device zoomSupported]];

	if ([device backlightSupported])	{
		[backlightElement setMin:(int)[device minBacklight]];
		[backlightElement setMax:(int)[device maxBacklight]];
		[backlightElement setVal:(int)[device backlight]];
	}
	[backlightElement setEnabled:[device backlightSupported]];

	if ([device brightSupported])	{
		[brightElement setMin:(int)[device minBright]];
		[brightElement setMax:(int)[device maxBright]];
		[brightElement setVal:(int)[device bright]];
	}
	[brightElement setEnabled:[device brightSupported]];

	if ([device contrastSupported])	{
		[contrastElement setMin:(int)[device minContrast]];
		[contrastElement setMax:(int)[device maxContrast]];
		[contrastElement setVal:(int)[device contrast]];
	}
	[contrastElement setEnabled:[device contrastSupported]];
	
	if ([device gainSupported])	{
		[gainElement setMin:(int)[device minGain]];
		[gainElement setMax:(int)[device maxGain]];
		[gainElement setVal:(int)[device gain]];
	}
	[gainElement setEnabled:[device gainSupported]];

	if ([device powerLineSupported])	{
		[powerElement setMin:(int)[device minPowerLine]];
		[powerElement setMax:(int)[device maxPowerLine]];
		[powerElement setVal:(int)[device powerLine]];
	}
	[powerElement setEnabled:[device powerLineSupported]];
	
	if ([device saturationSupported])	{
		[satElement setMin:(int)[device minSaturation]];
		[satElement setMax:(int)[device maxSaturation]];
		[satElement setVal:(int)[device saturation]];
	}
	[satElement setEnabled:[device saturationSupported]];

	if ([device sharpnessSupported])	{
		[sharpElement setMin:(int)[device minSharpness]];
		[sharpElement setMax:(int)[device maxSharpness]];
		[sharpElement setVal:(int)[device sharpness]];
	}
	[sharpElement setEnabled:[device sharpnessSupported]];

	if ([device gammaSupported])	{
		[gammaElement setMin:(int)[device minGamma]];
		[gammaElement setMax:(int)[device maxGamma]];
		[gammaElement setVal:(int)[device gamma]];
	}
	
	[expPriorityButton setEnabled:[device autoExposurePrioritySupported]];
	[expPriorityButton setIntValue:([device autoExposurePriority]) ? NSOnState : NSOffState];
	
	[autoFocusButton setEnabled:([device autoFocusSupported]) ? YES : NO];
	[autoFocusButton setIntValue:([device autoFocus]) ? NSOnState : NSOffState];
	
	
	BOOL			enableFocusElement = NO;
	if ([device autoFocusSupported])	{
		[autoFocusButton setEnabled:YES];
		if ([device autoFocus])	{
			[autoFocusButton setIntValue:NSOnState];
		}
		else	{
			[autoFocusButton setIntValue:NSOffState];
			if ([device focusSupported])
				enableFocusElement = YES;
		}
	}
	else	{
		[autoFocusButton setEnabled:NO];
		[autoFocusButton setIntValue:NSOffState];
		if ([device focusSupported])
			enableFocusElement = YES;
	}
	[focusElement setEnabled:enableFocusElement];
	if (enableFocusElement)	{
		[focusElement setMin:(int)[device minFocus]];
		[focusElement setMax:(int)[device maxFocus]];
		[focusElement setVal:(int)[device focus]];
	} else [focusElement setVal:0];

	
	BOOL			enableHueElement = NO;
	if ([device autoHueSupported])	{
		[autoHueButton setEnabled:YES];
		if ([device autoHue])	{
			[autoHueButton setIntValue:NSOnState];
		}
		else	{
			[autoHueButton setIntValue:NSOffState];
			if ([device hueSupported])
				enableHueElement = YES;
		}
	}
	else	{
		[autoHueButton setEnabled:NO];
		[autoHueButton setIntValue:NSOffState];
		if ([device hueSupported])
			enableHueElement = YES;
	}
	[hueElement setEnabled:enableHueElement];
	if (enableHueElement)	{
		[hueElement setMin:(int)[device minHue]];
		[hueElement setMax:(int)[device maxHue]];
		[hueElement setVal:(int)[device hue]];
	} else [hueElement setVal:0];


	BOOL			enableWBElement = NO;
	if ([device autoWhiteBalanceSupported])	{
		[autoWBButton setEnabled:YES];
		if ([device autoWhiteBalance])	{
			[autoWBButton setIntValue:NSOnState];
		}
		else	{
			[autoWBButton setIntValue:NSOffState];
			if ([device whiteBalanceSupported])
				enableWBElement = YES;
		}
	}
	else	{
		[autoWBButton setEnabled:NO];
		[autoWBButton setIntValue:NSOffState];
		if ([device whiteBalanceSupported])
			enableWBElement = YES;
	}
	[wbElement setEnabled:enableWBElement];
	if (enableWBElement)	{
		[wbElement setMin:(int)[device minWhiteBalance]];
		[wbElement setMax:(int)[device maxWhiteBalance]];
		[wbElement setVal:(int)[device whiteBalance]];
	} else [wbElement setVal:0];


	UVC_AEMode		aeMode = [device autoExposureMode];
	switch (aeMode)	{
		case UVC_AEMode_Undefined:	//	hide both
			[autoExpButton selectItemAtIndex:0];
			[expElement setEnabled:NO];
			[irisElement setEnabled:NO];
			break;
		case UVC_AEMode_Manual:	//	show both
			[autoExpButton selectItemAtIndex:0];
			[expElement setEnabled:(YES && [device exposureTimeSupported])];
			[irisElement setEnabled:(YES && [device irisSupported])];
			break;
		case UVC_AEMode_Auto:	//	hide both
			[autoExpButton selectItemAtIndex:1];
			[expElement setEnabled:NO];
			[irisElement setEnabled:NO];
			[expElement setVal:0];
			break;
		case UVC_AEMode_ShutterPriority:
			[autoExpButton selectItemAtIndex:2];
			[expElement setEnabled:(YES && [device exposureTimeSupported])];
			[irisElement setEnabled:NO];
			break;
		case UVC_AEMode_AperturePriority:
			[autoExpButton selectItemAtIndex:3];
			[expElement setEnabled:NO];
			[irisElement setEnabled:(YES && [device irisSupported])];
			[expElement setVal:0];
			break;
	}
}
@end
