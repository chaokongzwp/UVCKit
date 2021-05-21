//
//  UVCButton.m
//  UVC Test App
//
//  Created by 朝空 on 2021/5/11.
//  Copyright © 2021 Vidvox. All rights reserved.
//

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
