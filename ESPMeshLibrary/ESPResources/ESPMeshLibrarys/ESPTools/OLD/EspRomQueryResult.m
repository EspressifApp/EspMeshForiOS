//
//  EspRomQueryResult.m
//  Esp32Mesh
//
//  Created by AE on 2018/4/24.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspRomQueryResult.h"

@implementation EspRomQueryResult

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fileNames = [NSMutableArray array];
    }
    return self;
}

- (void)addFileName:(NSString *)name {
    [self.fileNames addObject:name];
}

- (void)removeFileName:(NSString *)name {
    [self.fileNames removeObject:name];
}

@end
