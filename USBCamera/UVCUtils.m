//
//  UVCUtils.m
//  UVC Test App
//
//  Created by 张伟平 on 2021/6/6.
//  Copyright © 2021 Chingan. All rights reserved.
//

#import "UVCUtils.h"

static NSDateFormatter *dateFormatter = nil;

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

+ (NSString *)currentTime{
	//获取系统当前时间
	NSDate *currentDate = [NSDate date];
	//用于格式化NSDate对象
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFormatter = [[NSDateFormatter alloc] init];
		//设置格式：zzz表示时区
		[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss SSS"];
	});
	
	//NSDate转NSString
	NSString *currentDateString = [dateFormatter stringFromDate:currentDate];
	//输出currentDateString
	NSLog(@"%@",currentDateString);
	
	return currentDateString;
}

+ (NSString *)logFilePath{
	static NSString *path = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		path = [NSString stringWithFormat:@"%@/uvclog.txt", [[NSFileManager defaultManager] homeDirectoryForCurrentUser].path];
		NSLog(@"logFilePath %@",path);
	});
	
	return path;
}



+ (void)logFile:(char *)sourceFile lineNumber:(int)lineNumber format:(NSString*)format, ...{
	va_list ap;
	va_start(ap, format);
	NSString *file = [[NSString alloc] initWithBytes:sourceFile length:strlen(sourceFile) encoding:NSUTF8StringEncoding];
	NSString *print = [[NSString alloc] initWithFormat:format arguments:ap];
	va_end(ap);
	// NSLog handles synchronization issues

	NSString *log = [NSString stringWithFormat:@"[%@] %s:%d %@",  [self currentTime], [[file lastPathComponent] UTF8String], lineNumber, print];
	NSLog(@"%s:%d %@", [[file lastPathComponent] UTF8String], lineNumber, print);
	
	NSMutableData *writer = [[NSMutableData alloc] init];

	[writer appendData:[log dataUsingEncoding:NSUTF8StringEncoding]];
	[writer writeToFile:[self logFilePath] atomically:YES];
}

@end
