#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>



@interface UVCCaptureDeviceFormat : NSObject
@property (assign, nonatomic) NSUInteger index;
@property (assign, nonatomic) int32_t width;
@property (assign, nonatomic) int32_t height;
@property (copy, nonatomic)  NSString *subMediaType;
@property (copy, nonatomic) NSString *videoName;

- (NSString *)alias;
- (NSString *)formatDesc;
@end


@interface UVCCaptureVideoSource : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>	{
    NSRecursiveLock*							propLock;
	BOOL								propRunning;
	AVCaptureDeviceInput				*propDeviceInput;
	AVCaptureSession					*propSession;
	AVCaptureVideoDataOutput			*propOutput;
	dispatch_queue_t					propQueue;
}
@property (nonatomic, copy) NSMutableArray<NSString *> *videoName;
 
- (void) loadDeviceWithUniqueID:(NSString *)n;
- (void) loadDeviceWithUniqueID:(NSString *)n format:(UVCCaptureDeviceFormat *)uvcFormat;
- (NSString *)currentDeivceId;
- (void) stop;
- (void) _stop;
- (BOOL) running;
- (NSArray *) arrayOfSourceMenuItems;
- (NSDictionary<NSString *, NSArray<UVCCaptureDeviceFormat *> *> *)getMediaSubTypes;
- (void)updateDeviceFormat:(UVCCaptureDeviceFormat *)uvcFormat;
- (UVCCaptureDeviceFormat *)activeFormatInfo;
- (void)setPreviewLayer:(NSView *)view;
@end
