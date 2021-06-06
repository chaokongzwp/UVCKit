#import <Cocoa/Cocoa.h>
#import <OpenGL/CGLMacro.h>




@interface CVGLView : NSOpenGLView	{
	IBOutlet id		appDelegate;
    NSRecursiveLock*    renderLock;
	BOOL			initialized;
}

+ (NSRect) rectThatFitsRect:(NSRect)a inRect:(NSRect)b;
- (void) drawTextureRef:(CVOpenGLTextureRef)n;

@end
