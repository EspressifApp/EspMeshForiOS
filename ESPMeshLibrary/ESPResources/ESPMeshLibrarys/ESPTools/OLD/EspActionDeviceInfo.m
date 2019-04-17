//
//  EspActionDeviceInfo.m
//  Esp32Mesh
//
//  Created by AE on 2018/3/1.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspActionDeviceInfo.h"
#import "EspConstants.h"
#import "EspHttpResponse.h"
#import "EspDeviceUtil.h"
#import "EspCommonUtils.h"
#import "EspHttpUtils.h"
#import "EspJsonUtils.h"


static NSString * const EspRequestGetDeviceInfo = @"get_device_info";
static NSString * const EspRequestSetStatus = @"set_status";
static NSString * const EspRequestGetStatus = @"get_status";

static NSString * const EspKeyTid = @"tid";
static NSString * const EspKeyName = @"name";
static NSString * const EspKeyCharacteristics = @"characteristics";
static NSString * const EspKeyCid = @"cid";
static NSString * const EspKeyFormat = @"format";
static NSString * const EspKeyPerms = @"perms";
static NSString * const EspKeyMin = @"min";
static NSString * const EspKeyMax = @"max";
static NSString * const EspKeyStep = @"step";
static NSString * const EspKeyValue = @"value";
static NSString * const EspKeyCids = @"cids";

@implementation EspActionDeviceInfo

- (BOOL)doActionGetDeviceInfoLocal:(EspDevice *)device {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:EspRequestGetDeviceInfo forKey:EspKeyRequest];
    NSData *data = [EspJsonUtils getDataWithDictionary:dict];
    if (data == nil) {
        return NO;
    }
    EspHttpResponse *response = [EspDeviceUtil httpLocalRequestForDevice:device content:data params:nil headers:nil];
    return [self setDeviceInfo:device withResponse:response];
}

- (NSMutableDictionary*)doActionGetDevicesInfoLocal:(NSArray<EspDevice *> *)devices {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:EspRequestGetDeviceInfo forKey:EspKeyRequest];
    NSData *data = [EspJsonUtils getDataWithDictionary:dict];
    NSMutableDictionary* resps=[NSMutableDictionary dictionaryWithCapacity:0];
    if (data == nil) {
        return resps;
    }
    
    NSMutableSet *allDeviceSet = [NSMutableSet set];
    for (EspDevice *device in devices) {
        //if ([device isState:EspDeviceStateLocal]) {
            [allDeviceSet addObject:device];
        //}
    }
    
    EspHttpParams *params = [[EspHttpParams alloc] init];
    double timeout = 5;
    for (int i = 0; i < 3 && [allDeviceSet count] > 0; i++) {
        params.timeout = (timeout + timeout * i);
        NSArray *respArray = [EspDeviceUtil httpLocalMulticastRequestForDevices:[allDeviceSet allObjects] content:data params:params headers:nil multithread:false];
        NSDictionary *respDict = [EspDeviceUtil getDictionaryWithDeviceResponses:respArray];
        
        for (EspDevice *device in devices) {
            EspHttpResponse *response = respDict[device.mac];
            BOOL suc = [self setDeviceInfo:device withResponse:response];
            if (suc) {
                resps[device.mac]=respDict[device.mac];
                [device notifyStatusChanged];
                [allDeviceSet removeObject:device];
            }
        }
    }
    return resps;
}

- (BOOL)setDeviceInfo:(EspDevice *)device withResponse:(EspHttpResponse *)response {
    id json = [self getResponseJSON:response];
    if (json == nil) {
        return NO;
    }
    
    NSString *parentMac = [response getHeaderValueForKey:EspHeaderParentMac];
    if (![EspCommonUtils isNull:parentMac]) {
        device.parentDeviceMac = parentMac;
    }
    NSString *meshLayerStr = [response getHeaderValueForKey:EspHeaderMeshLayer];
    if (![EspCommonUtils isNull:meshLayerStr]) {
        int meshLayer = [meshLayerStr intValue];
        device.meshLayerLevel = meshLayer;
    }
    
    NSNumber *statusCode = [json valueForKey:EspKeyStatusCode];
    if ([EspCommonUtils isNull:statusCode] || [statusCode intValue] != EspStatusCodeSuc) {
        return NO;
    }
    
    @try {
        NSNumber *tid = [json valueForKey:EspKeyTid];
        device.typeId = [tid intValue];
        
        NSString *name = [json valueForKey:EspKeyName];
        device.name = name;
        
        NSString *version = [json valueForKey:EspKeyVersion];
        if (version) {
            device.currentRomVersion = version;
        }
        
        NSNumber *mlinkVersion = [json valueForKey:EspKeyMlinkVersion];
        if (!mlinkVersion) {
            mlinkVersion = [json valueForKey:EspKeyProtocolVersion];
        }
        int protocolVersion = mlinkVersion ? [mlinkVersion intValue] : 0;
        [device clearCharacteristics];
        NSArray *ctrtArray = [json valueForKey:EspKeyCharacteristics];
        switch (protocolVersion) {
            case 0:
            case 2:
                [self setProtocol0CharacteristicsForDevice:device withJsonArray:ctrtArray];
                break;
            case 1:
                [self setProtocol1CharacteristicsForDevice:device withJsonArray:ctrtArray];
                break;
        }
        
       // [[EspDBManager sharedInstance].device saveDevice:device];
        return YES;
    }
    @catch(NSException *e) {
        NSLog(@"%@", e);
    }
    return NO;
}

- (void) setProtocol0CharacteristicsForDevice:(EspDevice *)device withJsonArray:(NSArray *)ctrtArray {
    for (id ctrtJSON in ctrtArray) {
        NSNumber *cid = [ctrtJSON valueForKey:EspKeyCid];
        NSString *cname = [ctrtJSON valueForKey:EspKeyName];
        NSString *format = [ctrtJSON valueForKey:EspKeyFormat];
        NSNumber *perms = [ctrtJSON valueForKey:EspKeyPerms];
        NSNumber *max = [ctrtJSON valueForKey:EspKeyMax];
        NSNumber *min = [ctrtJSON valueForKey:EspKeyMin];
        NSNumber *step = [ctrtJSON valueForKey:EspKeyStep];
        id value = [ctrtJSON valueForKey:EspKeyValue];
        
        EspDeviceCharacteristic *c = [EspDeviceCharacteristic newInstance:format];
        c.cid = [cid intValue];
        c.name = cname;
        c.perms = [perms intValue];
        c.max = max;
        c.min = min;
        c.step = step;
        c.value = value;
        
        if ([format isEqualToString:EspFormatInt]) {
            [device addOrReplaceCharacteristic:c];
        } else if ([format isEqualToString:EspFormatDouble]) {
            [device addOrReplaceCharacteristic:c];
        } else if ([format isEqualToString:EspFormatString]) {
            [device addOrReplaceCharacteristic:c];
        } else if ([format isEqualToString:EspFormatJson]) {
            [device addOrReplaceCharacteristic:c];
        }
    }
}

- (void) setProtocol1CharacteristicsForDevice:(EspDevice *)device withJsonArray:(NSArray *)ctrtArray {
    const NSUInteger indexCid = 0;
    const NSUInteger indexCname = 1;
    const NSUInteger indexFormat = 2;
    const NSUInteger indexPerms = 3;
    const NSUInteger indexValue = 4;
    const NSUInteger indexMin = 5;
    const NSUInteger indexMax = 6;
    const NSUInteger indexStep = 7;
    for (id array in ctrtArray) {
        NSString *format = array[indexFormat];
        EspDeviceCharacteristic *characteristic = [EspDeviceCharacteristic newInstance:format];
        if (!characteristic) {
            continue;
        }
        
        NSNumber *cid = array[indexCid];
        characteristic.cid = [cid intValue];
        NSString *cname = array[indexCname];
        characteristic.name = cname;
        NSNumber *perms = array[indexPerms];
        characteristic.perms = [perms intValue];
        if ([characteristic isReadable]) {
            id value = array[indexValue];
            characteristic.value = value;
        }
        NSNumber *min = array[indexMin];
        characteristic.min = min;
        NSNumber *max = array[indexMax];
        characteristic.max = max;
        NSNumber *step = array[indexStep];
        characteristic.step = step;
        
        [device addOrReplaceCharacteristic:characteristic];
    }
}

- (BOOL)doActionGetDeviceStatusLocal:(EspDevice *)device forCids:(NSArray<NSNumber *> *)cids {
    if ([EspCommonUtils isNull:cids] || [cids count] == 0) {
        return NO;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:EspRequestGetStatus forKey:EspKeyRequest];
    [dict setObject:cids forKey:EspKeyCids];
    NSData *data = [EspJsonUtils getDataWithDictionary:dict];
    if (!data) {
        return NO;
    }
    
    EspHttpResponse *response = [EspDeviceUtil httpLocalRequestForDevice:device content:data params:nil headers:nil];
    id respJSON = [self getResponseJSON:response];
    if (!respJSON) {
        return NO;
    }
    
    @try {
        NSNumber *statusCode = [respJSON valueForKey:EspKeyStatusCode];
        if ([statusCode intValue] != EspStatusCodeSuc) {
            return NO;
        }
        
        NSArray *cArray = [respJSON valueForKey:EspKeyCharacteristics];
        for (id cJSON in cArray) {
            NSNumber *cid = [cJSON valueForKey:EspKeyCid];
            id cvalue = [cJSON valueForKey:EspKeyValue];
            
            EspDeviceCharacteristic *deviceChar = [device getCharacteristicForCid:[cid intValue]];
            if (![EspCommonUtils isNull:deviceChar]) {
                deviceChar.value = cvalue;
            }
        }
        
        return YES;
    }
    @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    return NO;
}

- (void)doActionGetDevicesStatusLocal:(NSArray<EspDevice *> *)devices forCids:(NSArray<NSNumber *> *)cids {
    // TODO
    if ([EspCommonUtils isNull:cids] || [cids count] == 0) {
        return;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:EspRequestGetStatus forKey:EspKeyRequest];
    [dict setObject:cids forKey:EspKeyCids];
    NSData *data = [EspJsonUtils getDataWithDictionary:dict];
    if (data == nil) {
        return;
    }
    
    NSArray *respArray = [EspDeviceUtil httpLocalMulticastRequestForDevices:devices content:data params:nil headers:nil multithread:false];
    NSDictionary *respDict = [EspDeviceUtil getDictionaryWithDeviceResponses:respArray];
    for (EspDevice *device in devices) {
        EspHttpResponse *response = respDict[device.mac];
        id respJSON = [self getResponseJSON:response];
        @try {
            NSNumber *statusCode = [respJSON valueForKey:EspKeyStatusCode];
            if ([statusCode intValue] != EspStatusCodeSuc) {
                continue;
            }
            
            NSArray *cArray = [respJSON valueForKey:EspKeyCharacteristics];
            for (id cJSON in cArray) {
                NSNumber *cid = [cJSON valueForKey:EspKeyCid];
                id cvalue = [cJSON valueForKey:EspKeyValue];
                EspDeviceCharacteristic *c = [device getCharacteristicForCid:[cid intValue]];
                if (c != nil) {
                    c.value = cvalue;
                }
            }
        }
        @catch (NSException *e) {
            NSLog(@"%@", e);
        }
    }
}

- (BOOL)doActionSetDeviceStatusLocal:(EspDevice *)device forCharacteristics:(NSArray<EspDeviceCharacteristic *> *)characteristics {
    if ([EspCommonUtils isNull:characteristics] || [characteristics count] == 0) {
        return NO;
    }
    
    NSData *data = [self getLocalPostJSONData:characteristics];
    if (data == nil) {
        return NO;
    }
    
    EspHttpResponse *response = [EspDeviceUtil httpLocalRequestForDevice:device content:data params:nil headers:nil];
    id respJSON = [self getResponseJSON:response];
    if (respJSON == nil) {
        return NO;
    }
    
    @try {
        NSNumber *statusCode = [respJSON valueForKey:EspKeyStatusCode];
        if ([statusCode intValue] != EspStatusCodeSuc) {
            return NO;
        }
        
        for (EspDeviceCharacteristic *c in characteristics) {
            EspDeviceCharacteristic *deviceC = [device getCharacteristicForCid:c.cid];
            if (![EspCommonUtils isNull:deviceC]) {
                deviceC.value = c.value;
            }
        }
        
        return YES;
    }
    @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    return NO;
}

- (void)doActionSetDevicesStatusLocal:(NSArray<EspDevice *> *)devices forCharacteristics:(NSArray<EspDeviceCharacteristic *> *)characteristics {
    // TODO
    NSData *data = [self getLocalPostJSONData:characteristics];
    if (!data) {
        return;
    }
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [headers setObject:@"true" forKey:EspHeaderNoResponse];
    [EspDeviceUtil httpLocalMulticastRequestForDevices:devices content:data params:nil headers:headers multithread:false];
}

- (NSData *)getLocalPostJSONData:(NSArray<EspDeviceCharacteristic *> *)characteristics {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:EspRequestSetStatus forKey:EspKeyRequest];
    NSMutableArray *cvArray = [NSMutableArray arrayWithCapacity:[characteristics count]];
    for (EspDeviceCharacteristic *c in characteristics) {
        NSNumber *cid = [NSNumber numberWithInt:c.cid];
        NSDictionary *cvDict = [NSDictionary dictionaryWithObjectsAndKeys:cid, EspKeyCid, c.value, EspKeyValue, nil];
        
        [cvArray addObject:cvDict];
    }
    [dict setObject:cvArray forKey:EspKeyCharacteristics];
    
    NSError *err;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&err];
    if (err) {
        NSLog(@"%@", err);
        return nil;
    }
    
    return data;
}

- (id)getResponseJSON:(EspHttpResponse *)response {
    if ([EspCommonUtils isNull:response]) {
        return nil;
    }
    
    if (response.code != EspHttpCodeOK) {
        return nil;
    }
    
    return [response getContentJSON];
}
@end
