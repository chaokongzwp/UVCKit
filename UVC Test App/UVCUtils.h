//
//  UVCUtils.h
//  UVC Test App
//
//  Created by 张伟平 on 2021/6/6.
//  Copyright © 2021 Chingan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UVCUtils : NSObject
+ (void)showAlert:(NSString *)msg title:(NSString *)title window:(NSWindow *)window completionHandler:(void (^ _Nullable)(void))handler;
@end

NS_ASSUME_NONNULL_END
