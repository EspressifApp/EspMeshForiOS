//
//  EspCommonUtils.m
//  Esp32Mesh
//
//  Created by AE on 2018/2/28.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspCommonUtils.h"

@implementation EspCommonUtils

+ (BOOL)isNull:(NSObject *)obj {
    if (obj == nil) {
        return YES;
    } else if ([obj isKindOfClass:[NSNull class]]) {
        return YES;
    }
    
    return NO;
}

@end
