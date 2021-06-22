//
//  UVCUtils.m
//  UVC Test App
//
//  Created by 张伟平 on 2021/6/6.
//  Copyright © 2021 Chingan. All rights reserved.
//

#import "UVCUtils.h"

static NSDateFormatter *dateFormatter = nil;
static dispatch_queue_t propQueue;
static NSMutableArray<NSString *> *cacheLog;
static NSRecursiveLock *logLock;
static NSString *path = nil;

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
	
	return currentDateString;
}

+ (void)openLog{
	NSLog(@"logFilePath %@",[self logPath]);
	propQueue = dispatch_queue_create("UVCUtils_log", NULL);
	logLock = [NSRecursiveLock new];
	cacheLog = [NSMutableArray array];
	[self writeLog];
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self logPath]]) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[fileManager removeItemAtPath:path error:nil];
	}
	
	BOOL ret = [[NSFileManager defaultManager] createFileAtPath:[self logPath] contents:nil attributes:nil];
	if (!ret) {
		NSLog(@"创建log文件失败");
	}

}

+ (NSString *)logPath{
	if (path == nil) {
		path = [NSString stringWithFormat:@"%@/uvclog.txt", [[NSFileManager defaultManager] homeDirectoryForCurrentUser].path];
	}
	
	return path;
}

+ (void)closeLog{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtPath:[self logPath] error:nil];
}

+ (BOOL)isLogOn{
	return [[NSFileManager defaultManager] fileExistsAtPath:[self logPath]];
}

+ (void)writeLog{
	dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1000 * NSEC_PER_MSEC);

	dispatch_after(time, propQueue, ^{
		if (![self isLogOn]) {
			return;
		}
		
		NSFileHandle *fileHandler = [NSFileHandle fileHandleForWritingAtPath:path];
		[fileHandler seekToEndOfFile];
		[logLock lock];
		NSArray *tmp = cacheLog;
		cacheLog = [NSMutableArray array];
		[logLock unlock];
		
		for (NSString *item in tmp) {
			[fileHandler writeData:[item dataUsingEncoding:NSUTF8StringEncoding]];
		}
		
		[fileHandler  closeFile];
		[self writeLog];
	});
}

+ (void)logFile:(char *)sourceFile lineNumber:(int)lineNumber format:(NSString*)format, ...{
	va_list ap;
	va_start(ap, format);
	NSString *file = [[NSString alloc] initWithBytes:sourceFile length:strlen(sourceFile) encoding:NSUTF8StringEncoding];
	NSString *print = [[NSString alloc] initWithFormat:format arguments:ap];
	va_end(ap);
	// NSLog handles synchronization issues
	NSLog(@"%@", print);
	NSString *log = [NSString stringWithFormat:@"[%@] %s:%d %@\n",  [self currentTime], [[file lastPathComponent] UTF8String], lineNumber, print];
//	NSLog(@"%s:%d %@", [[file lastPathComponent] UTF8String], lineNumber, print);
	[logLock lock];
	[cacheLog addObject:log];
	[logLock unlock];
}

@end
