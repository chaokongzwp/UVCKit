//
//  UVCUtils.m
//  UVC Test App
//
//  Created by 张伟平 on 2021/6/6.
//  Copyright © 2021 Vidvox. All rights reserved.
//

#import "UVCUtils.h"

@implementation UVCUtils
+ (void)showAlert:(NSString *)msg title:(NSString *)title window:(NSWindow *)window completionHandler:(void (^ _Nullable)(void))handler{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
    
    [alert setInformativeText:msg];
    
    [alert setAlertStyle:NSAlertStyleInformational];
    
    [alert beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
        if (handler) {
            handler();
        }
    }];
}


@end
