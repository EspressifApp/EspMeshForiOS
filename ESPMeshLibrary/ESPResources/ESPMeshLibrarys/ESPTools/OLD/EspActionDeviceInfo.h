//
//  EspActionDeviceInfo.h
//  Esp32Mesh
//
//  Created by AE on 2018/3/1.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspActionDevice.h"
#import "EspDevice.h"

@interface EspActionDeviceInfo : EspActionDevice

- (BOOL)doActionGetDeviceInfoLocal:(EspDevice *)device;
- (NSMutableDictionary*)doActionGetDevicesInfoLocal:(NSArray<EspDevice *> *)devices;
- (BOOL)doActionGetDeviceStatusLocal:(EspDevice *)device forCids:(NSArray<NSNumber *> *)cids;
- (void)doActionGetDevicesStatusLocal:(NSArray<EspDevice *> *)devices forCids:(NSArray<NSNumber *> *)cids;
- (BOOL)doActionSetDeviceStatusLocal:(EspDevice *)device forCharacteristics:(NSArray<EspDeviceCharacteristic *> *)characteristics;
- (void)doActionSetDevicesStatusLocal:(NSArray<EspDevice *> *)devices forCharacteristics:(NSArray<EspDeviceCharacteristic *> *)characteristics;

@end
