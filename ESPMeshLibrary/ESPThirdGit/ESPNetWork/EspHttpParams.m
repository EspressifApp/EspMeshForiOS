//
//  EspHttpParams.m
//  Esp32Mesh
//
//  Created by AE on 2018/2/27.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspHttpParams.h"

@implementation EspHttpParams

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.timeout = -1;
        self.tryCount = 1;
        self.requireResponse = YES;
    }
    return self;
}

@end
