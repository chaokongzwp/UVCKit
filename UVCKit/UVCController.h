#import  <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOMessage.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#import  <USBBusProber/USBBusProber.h>
#import  "UVCKitStringAdditions.h"

typedef enum	{
	UVC_AEMode_Undefined = 0x00,	///	undefined auto exposure mode
	UVC_AEMode_Manual = 0x01,	///	manual exposure, manual iris
	UVC_AEMode_Auto = 0x02,	///	auto exposure, auto iris
	UVC_AEMode_ShutterPriority = 0x04,	///	manual exposure, auto iris
	UVC_AEMode_AperturePriority = 0x08	///	auto exposure, manual iris
} UVC_AEMode;

typedef enum : NSUInteger {
    FlipHorizontalOffAndFlipVerticalOff = 0x00,
    FlipHorizontalOnAndFlipVerticalOff = 0x01,
    FlipHorizontalOffAndFlipVerticalOn = 0x02,
    FlipHorizontalOnAndFlipVerticalOn = 0x03,
    UVCFactoryReset = 0xFF
} UVCExtensionSettingValue;

typedef struct {
	int		unit;	//	describes whether terminal/hardware or processing/software
	int		selector;	//	the address of the "parameter" being changed- 
	int		intendedSize;
	BOOL	hasMin;	//	whether or not the video control parameter described by this struct has a min val
	BOOL	hasMax;	//	whether or not the video control parameter described by this struct has a max
	BOOL	hasDef;	//	whether or not the video control parameter described by this struct has a default
	BOOL	isSigned;	//	whether or not the video control parameter described by this struct is a signed val
	BOOL	isRelative;	//	whether or not the video control parameter described by this struct is a relative val
} uvc_control_info_t;


typedef struct	{
	BOOL	supported;	//	if YES, this parameter is supported. if NO, either the camera doesn't support this parameter, or the "inputTerminalID" or "processingUnitID" of the camera is wrong!
	long	min;	//	the paramter's actual min val
	long	max;	//	the parameter's actual max val
	long	val;	//	the parameter's actual val
	long	def;	//	the parameter's default val
	int		actualSize;
	uvc_control_info_t	*ctrlInfo;
} uvc_param;

typedef struct {
    BOOL    supported;
    uvc_param pan;
    uvc_param tilt;
    uvc_control_info_t    *ctrlInfo;
}uvc_pan_tilt_abs_param;

typedef enum{
	UVC_PAN_TILT_UP,
	UVC_PAN_TILT_RIGHT,
	UVC_PAN_TILT_DOWN,
	UVC_PAN_TILT_LEFT,
	UVC_PAN_TILT_CANCEL
} UVC_PAN_TILT_DIRECTION;

// relative pan tilt operations
typedef struct {
	int8_t pan_direction;
	int8_t tilt_direction;
	uint8_t min_pan_speed;
	uint8_t min_tilt_speed;
	uint8_t max_pan_speed;
	uint8_t max_tilt_speed;
	uint8_t resolution_pan_speed;
	uint8_t resolution_tilt_speed;
	uint8_t default_pan_speed;
	uint8_t default_tilt_speed;
	uint8_t current_pan_speed;
	uint8_t current_tilt_speed;
	uvc_control_info_t	*ctrlInfo;
	BOOL supported;
	BOOL result;
	const char * error;
}RelativePanTiltInfo;

struct fireware_info{
	UInt8  CamVersion[3];   //firmware version of camera Version = byte1.byte2.byte3
	UInt8  dwCamDate[4];    //Year =  (byte4<<8) | byte5 Month = byte6 Day = byte7
	UInt8  ProductVer[32];    // AutoFocus Version = byte8.byte9.byte10
	UInt8  AuthorizedStated;  //Device  Authorized  Stated
} __attribute__((packed));


@interface UVCController : NSObject {
	IOUSBInterfaceInterface190		**interface;
	UInt32							deviceLocationID;
	UInt8							interfaceNumber;
	int								inputTerminalID;
	int								processingUnitID;
	int 							outputTerminalID;
	int								extensionUnitID;
	
	uvc_param			scanningMode;
	uvc_param			autoExposureMode;	//	mode functionality described by the type UVC_AEMode
	uvc_param			autoExposurePriority;	//	if 1, framerate may be varied.  if 0, framerate must remain constant.
	uvc_param			exposureTime;
	uvc_param			iris;
	uvc_param			autoFocus;
	uvc_param			focus;
	uvc_param			zoom;
    uvc_pan_tilt_abs_param	panTilt;
	RelativePanTiltInfo	panTiltRel;
	uvc_param			roll;
	uvc_param			rollRel;
	uvc_param			backlight;
	uvc_param			bright;
	uvc_param			contrast;
	uvc_param			gain;
	uvc_param			powerLine;
	uvc_param			autoHue;
	uvc_param			hue;
	uvc_param			saturation;
	uvc_param			sharpness;
	uvc_param			gamma;
	uvc_param			autoWhiteBalance;
	uvc_param			whiteBalance;
	
	NSNib				*theNib;
	NSArray				*nibTopLevelObjects;
	IBOutlet id			uiCtrlr;
	IBOutlet NSWindow	*settingsWindow;
	IBOutlet NSView		*settingsView;
	NSMutableArray<NSString *> *videoName;
}

- (id) initWithDeviceIDString:(NSString *)n;
- (id) initWithLocationID:(UInt32)locationID;
- (IOUSBInterfaceInterface190 **) _getControlInferaceWithDeviceInterface:(IOUSBDeviceInterface **)deviceInterface;
- (void) generalInit;
- (NSMutableDictionary *) createSnapshot;
- (void) loadSnapshot:(NSDictionary *)s;
- (BOOL) _sendControlRequest:(IOUSBDevRequest *)controlRequest;
- (int) _requestValType:(int)requestType forControl:(const uvc_control_info_t *)ctrl returnVal:(void **)ret;
- (BOOL) _setBytes:(void *)bytes sized:(int)size toControl:(const uvc_control_info_t *)ctrl;
- (void) _populateAllParams;
- (void) _populateParam:(uvc_param *)param;
- (BOOL) _pushParamToDevice:(uvc_param *)param;
- (void) _resetParamToDefault:(uvc_param *)param;
///	Resets the parameters to their default values.  The default values are supplied by/stored in the device.
- (void) resetParamsToDefaults;
///	Opens a window with a GUI for interacting with the camera parameters
- (void) openSettingsWindow;
///	Closes the GUI window (if it's open).
- (void) closeSettingsWindow;
- (void) setInterlaced:(BOOL)n;
- (BOOL) interlaced;
- (BOOL) interlacedSupported;
- (void) resetInterlaced;
///	Sets the auto exposure mode using one of the basic auto exposure modes defined in the header (vals pulled from the USB spec)
- (void) setAutoExposureMode:(UVC_AEMode)n;
///	Gets the auto exposure mode
- (UVC_AEMode) autoExposureMode;
///	Whether or not this camera supports the use of alternate auto exposure modes
- (BOOL) autoExposureModeSupported;
///	Resets the auto exposure mode to the hardware-defined default
- (void) resetAutoExposureMode;
///	Sets whether or not auto exposure will be given priority
- (void) setAutoExposurePriority:(BOOL)n;
///	Gets whether or not the camera is giving auto exposure priority
- (BOOL) autoExposurePriority;
///	Whether or not this camera supports the use of auto exposure priority
- (BOOL) autoExposurePrioritySupported;
///	Resets the auto exposure priority to the hardware-defined default
- (void) resetAutoExposurePriority;
///	Sets the exposure time to the passed value
- (void) setExposureTime:(long)n;
///	Gets the current exposure time value being used by the camera
- (long) exposureTime;
///	Whether or not this camera supports the exposure time parameter
- (BOOL) exposureTimeSupported;
///	Resets the exposure time value to the hardware-defined default
- (void) resetExposureTime;
///	The min exposure time value
- (long) minExposureTime;
///	The max exposure time value
- (long) maxExposureTime;
///	Sets the iris to the passed value
- (void) setIris:(long)n;
///	Gets the current iris value being used by the camera
- (long) iris;
///	Whether or not this camera supports the iris parameter
- (BOOL) irisSupported;
///	Resets the iris value to the hardware-defined default
- (void) resetIris;
///	The min iris value
- (long) minIris;
///	The max iris value
- (long) maxIris;
///	Sets the auto focus to the passed value
- (void) setAutoFocus:(BOOL)n;
///	Gets the auto focus value being used by the camera
- (BOOL) autoFocus;
///	Whether or not this camera supports the auto focus parameter
- (BOOL) autoFocusSupported;
///	Resets the auto focus value to the hardware-defined default.
- (void) resetAutoFocus;
///	Sets the focus value
- (void) setFocus:(long)n;
///	Gets the focus value currently being used by the camera
- (long) focus;
///	Whether or not this camera supports the focus parameter
- (BOOL) focusSupported;
///	Resets the focus value to the hardware-defined default
- (void) resetFocus;
///	The min focus value
- (long) minFocus;
///	The max focus value
- (long) maxFocus;
///	Sets the zoom value
- (void) setZoom:(long)n;
///	Gets the current zoom value being used by the camera
- (long) zoom;
///	Whether or not this camera supports the zoom parameter
- (BOOL) zoomSupported;
///	Resets the zoom value to the hardware-defined default
- (void) resetZoom;
///	The min zoom value
- (long) minZoom;
///	The max zoom value
- (long) maxZoom;
///	Sets the backlight to the passed value
- (void) setBacklight:(long)n;
///	Gets the backlight value currently being used by the camera
- (long) backlight;
///	Whether or not this camera supports the backlight parameter
- (BOOL) backlightSupported;
///	Resets the backlight value to the hardware-defined default
- (void) resetBacklight;
///	The min backlight value
- (long) minBacklight;
///	The max backlight value
- (long) maxBacklight;
///	Sets the bright value to the passed value
- (void) setBright:(long)n;
///	Gets the bright value currently being used by the camera
- (long) bright;
///	Whether or not this camera supports the bright parameter
- (BOOL) brightSupported;
///	Resets the bright parameter to the hardware-defined default
- (void) resetBright;
///	The min bright value
- (long) minBright;
///	The max bright value
- (long) maxBright;
///	Sets the contrast to the passed value
- (void) setContrast:(long)n;
///	Gets the contrast value currently being used by the camera
- (long) contrast;
///	Whether or not this camera supports the contrast parameter
- (BOOL) contrastSupported;
///	Resets the contrast to the hardware-defined default
- (void) resetContrast;
///	The min contrast value
- (long) minContrast;
///	The max contrast value
- (long) maxContrast;
///	Sets the gain to the passed value
- (void) setGain:(long)n;
///	Gets the gain value currently being used by the camera
- (long) gain;
///	Whether or not this camera supports the gain parameter
- (BOOL) gainSupported;
///	Resets the gain value to the hardware-defined default
- (void) resetGain;
///	The min gain value
- (long) minGain;
///	The max gain value
- (long) maxGain;
///	Sets the powerline to the passed value
- (void) setPowerLine:(long)n;
///	Gets the powerline value currently being used by the camera
- (long) powerLine;
///	Whether or not this camera supports the powerline parameter
- (BOOL) powerLineSupported;
///	Resets the powerline value to the hardware-defined default
- (void) resetPowerLine;
///	The min powerline value
- (long) minPowerLine;
///	The max powerline value
- (long) maxPowerLine;
///	Sets the auto hue to the passed value
- (void) setAutoHue:(BOOL)n;
///	The auto hue value currently being used by the camera
- (BOOL) autoHue;
///	Whether or not this camera supports the auto hue parameter
- (BOOL) autoHueSupported;
///	Resets the auto hue parameter to the hardware-defined default
- (void) resetAutoHue;
///	Sets the hue to the passed value
- (void) setHue:(long)n;
///	Gets the hue value currently being used by the camera
- (long) hue;
///	Whether or not this camera supports the hue parameter
- (BOOL) hueSupported;
///	Resets the hue parameter to the hardware-defined default
- (void) resetHue;
///	The min hue value
- (long) minHue;
///	The max hue value
- (long) maxHue;
///	Sets the saturation to the passed value
- (void) setSaturation:(long)n;
///	Gets the saturation value currently being used by the camera
- (long) saturation;
///	Whether or not this camera supports the saturation parameter
- (BOOL) saturationSupported;
///	Resets the saturation to the hardware-defined default
- (void) resetSaturation;
///	The min saturation value
- (long) minSaturation;
///	The max saturation value
- (long) maxSaturation;
///	Sets the sharpness to the passed value
- (void) setSharpness:(long)n;
///	Gets the sharpness value currently being used by the camera
- (long) sharpness;
///	Whether or not this camera supports the sharpness parameter
- (BOOL) sharpnessSupported;
///	Resets the sharpness to the hardware-defined default
- (void) resetSharpness;
///	The min sharpness value
- (long) minSharpness;
///	The max sharpness value
- (long) maxSharpness;
///	Sets the gamma to the passed value
- (void) setGamma:(long)n;
///	Gets the gamma value currently being used by the camera
- (long) gamma;
///	Whether or not this camera supports the gamma parameter
- (BOOL) gammaSupported;
///	Resets the gamma value to the hardware-defined default
- (void) resetGamma;
///	The min gamma value
- (long) minGamma;
///	The max gamma value
- (long) maxGamma;
///	Sets the auto white balance to the passed value
- (void) setAutoWhiteBalance:(BOOL)n;
///	Gets the auto white balance value currently being used by the camera
- (BOOL) autoWhiteBalance;
///	Whether or not this camera supports the auto white balance parameter
- (BOOL) autoWhiteBalanceSupported;
///	Resets the auto white balance to the hardware-defined default
- (void) resetAutoWhiteBalance;
///	Sets the white balance to the passed value
- (void) setWhiteBalance:(long)n;
///	Gets the white balance value currently being used by the camera
- (long) whiteBalance;
///	Whether or not this camera supports the white balance parameter
- (BOOL) whiteBalanceSupported;
///	Resets the white balance value to the hardware-defined default
- (void) resetWhiteBalance;
///	The min white balance value
- (long) minWhiteBalance;
///	The max white balance value
- (long) maxWhiteBalance;
- (BOOL) panTilt:(UVC_PAN_TILT_DIRECTION)direction;
- (NSString *)getExtensionVersion;
- (BOOL)setUpdateMode;
- (BOOL)resetPanTilt;
- (BOOL) setRelativeZoomControl:(UInt8)bZoom;

- (long)absPan;
- (BOOL)setAbsPan:(long)pan;
- (long)absTilt;
- (BOOL)setAbsTilt:(long)tilt;
- (void) setRoll:(long)n;
- (long) roll;
- (BOOL) rollSupported;

// flip
- (NSUInteger)getFlipValue;
- (BOOL)setUVCExtensionSettingValue:(UVCExtensionSettingValue)value;

// image ctrl
- (void)populateImageCtrlParams;
- (void)rollbackImageCtrlParams;
- (void)saveImageCtrlParamToCache;
- (void)resetDefaultImageCtrlParams;
- (BOOL)isAutoWhiteBalance;

// camera ctrl
- (void)populateCameraCtrlParams;
- (void)rollbackCameraCtrlParams;
- (void)saveCameraCtrlParamToCache;
- (void)resetDefaultCameraCtrlParams;
- (BOOL)isExposureAutoMode;
@end
