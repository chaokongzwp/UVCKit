//
//  UVCButton.h
//  UVC Test App
//
//  Created by 朝空 on 2021/5/11.
//  Copyright © 2021 Chingan. All rights reserved.
//

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
