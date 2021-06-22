//
//  UVCUtils.h
//  UVC Test App
//
//  Created by 张伟平 on 2021/6/6.
//  Copyright © 2021 Chingan. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NSXLog(string, ...) \
	[UVCUtils logFile:__FILE__ lineNumber:__LINE__ format:(string), ##__VA_ARGS__]

NS_ASSUME_NONNULL_BEGIN

@interface UVCUtils : NSObject
+ (void)showAlert:(NSString *)msg title:(NSString *)title window:(NSWindow *)window completionHandler:(void (^ _Nullable)(void))handler;
+ (void)logFile:(char *)sourceFile lineNumber:(int)lineNumber format:(NSString*)format, ...;
@end

NS_ASSUME_NONNULL_END
