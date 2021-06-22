#import "UVCButton.h"

@implementation UVCButton
- (void)mouseDown:(NSEvent *)event {
	if ([self.delegate respondsToSelector:@selector(mouseDown:sender:)]){
		[self.delegate mouseDown:event sender:self];
	}
}

- (void)mouseUp:(NSEvent *)event {
	if ([self.delegate respondsToSelector:@selector(mouseUp:sender:)]){
		[self.delegate mouseUp:event sender:self];
	}
}
@end
