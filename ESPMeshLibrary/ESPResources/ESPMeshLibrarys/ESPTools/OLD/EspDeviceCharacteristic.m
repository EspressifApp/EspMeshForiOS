//
//  EspDeviceCharacteristic.m
//  Esp32Mesh
//
//  Created by AE on 2018/2/22.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspDeviceCharacteristic.h"

@implementation EspDeviceCharacteristic

- (BOOL)isReadable {
    return (self.perms & 1) == 1;
}

- (BOOL)isWritable {
    return ((self.perms >> 1) & 1) == 1;
}

- (BOOL)isEventAvailable {
    return ((self.perms >> 2) & 1) == 1;
}

- (EspDeviceCharacteristic *)cloneInstance {
    EspDeviceCharacteristic *result = [EspDeviceCharacteristic newInstance:self.format];
    if (result != nil) {
        result.cid = self.cid;
        result.name = self.name;
        result.perms = self.perms;
        result.value = self.value;
        result.min = self.min;
        result.max = self.max;
        result.step = self.step;
    }
    
    return result;
}

+ (EspDeviceCharacteristic *)newInstance:(NSString *)format {
    EspDeviceCharacteristic *result = nil;
    if ([EspFormatInt isEqualToString:format]
        || [EspFormatDouble isEqualToString:format]
        || [EspFormatString isEqualToString:format]
        || [EspFormatJson isEqualToString:format]) {
        result = [[EspDeviceCharacteristic alloc] init];
        result.format = format;
    }
    return result;
}

- (id)setValueObjectWithString:(NSString *)valueStr {
    id newValue = nil;
    if ([self.format isEqualToString:EspFormatInt]) {
        newValue = [NSNumber numberWithInt:[valueStr intValue]];
    } else if ([self.format isEqualToString:EspFormatDouble]) {
        newValue = [NSNumber numberWithDouble:[valueStr doubleValue]];
    } else if ([self.format isEqualToString:EspFormatString]) {
        newValue = valueStr;
    } else if ([self.format isEqualToString:EspFormatJson]) {
        newValue = valueStr;
    }
    
    self.value = newValue;
    
    return newValue;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"cid=%d, name=%@, format=%@, perms=%d, max=%@, min=%@, step=%@, value=%@", self.cid, self.name, self.format, self.perms, self.max, self.min, self.step, self.value];
}

@end
