#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol UVCMouseDelegate <NSObject>
@optional
- (void)mouseDown:(NSEvent *)event sender:(id)sender;
- (void)mouseUp:(NSEvent *)event sender:(id)sender;
@end

@interface UVCButton : NSButton
@property (weak, nonatomic) id<UVCMouseDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
