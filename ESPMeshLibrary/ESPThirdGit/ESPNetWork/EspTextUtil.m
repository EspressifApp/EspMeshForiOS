//
//  TextUtil.m
//  Esp32Mesh
//
//  Created by AE on 2018/2/24.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspTextUtil.h"

@implementation EspTextUtil

+ (BOOL)isEmpty:(NSString *)string {
    if (string == nil) {
        return YES;
    } else if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    } else if ([string length] == 0) {
        return YES;
    }

    return NO;
}

@end
