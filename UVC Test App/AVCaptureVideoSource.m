#import "AVCaptureVideoSource.h"
#import "UVCUtils.h"



CVOpenGLTextureCacheRef		_textureCache = nil;



@implementation UVCCaptureDeviceFormat
- (NSString *)formatDesc{
	return [NSString stringWithFormat:@"%d * %d", self.width, self.height];
}

- (NSString *)alias{
	if ([self.subMediaType isEqualTo:@"yuvs"]) {
		return @"YUY2";
	}
	
	if ([self.subMediaType isEqualTo:@"dmb1"]) {
		return @"MJPG";
	}
	
	
	return _subMediaType;
}
@end


@interface AVCaptureVideoSource()
@property (nonatomic, strong) NSMutableDictionary<UVCCaptureDeviceFormat *, AVCaptureDeviceFormat
*> *formatMap;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preLayer;
@end


@implementation AVCaptureVideoSource


- (id) init	{
	if (self = [super init])	{
		propLock = [NSRecursiveLock new];
		propDelegate = nil;
		propRunning = NO;
		propDeviceInput = nil;
		propSession = nil;
		propOutput = nil;
		propQueue = nil;
		propTexture = nil;
		self.formatMap = [NSMutableDictionary dictionary];
		return self;
	}
//	[self release];
	return nil;
}
- (void) dealloc	{
	[self stop];
	
    [propLock lock];
	if (propTexture != nil)	{
		CVOpenGLTextureRelease(propTexture);
		propTexture = nil;
	}
    [propLock unlock];
//	[super dealloc];
}


/*===================================================================================*/
#pragma mark --------------------- control messages
/*------------------------------------*/
#define FourCC2Str(fourcc) (const char[]){*(((char*)&fourcc)+3), *(((char*)&fourcc)+2), *(((char*)&fourcc)+1), *(((char*)&fourcc)+0),0}

- (NSDictionary<NSString *, NSArray<UVCCaptureDeviceFormat *> *> *)getMediaSubTypes {
	if (propDeviceInput == nil){
		return nil;
	}
	
	AVCaptureDevice		*propDevice = propDeviceInput.device;
	NSMutableDictionary<NSString *, NSMutableArray *> *types = [NSMutableDictionary dictionary];
	NSXLog(@"[%@] Media Sub Types:", [propDevice localizedName]);
	for (AVCaptureDeviceFormat *format in propDevice.formats){
		FourCharCode codeType=CMFormatDescriptionGetMediaSubType(format.formatDescription);
		NSString *codeTypeStr = [[NSString alloc] initWithUTF8String:FourCC2Str(codeType)];
		if ([codeTypeStr isEqualToString:@"420v"]){
			continue;
		}
		
		UVCCaptureDeviceFormat *uvcFormat = [UVCCaptureDeviceFormat new];
		uvcFormat.subMediaType = codeTypeStr;
		CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
		NSXLog(@"%@ %u*%u", codeTypeStr, dimensions.width, dimensions.height);
		uvcFormat.height = dimensions.height;
		uvcFormat.width = dimensions.width;
		
		NSMutableArray *dimensionList = types[uvcFormat.alias];
		if (dimensionList == nil) {
			dimensionList = [NSMutableArray array];
			types[uvcFormat.alias] = dimensionList;
		}
		
		[dimensionList addObject:uvcFormat];
	}
	
	return types;
}

- (UVCCaptureDeviceFormat *)activeFormatInfo{
	if (propDeviceInput == nil) {
		return nil;
	}
	
	AVCaptureDeviceFormat *format = propDeviceInput.device.activeFormat;
	FourCharCode codeType=CMFormatDescriptionGetMediaSubType(format.formatDescription);
	NSString *codeTypeStr = [[NSString alloc] initWithUTF8String:FourCC2Str(codeType)];
	UVCCaptureDeviceFormat *uvcFormat = [UVCCaptureDeviceFormat new];
	uvcFormat.subMediaType = codeTypeStr;
	
	CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
	NSXLog(@"%u %u", dimensions.height, dimensions.width);
	
	uvcFormat.height = dimensions.height;
	uvcFormat.width = dimensions.width;
	
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
				[propDevice lockForConfiguration:&err];
				[propDevice setActiveFormat:format];
				[propDevice unlockForConfiguration];
				
				NSMutableDictionary *videoSettings = [NSMutableDictionary new];
				[videoSettings setValue:@(codeType) forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
				[videoSettings setValue:@(uvcFormat.width) forKey:(NSString *)kCVPixelBufferWidthKey];
				[videoSettings setValue:@(uvcFormat.height) forKey:(NSString *)kCVPixelBufferHeightKey];
			
				propDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:propDevice error:&err];
				
				if (propDeviceInput != nil)	{
					propSession = [[AVCaptureSession alloc] init];
					propOutput = [[AVCaptureVideoDataOutput alloc] init];
					if (![propSession canAddInput:propDeviceInput])	{
						NSXLog(@"\t\tproblem adding propDeviceInput in %s",__func__);
						bail = YES;
					}
					if (![propSession canAddOutput:propOutput])	{
						NSXLog(@"\t\tproblem adding propOutput in %s",__func__);
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

- (AVCaptureDeviceFormat *)setFormat:(UVCCaptureDeviceFormat *)uvcFormat device:(AVCaptureDevice *)propDevice{
	__block AVCaptureDeviceFormat *format = nil;
	if (uvcFormat){
		[propDevice.formats enumerateObjectsUsingBlock:^(AVCaptureDeviceFormat * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			FourCharCode codeType=CMFormatDescriptionGetMediaSubType(obj.formatDescription);
			NSString *codeTypeStr = [[NSString alloc] initWithUTF8String:FourCC2Str(codeType)];
			CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(obj.formatDescription);
			
			if ([codeTypeStr isEqualToString:uvcFormat.subMediaType]
				&& dimensions.height == uvcFormat.height
				&& dimensions.width == uvcFormat.width) {
				NSError	*err = nil;
				[propDevice lockForConfiguration:&err];
				[propDevice setActiveFormat:obj];
				[propDevice unlockForConfiguration];
				if (err) {
					NSXLog(@"setFormat %@ uvcFormat %@ %@", err, uvcFormat.alias, uvcFormat.formatDesc);
				}
				
				format = obj;
				return;
			}
		}];
	}

	
	NSError	*err = nil;
	FourCharCode codeType=CMFormatDescriptionGetMediaSubType(propDevice.activeFormat.formatDescription);
	if (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == codeType) {
		
		[propDevice.formats enumerateObjectsUsingBlock:^(AVCaptureDeviceFormat * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			FourCharCode codeType=CMFormatDescriptionGetMediaSubType(propDevice.activeFormat.formatDescription);
			if (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange != codeType) {
				format = obj;
			}
		}];
		
		if (format) {
			[propDevice lockForConfiguration:&err];
			[propDevice setActiveFormat:format];
			[propDevice unlockForConfiguration];
		}
	}
	
	return format;
}

- (void) loadDeviceWithUniqueID:(NSString *)n format:(UVCCaptureDeviceFormat *)uvcFormat{
	if ([self running]){
		[self stop];
	}
		
	if (n==nil) {
		return;
	}
	
	BOOL				bail = NO;
	NSError				*err = nil;
    [propLock lock];
	AVCaptureDevice		*propDevice = [AVCaptureDevice deviceWithUniqueID:n];
	NSXLog(@"formats %@", propDevice.activeFormat);
	
	propDeviceInput = (propDevice==nil) ? nil : [[AVCaptureDeviceInput alloc] initWithDevice:propDevice error:&err];
	if (propDeviceInput != nil)	{
		propSession = [[AVCaptureSession alloc] init];
		propOutput = [[AVCaptureVideoDataOutput alloc] init];
		
		if (![propSession canAddInput:propDeviceInput])	{
			NSXLog(@"\t\tproblem adding propDeviceInput in %s",__func__);
			bail = YES;
		}
		if (![propSession canAddOutput:propOutput])	{
			NSXLog(@"\t\tproblem adding propOutput in %s",__func__);
			bail = YES;
		}
		
		if (!bail)	{
//			propQueue = dispatch_queue_create([[[NSBundle mainBundle] bundleIdentifier] UTF8String], NULL);
//			[propOutput setSampleBufferDelegate:self queue:propQueue];
			[self setFormat:uvcFormat device:propDevice];
			NSXLog(@"formatDescription %@", propDevice.activeFormat.formatDescription);
			FourCharCode codeType=CMFormatDescriptionGetMediaSubType(propDevice.activeFormat.formatDescription);
			CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(propDevice.activeFormat.formatDescription);
			
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
	if (!propRunning)	{
		[self _start];
		propRunning = YES;
	}
    else{
		NSXLog(@"\t\tERR: starting something that wasn't stopped, %s",__func__);
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
		NSXLog(@"\t\tERR: stopping something that wasn't running, %s",__func__);
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
}


/*===================================================================================*/
#pragma mark --------------------- AVCaptureVideoDataOutputSampleBufferDelegate protocol (and AVCaptureFileOutputDelegate, too- some protocols share these methods)
/*------------------------------------*/
- (void)captureOutput:(AVCaptureOutput *)o didDropSampleBuffer:(CMSampleBufferRef)b fromConnection:(AVCaptureConnection *)c	{
	NSXLog(@"");
}

- (void)captureOutput:(AVCaptureOutput *)o didOutputSampleBuffer:(CMSampleBufferRef)b fromConnection:(AVCaptureConnection *)c	{
	//NSXLog(@"%s",__func__);
	CMFormatDescriptionRef		portFormatDesc = CMSampleBufferGetFormatDescription(b);
	FourCharCode code= CMFormatDescriptionGetMediaSubType(portFormatDesc);
	NSXLog(@"media subtype is %s",FourCC2Str(code));
	CMVideoDimensions		vidDims = CMVideoFormatDescriptionGetDimensions(portFormatDesc);
	NSXLog(@"size is %d x %d",vidDims.width,vidDims.height);
	
	//	if this came from a connection belonging to the data output
	//VVBuffer				*newBuffer = nil;
	CMBlockBufferRef		blockBufferRef = CMSampleBufferGetDataBuffer(b);
	if (blockBufferRef) {
		
	}
	
	CVImageBufferRef		imgBufferRef = CMSampleBufferGetImageBuffer(b);
	if (imgBufferRef != NULL)	{
		CGSize		imgBufferSize = CVImageBufferGetDisplaySize(imgBufferRef);
		NSXLog(@"img buffer size is %f %f",imgBufferSize.height, imgBufferSize.width);
//		CVOpenGLTextureRef		cvTexRef = NULL;
//		CVReturn				err = kCVReturnSuccess;
//
//
//		err = CVOpenGLTextureCacheCreateTextureFromImage(NULL,_textureCache,imgBufferRef,NULL,&cvTexRef);
//		if (err != kCVReturnSuccess)	{
//			NSXLog(@"\t\terr %d at CVOpenGLTextureCacheCreateTextureFromImage() in %s",err,__func__);
//		}
//		else	{
//            [propLock lock];
//			if (propTexture != nil)	{
//				CVOpenGLTextureRelease(propTexture);
//				propTexture = nil;
//			}
//			propTexture = cvTexRef;
//			//CVOpenGLTextureRelease(cvTexRef);
//            [propLock unlock];
//		}
	}
//	CVOpenGLTextureCacheFlush(_textureCache,0);
}


/*===================================================================================*/
#pragma mark --------------------- key-val-ish
/*------------------------------------*/


- (BOOL) running	{
	BOOL		returnMe;
    [propLock lock];
	returnMe = propRunning;
    [propLock unlock];
	return returnMe;
}

- (void) setDelegate:(id<AVCaptureVideoSourceDelegate>)n	{
    [propLock lock];
	propDelegate = n;
    [propLock unlock];
}

- (NSArray *) arrayOfSourceMenuItems	{
	NSArray		*devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	if (devices==nil || [devices count]<1)
		return nil;
	NSMutableArray		*returnMe = [NSMutableArray arrayWithCapacity:0];
	for (AVCaptureDevice *devicePtr in devices)	{
		NSMenuItem		*newItem = [[NSMenuItem alloc] initWithTitle:[devicePtr localizedName] action:nil keyEquivalent:@""];
		NSString		*uniqueID = [devicePtr uniqueID];
		[newItem setRepresentedObject:uniqueID];
		[returnMe addObject:newItem];
	}
	return returnMe;
}

- (CVOpenGLTextureRef) safelyGetRetainedTextureRef	{
	CVOpenGLTextureRef		returnMe = NULL;
    [propLock lock];
	if (propTexture != nil)	{
		returnMe = propTexture;
		CVOpenGLTextureRetain(returnMe);
	}
    [propLock unlock];
	return returnMe;
}
@end
