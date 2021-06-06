#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>




extern CVOpenGLTextureCacheRef		_textureCache;




@protocol AVCaptureVideoSourceDelegate
- (void) listOfStaticSourcesUpdated:(id)videoSource;
@end

@interface UVCCaptureDeviceFormat : NSObject
@property (assign, nonatomic) int32_t width;
@property (assign, nonatomic) int32_t height;
@property (copy, nonatomic)  NSString *subMediaType;

- (NSString *)formatDesc;
@end


@interface AVCaptureVideoSource : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>	{
    NSRecursiveLock*							propLock;
	id <AVCaptureVideoSourceDelegate>	propDelegate;
	BOOL								propRunning;
	
	AVCaptureDeviceInput				*propDeviceInput;
	AVCaptureSession					*propSession;
	AVCaptureVideoDataOutput			*propOutput;
	dispatch_queue_t					propQueue;
	CVOpenGLTextureRef					propTexture;
}

- (void) loadDeviceWithUniqueID:(NSString *)n;
- (NSString *)currentDeivceId;
- (void) stop;
- (void) _stop;

- (BOOL) running;
- (void) setDelegate:(id<AVCaptureVideoSourceDelegate>)n;
- (NSArray *) arrayOfSourceMenuItems;

- (CVOpenGLTextureRef) safelyGetRetainedTextureRef;

- (NSDictionary<NSString *, NSArray<UVCCaptureDeviceFormat *> *> *)getMediaSubTypes;
- (void)updateDeviceFormat:(UVCCaptureDeviceFormat *)uvcFormat;
- (UVCCaptureDeviceFormat *)activeFormatInfo;

- (void)setPreviewLayer:(NSView *)view;
@end
