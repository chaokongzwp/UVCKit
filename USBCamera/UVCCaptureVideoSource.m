#import "UVCCaptureVideoSource.h"
#import "UVCUtils.h"



@implementation UVCCaptureDeviceFormat
- (NSString *)formatDesc{
	return [NSString stringWithFormat:@"%d * %d", self.width, self.height];
}

- (NSString *)alias{
	return self.videoName;
}
@end


@interface UVCCaptureVideoSource()
@property (nonatomic, strong) NSMutableDictionary<UVCCaptureDeviceFormat *, AVCaptureDeviceFormat*> *formatMap;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preLayer;
@property (nonatomic, strong) AVCaptureDeviceFormat *currentFormat;
@end


@implementation UVCCaptureVideoSource
- (id) init	{
	if (self = [super init])	{
		propLock = [NSRecursiveLock new];
		propRunning = NO;
		propDeviceInput = nil;
		propSession = nil;
		propOutput = nil;
		propQueue = nil;
		self.formatMap = [NSMutableDictionary dictionary];
		return self;
	}

	return nil;
}

- (void) dealloc	{
	[self stop];
}

/*===================================================================================*/
#pragma mark --------------------- control messages
/*------------------------------------*/
#define FourCC2Str(fourcc) (const char[]){*(((char*)&fourcc)+3), *(((char*)&fourcc)+2), *(((char*)&fourcc)+1), *(((char*)&fourcc)+0),0}
- (NSDictionary<NSString *, NSArray<UVCCaptureDeviceFormat *> *> *)getMediaSubTypes {
	if (propDeviceInput == nil){
		return nil;
	}
    
    UVCCaptureDeviceFormat *current = [self activeFormatInfo];
	
	AVCaptureDevice		*propDevice = propDeviceInput.device;
	NSMutableDictionary<NSString *, NSMutableArray *> *types = [NSMutableDictionary dictionary];
    NSMutableArray *dimensionList = [NSMutableArray array];
	NSXLog(@"[%@] Media Sub Types:", [propDevice localizedName]);
	for (AVCaptureDeviceFormat *format in propDevice.formats){
		FourCharCode codeType=CMFormatDescriptionGetMediaSubType(format.formatDescription);
		NSString *codeTypeStr = [[NSString alloc] initWithUTF8String:FourCC2Str(codeType)];
        if (![codeTypeStr isEqualToString:current.subMediaType]) {
            continue;
        }
        
		UVCCaptureDeviceFormat *uvcFormat = [UVCCaptureDeviceFormat new];
		uvcFormat.subMediaType = codeTypeStr;
		CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
		NSXLog(@"%@ %u*%u", codeTypeStr, dimensions.width, dimensions.height);
		uvcFormat.height = dimensions.height;
		uvcFormat.width = dimensions.width;
		[dimensionList addObject:uvcFormat];
	}
    
    for (NSString *videoName in self.videoName) {
        for (UVCCaptureDeviceFormat *format in dimensionList){
            format.videoName = videoName;
        }
        [types setValue:dimensionList forKey:videoName];
    }
    
    if (types.count == 0) {
        [types setValue:dimensionList forKey:@"YUV2"];
    }
    
    if (current.videoName == nil) {
        current.videoName = self.videoName.firstObject?:@"YUV2";
        
    }
	
	return types;
}

- (UVCCaptureDeviceFormat *)activeFormatInfo{
	if (propDeviceInput == nil) {
		return nil;
	}
	
	AVCaptureDeviceFormat *format = self.currentFormat;
	FourCharCode codeType=CMFormatDescriptionGetMediaSubType(format.formatDescription);
	NSString *codeTypeStr = [[NSString alloc] initWithUTF8String:FourCC2Str(codeType)];
	UVCCaptureDeviceFormat *uvcFormat = [UVCCaptureDeviceFormat new];
	uvcFormat.subMediaType = codeTypeStr;
	
	CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
	NSXLog(@"activeFormatInfo %@ %u %u",codeTypeStr, dimensions.height, dimensions.width);
	
	uvcFormat.height = dimensions.height;
	uvcFormat.width = dimensions.width;
	
    if (self.videoName.count == 0) {
        uvcFormat.videoName = @"YUV2";
    } else {
        uvcFormat.videoName = self.videoName.firstObject;
    }
    
	return uvcFormat;
}

- (void)updateDeviceFormat:(UVCCaptureDeviceFormat *)uvcFormat{
	if (propDeviceInput == nil){
		return;
	}
	
	NSXLog(@"updateDeviceFormat %@ %@", uvcFormat.subMediaType, uvcFormat.formatDesc);
	AVCaptureDevice		*propDevice = propDeviceInput.device;
	for (AVCaptureDeviceFormat *format in propDevice.formats) {
		FourCharCode codeType=CMFormatDescriptionGetMediaSubType(format.formatDescription);
		NSString *codeTypeStr = [[NSString alloc] initWithUTF8String:FourCC2Str(codeType)];
		NSXLog(@"%@", codeTypeStr);
		if ([uvcFormat.subMediaType isEqualToString:codeTypeStr]) {
			CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
			NSXLog(@"%u %u", dimensions.height, dimensions.width);
			
			if (uvcFormat.height == dimensions.height && uvcFormat.width == dimensions.width) {
				if ([self running])
					[self stop];
				BOOL				bail = NO;
				NSError				*err = nil;
                [propLock lock];
				NSXLog(@"formats %@", propDevice.formats);
				NSMutableDictionary *videoSettings = [NSMutableDictionary new];
				[videoSettings setValue:@(codeType) forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
				[videoSettings setValue:@(uvcFormat.width) forKey:(NSString *)kCVPixelBufferWidthKey];
				[videoSettings setValue:@(uvcFormat.height) forKey:(NSString *)kCVPixelBufferHeightKey];
			
				propDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:propDevice error:&err];
				
				if (propDeviceInput != nil)	{
					propSession = [[AVCaptureSession alloc] init];
					propOutput = [[AVCaptureVideoDataOutput alloc] init];
					if (![propSession canAddInput:propDeviceInput])	{
						NSXLog(@"problem adding propDeviceInput");
						bail = YES;
					}
					if (![propSession canAddOutput:propOutput])	{
						NSXLog(@"problem adding propOutput");
						bail = YES;
					}
					
					if (!bail)	{
//                        propQueue = dispatch_queue_create([[[NSBundle mainBundle] bundleIdentifier] UTF8String], NULL);
//                        [propOutput setSampleBufferDelegate:self queue:propQueue];
						propOutput.videoSettings = videoSettings;
						[propSession addInput:propDeviceInput];
						[propSession addOutput:propOutput];
						[propSession startRunning];
					}
				}
                else{
                    bail = YES;
                }
                [propLock unlock];
				
                if (bail){
					[self stop];
                } else {
					[self start];
                }
				
				break;
			}
		}
	}
}

- (void)setPreviewLayer:(NSView *)view{
	AVCaptureVideoPreviewLayer *preLayer = [AVCaptureVideoPreviewLayer layerWithSession:propSession];
	preLayer.frame = view.bounds;
	preLayer.videoGravity = AVLayerVideoGravityResizeAspect;
	[view.layer addSublayer:preLayer];
}

- (void)loadDeviceWithUniqueID:(NSString *)n{
	[self loadDeviceWithUniqueID:n format:nil];
}

- (void)setFormat:(UVCCaptureDeviceFormat *)uvcFormat device:(AVCaptureDevice *)propDevice{
	if (uvcFormat){
		[propDevice.formats enumerateObjectsUsingBlock:^(AVCaptureDeviceFormat * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			FourCharCode codeType=CMFormatDescriptionGetMediaSubType(obj.formatDescription);
			NSString *codeTypeStr = [[NSString alloc] initWithUTF8String:FourCC2Str(codeType)];
			CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(obj.formatDescription);
			
			if ([codeTypeStr isEqualToString:uvcFormat.subMediaType]
				&& dimensions.height == uvcFormat.height
				&& dimensions.width == uvcFormat.width) {
				self.currentFormat = obj;
				return;
			}
		}];
	}
}

- (AVCaptureDeviceFormat *)currentFormat{
	if (_currentFormat) {
		return _currentFormat;
	}
	
	_currentFormat = propDeviceInput.device.activeFormat;
	
	return _currentFormat;
}

- (void) loadDeviceWithUniqueID:(NSString *)n format:(UVCCaptureDeviceFormat *)uvcFormat{
	if ([self running]){
		[self stop];
	}
		
	if (n == nil) {
		return;
	}
	
	BOOL				bail = NO;
	NSError				*err = nil;
    [propLock lock];
	AVCaptureDevice		*propDevice = [AVCaptureDevice deviceWithUniqueID:n];
	NSXLog(@"formats %@", propDevice.activeFormat);
	
	propDeviceInput = (propDevice == nil) ? nil : [[AVCaptureDeviceInput alloc] initWithDevice:propDevice error:&err];
	if (propDeviceInput != nil)	{
		propSession = [[AVCaptureSession alloc] init];
		propOutput = [[AVCaptureVideoDataOutput alloc] init];
		
		if (![propSession canAddInput:propDeviceInput])	{
			NSXLog(@"problem adding propDeviceInput");
			bail = YES;
		}
		if (![propSession canAddOutput:propOutput])	{
			NSXLog(@"problem adding propOutput");
			bail = YES;
		}
		
		if (!bail)	{
//			propQueue = dispatch_queue_create([[[NSBundle mainBundle] bundleIdentifier] UTF8String], NULL);
//			[propOutput setSampleBufferDelegate:self queue:propQueue];
			[self setFormat:uvcFormat device:propDevice];
			NSXLog(@"formatDescription %@", propDevice.activeFormat.formatDescription);
			NSXLog(@"self.currentFormat %@", self.currentFormat);
			FourCharCode codeType=CMFormatDescriptionGetMediaSubType(self.currentFormat.formatDescription);
			CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(self.currentFormat.formatDescription);
			
			NSMutableDictionary *videoSettings = [NSMutableDictionary new];
			[videoSettings setValue:@(codeType) forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
			[videoSettings setValue:@(dimensions.width) forKey:(NSString *)kCVPixelBufferWidthKey];
			[videoSettings setValue:@(dimensions.height) forKey:(NSString *)kCVPixelBufferHeightKey];
			propOutput.videoSettings = videoSettings;
			
			[propSession addInput:propDeviceInput];
			[propSession addOutput:propOutput];
			[propSession startRunning];
		}
	} else{
		bail = YES;
    }
    [propLock unlock];
	
	if (bail) {
		[self stop];
	} else {
		[self start];
	}
}

- (NSString *)currentDeivceId{
    return propDeviceInput.device.uniqueID;
}

- (void) start	{
	NSXLog(@"");
    [propLock lock];
	if (!propRunning) {
		[self _start];
		propRunning = YES;
	} else {
		NSXLog(@"ERR: starting something that wasn't stopped");
    }
	
    [propLock unlock];
}

- (void) stop	{
	NSXLog(@"");
    [propLock lock];
	if (propRunning)	{
		[self _stop];
		propRunning = NO;
	} else {
		NSXLog(@"ERR: stopping something that wasn't running");
    }
	
    [propLock unlock];
}


/*===================================================================================*/
#pragma mark --------------------- backend
/*------------------------------------*/
- (void) _start	{
	NSXLog(@"");
}

- (void) _stop	{
	if (propSession != nil)	{
		[propSession stopRunning];
		if (propDeviceInput != nil)
			[propSession removeInput:propDeviceInput];
		if (propOutput != nil)
			[propSession removeOutput:propOutput];
	
		propQueue = NULL;
		propDeviceInput = nil;
		propOutput = nil;
		propSession = nil;
	}
	
	self.currentFormat = nil;
}

/*===================================================================================*/
#pragma mark --------------------- AVCaptureVideoDataOutputSampleBufferDelegate protocol (and AVCaptureFileOutputDelegate, too- some protocols share these methods)
/*------------------------------------*/
- (void)captureOutput:(AVCaptureOutput *)o didDropSampleBuffer:(CMSampleBufferRef)b fromConnection:(AVCaptureConnection *)c	{
	NSXLog(@"");
}

- (void)captureOutput:(AVCaptureOutput *)o didOutputSampleBuffer:(CMSampleBufferRef)b fromConnection:(AVCaptureConnection *)c {
	CMFormatDescriptionRef		portFormatDesc = CMSampleBufferGetFormatDescription(b);
	FourCharCode code= CMFormatDescriptionGetMediaSubType(portFormatDesc);
	NSXLog(@"media subtype is %s",FourCC2Str(code));
	CMVideoDimensions		vidDims = CMVideoFormatDescriptionGetDimensions(portFormatDesc);
	NSXLog(@"size is %d x %d",vidDims.width,vidDims.height);
	
	CMBlockBufferRef		blockBufferRef = CMSampleBufferGetDataBuffer(b);
	if (blockBufferRef) {
		
	}
	
	CVImageBufferRef		imgBufferRef = CMSampleBufferGetImageBuffer(b);
	if (imgBufferRef != NULL)	{
		CGSize		imgBufferSize = CVImageBufferGetDisplaySize(imgBufferRef);
		NSXLog(@"img buffer size is %f %f",imgBufferSize.height, imgBufferSize.width);
	}
}


/*===================================================================================*/
#pragma mark --------------------- key-val-ish
/*------------------------------------*/
- (BOOL) running {
	BOOL		returnMe;
    [propLock lock];
	returnMe = propRunning;
    [propLock unlock];
	return returnMe;
}

- (NSArray *) arrayOfSourceMenuItems {
	NSArray		*devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	if (devices == nil || [devices count] < 1){
		return nil;
	}
	
	NSMutableArray		*returnMe = [NSMutableArray arrayWithCapacity:0];
	for (AVCaptureDevice *devicePtr in devices)	{
		NSMenuItem		*newItem = [[NSMenuItem alloc] initWithTitle:[devicePtr localizedName] action:nil keyEquivalent:@""];
		NSString		*uniqueID = [devicePtr uniqueID];
		[newItem setRepresentedObject:uniqueID];
		[returnMe addObject:newItem];
        NSXLog(@"arrayOfSourceMenuItems %@ %@",[devicePtr localizedName], uniqueID);
	}
	
	return returnMe;
}
@end
