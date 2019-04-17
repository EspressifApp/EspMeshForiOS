//
//  EspDevice.m
//  Esp32Mesh
//
//  Created by AE on 2018/1/3.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspDevice.h"

@implementation EspDevice

- (instancetype)init {
    self = [super init];
    if (self) {
        stateValue = 0;
        characters = [NSMutableDictionary dictionary];
        self.sendInfo = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (int)getStateValue:(EspDeviceState)state{
    return 1 << state;
}

- (void)addState:(EspDeviceState)state {
    stateValue |= [self getStateValue:state];
}

- (void)removeState:(EspDeviceState)state {
    stateValue &= ~[self getStateValue:state];
}

- (void)clearState {
    stateValue = 0;
}

- (BOOL)isState:(EspDeviceState)state {
    return (stateValue & [self getStateValue:state]) != 0;;
}

- (EspDeviceCharacteristic *)getCharacteristicForCid:(int)cid {
    @synchronized(characters) {
        NSNumber *key = [NSNumber numberWithInt:cid];
        return [characters objectForKey:key];
    }
}

- (NSArray<EspDeviceCharacteristic *> *)getCharacteristics {
    @synchronized(characters) {
        return [characters allValues];
    }
}

- (void)addOrReplaceCharacteristic:(EspDeviceCharacteristic *)characteristic {
    @synchronized(characters) {
        NSNumber *key = [NSNumber numberWithInt:characteristic.cid];
        [characters setObject:characteristic forKey:key];
    }
}

- (void)addOrReplaceCharacteristics:(NSArray<EspDeviceCharacteristic *> *)characteristics {
    @synchronized(characters) {
        for (EspDeviceCharacteristic *c in characteristics) {
            NSNumber *key = [NSNumber numberWithInt:c.cid];
            [characters setObject:c forKey:key];
        }
    }
}

- (void)removeCharacteristicForCid:(int)cid {
    @synchronized(characters) {
        NSNumber *key = [NSNumber numberWithInt:cid];
        [characters removeObjectForKey:key];
    }
}

- (void)clearCharacteristics {
    @synchronized(characters) {
        [characters removeAllObjects];
    }
}

- (void)notifyStatusChanged {
    // TODO
}


-(NSString*)descriptionStr{
    return [NSString stringWithFormat:@"mac:%@,name:%@,\n,host:%@,port%@\n,meshId:%@,RSSI:%d,version:%@",self.mac,self.name,self.host,self.port,self.meshID,self.RSSI,self.currentRomVersion];
}


@end
