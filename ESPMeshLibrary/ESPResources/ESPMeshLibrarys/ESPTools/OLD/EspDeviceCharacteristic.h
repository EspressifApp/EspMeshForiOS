//
//  EspDeviceCharacteristic.h
//  Esp32Mesh
//
//  Created by AE on 2018/2/22.
//  Copyright © 2018年 AE. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const EspFormatInt = @"int";
static NSString * const EspFormatDouble = @"double";
static NSString * const EspFormatString = @"string";
static NSString * const EspFormatJson = @"json";

@interface EspDeviceCharacteristic : NSObject

@property(nonatomic, assign) int cid;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *format;
@property(nonatomic, assign) int perms;
@property(nonatomic, strong) NSNumber *min;
@property(nonatomic, strong) NSNumber *max;
@property(nonatomic, strong) NSNumber *step;
@property(nonatomic, strong) id value;

- (BOOL) isReadable;
- (BOOL) isWritable;
- (BOOL) isEventAvailable;

- (EspDeviceCharacteristic *) cloneInstance;

+ (EspDeviceCharacteristic *) newInstance:(NSString *)format;

- (id) setValueObjectWithString:(NSString *)valueStr;

@end
