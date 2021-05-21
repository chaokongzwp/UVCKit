#import "AVCaptureVideoSource.h"




CVOpenGLTextureCacheRef		_textureCache = nil;



@implementation UVCCaptureDeviceFormat
- (NSString *)formatDesc{
	return [NSString stringWithFormat:@"%d * %d", self.width, self.height];
}
@end


@interface AVCaptureVideoSource()
@property (nonatomic, strong) NSMutableDictionary<UVCCaptureDeviceFormat *, AVCaptureDeviceFormat
*> *formatMap;
@end


@implementation AVCaptureVideoSource


- (id) init	{
	if (self = [super init])	{
		propLock = OS_SPINLOCK_INIT;
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
	
	OSSpinLockLock(&propLock);
	if (propTexture != nil)	{
		CVOpenGLTextureRelease(propTexture);
		propTexture = nil;
	}
	OSSpinLockUnlock(&propLock);
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
	
	for (AVCaptureDeviceFormat *format in propDevice.formats){
		FourCharCode codeType=CMFormatDescriptionGetMediaSubType(format.formatDescription);
		NSString *codeTypeStr = [[NSString alloc] initWithUTF8String:FourCC2Str(codeType)];
//		[types addObject:codeTypeStr];
		
		NSMutableArray *dimensionList = types[codeTypeStr];
		if (dimensionList == nil) {
			dimensionList = [NSMutableArray array];
			types[codeTypeStr] = dimensionList;
		}
		
		UVCCaptureDeviceFormat *uvcFormat = [UVCCaptureDeviceFormat new];
		
		
		CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
		NSLog(@"%u %u", dimensions.height, dimensions.width);
		
		uvcFormat.height = dimensions.height;
		uvcFormat.width = dimensions.width;
		
		[dimensionList addObject:uvcFormat];
	}
	
	return types;
}

- (void)updateDeviceFormat:(UVCCaptureDeviceFormat *)uvcFormat{
	
}



- (void) loadDeviceWithUniqueID:(NSString *)n	{
	if ([self running])
		[self stop];
	if (n==nil)
		return;
	BOOL				bail = NO;
	NSError				*err = nil;
	OSSpinLockLock(&propLock);
	AVCaptureDevice		*propDevice = [AVCaptureDevice deviceWithUniqueID:n];
	
	NSLog(@"formats %@", propDevice.formats);

	for (AVCaptureDeviceFormat *format in propDevice.formats){
//		NSLog(@"%d %d", format.highResolutionStillImageDimensions.height, format.highResolutionStillImageDimensions.width);
		NSLog(@"%@", format.mediaType);
		NSLog(@"%@", format.formatDescription);
//		id fd = format.formatDescription;
		FourCharCode codeType=CMFormatDescriptionGetMediaSubType(format.formatDescription);
		
		NSString *codeTypeStr = [[NSString alloc] initWithUTF8String:FourCC2Str(codeType)];
		NSLog(@"%@", codeTypeStr);
		CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
		NSLog(@"%u %u", dimensions.height, dimensions.width);
		CFDictionaryRef dic = CMFormatDescriptionGetExtensions(format.formatDescription);
		NSLog(@"%@", dic);
		NSString *desc = format.description;
		NSLog(@"%@", desc);
	}
	
	
	propDeviceInput = (propDevice==nil) ? nil : [[AVCaptureDeviceInput alloc] initWithDevice:propDevice error:&err];
	if (propDeviceInput != nil)	{
		propSession = [[AVCaptureSession alloc] init];
		propOutput = [[AVCaptureVideoDataOutput alloc] init];
		
		NSLog(@"availableVideoCodecTypes %@", propOutput.availableVideoCodecTypes);
		NSLog(@"availableVideoCVPixelFormatTypes %@", propOutput.availableVideoCVPixelFormatTypes);
		
		
		if (![propSession canAddInput:propDeviceInput])	{
			NSLog(@"\t\tproblem adding propDeviceInput in %s",__func__);
			bail = YES;
		}
		if (![propSession canAddOutput:propOutput])	{
			NSLog(@"\t\tproblem adding propOutput in %s",__func__);
			bail = YES;
		}
		
		if (!bail)	{
			propQueue = dispatch_queue_create([[[NSBundle mainBundle] bundleIdentifier] UTF8String], NULL);
			[propOutput setSampleBufferDelegate:self queue:propQueue];
			
			[propSession addInput:propDeviceInput];
			[propSession addOutput:propOutput];
			[propSession startRunning];
		}
	}
	else
		bail = YES;
	OSSpinLockUnlock(&propLock);
	
	if (bail)
		[self stop];
	else
		[self start];
}


- (void) start	{
	//NSLog(@"%s ... %@",__func__,self);
	OSSpinLockLock(&propLock);
	if (!propRunning)	{
		[self _start];
		propRunning = YES;
	}
	else
		NSLog(@"\t\tERR: starting something that wasn't stopped, %s",__func__);
	OSSpinLockUnlock(&propLock);
}
- (void) stop	{
	//NSLog(@"%s ... %@",__func__,self);
	OSSpinLockLock(&propLock);
	if (propRunning)	{
		[self _stop];
		propRunning = NO;
	}
	else
		NSLog(@"\t\tERR: stopping something that wasn't running, %s",__func__);
	OSSpinLockUnlock(&propLock);
}


/*===================================================================================*/
#pragma mark --------------------- backend
/*------------------------------------*/


- (void) _start	{

}
- (void) _stop	{
	if (propSession != nil)	{
		[propSession stopRunning];
		if (propDeviceInput != nil)
			[propSession removeInput:propDeviceInput];
		if (propOutput != nil)
			[propSession removeOutput:propOutput];
		
//		dispatch_release(propQueue);
		propQueue = NULL;
		
//		[propDeviceInput release];
		propDeviceInput = nil;
//		[propOutput release];
		propOutput = nil;
//		[propSession release];
		propSession = nil;
	}
}


/*===================================================================================*/
#pragma mark --------------------- AVCaptureVideoDataOutputSampleBufferDelegate protocol (and AVCaptureFileOutputDelegate, too- some protocols share these methods)
/*------------------------------------*/


- (void)captureOutput:(AVCaptureOutput *)o didDropSampleBuffer:(CMSampleBufferRef)b fromConnection:(AVCaptureConnection *)c	{
	NSLog(@"%s",__func__);
}
- (void)captureOutput:(AVCaptureOutput *)o didOutputSampleBuffer:(CMSampleBufferRef)b fromConnection:(AVCaptureConnection *)c	{
	//NSLog(@"%s",__func__);
	/*
	CMFormatDescriptionRef		portFormatDesc = CMSampleBufferGetFormatDescription(b);
	NSLog(@"\t\t\tCMMediaType is %ld, video is %ld",CMFormatDescriptionGetMediaType(portFormatDesc),kCMMediaType_Video);
	NSLog(@"\t\t\tthe FourCharCode for the media subtype is %ld",CMFormatDescriptionGetMediaSubType(portFormatDesc));
	CMVideoDimensions		vidDims = CMVideoFormatDescriptionGetDimensions(portFormatDesc);
	NSLog(@"\t\t\tport size is %d x %d",vidDims.width,vidDims.height);
	*/
	
	
	//	if this came from a connection belonging to the data output
	//VVBuffer				*newBuffer = nil;
	//CMBlockBufferRef		blockBufferRef = CMSampleBufferGetDataBuffer(b)
	CVImageBufferRef		imgBufferRef = CMSampleBufferGetImageBuffer(b);
	if (imgBufferRef != NULL)	{
		//CGSize		imgBufferSize = CVImageBufferGetDisplaySize(imgBufferRef);
		//NSSizeLog(@"\t\timg buffer size is",imgBufferSize);
		CVOpenGLTextureRef		cvTexRef = NULL;
		CVReturn				err = kCVReturnSuccess;
		
		
		err = CVOpenGLTextureCacheCreateTextureFromImage(NULL,_textureCache,imgBufferRef,NULL,&cvTexRef);
		if (err != kCVReturnSuccess)	{
			NSLog(@"\t\terr %d at CVOpenGLTextureCacheCreateTextureFromImage() in %s",err,__func__);
		}
		else	{
			OSSpinLockLock(&propLock);
			if (propTexture != nil)	{
				CVOpenGLTextureRelease(propTexture);
				propTexture = nil;
			}
			propTexture = cvTexRef;
			//CVOpenGLTextureRelease(cvTexRef);
			OSSpinLockUnlock(&propLock);
		}
	}
	CVOpenGLTextureCacheFlush(_textureCache,0);
	
	
}


/*===================================================================================*/
#pragma mark --------------------- key-val-ish
/*------------------------------------*/


- (BOOL) running	{
	BOOL		returnMe;
	OSSpinLockLock(&propLock);
	returnMe = propRunning;
	OSSpinLockUnlock(&propLock);
	return returnMe;
}
- (void) setDelegate:(id<AVCaptureVideoSourceDelegate>)n	{
	OSSpinLockLock(&propLock);
	propDelegate = n;
	OSSpinLockUnlock(&propLock);
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
//		[newItem release];
	}
	return returnMe;
}
- (CVOpenGLTextureRef) safelyGetRetainedTextureRef	{
	CVOpenGLTextureRef		returnMe = NULL;
	OSSpinLockLock(&propLock);
	if (propTexture != nil)	{
		returnMe = propTexture;
		CVOpenGLTextureRetain(returnMe);
	}
	OSSpinLockUnlock(&propLock);
	return returnMe;
}


@end
