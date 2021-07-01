//
//  UVCControllerUIBox.h
//  UVCKit
//
//  Created by 朝空 on 2021/6/29.
//  Copyright © 2021 Vidvox. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol UVCControllerUIBoxDelegate
- (void) controlChanged:(id)sender;
@end

@interface UVCControllerUIBox : NSBox {
	BOOL			enabled;
	NSSlider		*valSlider;
	NSTextField		*valLabel;
	NSTextField     *titleField;
	NSButton        *checkBoxButton;
	
	int				val;
	int				min;
	int				max;
}



@property (assign,readwrite) id<UVCControllerUIBoxDelegate> delegate;
@property (assign,readwrite) int val;
@property (assign,readwrite) int min;
@property (assign,readwrite) int max;

- (void)setTitle:(NSString *)title;
- (void) setEnabled:(BOOL)n;
- (void) _resizeContents;
- (void) uiItemUsed:(id)sender;
@end

NS_ASSUME_NONNULL_END
