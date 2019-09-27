//
//  ESPFBYColorPicker.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/9/23.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 HSB or HSV 颜色拾取
 可根据颜色自动定位
 */
@interface ESPFBYColorPicker : UIControl

@property(nonatomic, readonly) UIColor *selectedColor;

+ (instancetype)colorPickerWithBubbleWidth:(CGFloat)bubbleWidth completion:(void (^)(UIColor *color))complention;

- (void)changeColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
