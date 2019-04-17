//
//  EspDevice.h
//  Esp32Mesh
//
//  Created by AE on 2018/1/3.
//  Copyright © 2018年 AE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EspDeviceCharacteristic.h"
static const int EspMeshLayerRoot = 1;
static const int EspMeshLayerUnknow = -1;
@interface EspDevice : NSObject{
@private
    NSMutableDictionary<NSNumber*, EspDeviceCharacteristic*> const *characters;
@private
    int stateValue;
}

@property(nonatomic, strong) NSString *uuidBle;
@property(nonatomic, assign) int RSSI;
@property(nonatomic, strong) NSString *mac;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *ouiMDF;
@property(nonatomic, strong) NSString *version;
@property(nonatomic, strong) NSString *bssid;
@property(nonatomic, strong) NSString *deviceTid;
@property(nonatomic, assign) BOOL onlyBeacon;

@property(nonatomic, strong) NSString *httpType;
@property(nonatomic, strong) NSString *host;
@property(nonatomic, assign) NSString *port;

@property(nonatomic, strong) NSString *meshID;
@property(nonatomic, strong) NSString *parentDeviceMac;
@property(nonatomic, strong) NSString *rootDeviceMac;

@property(nonatomic, strong) NSString *key;
@property(nonatomic, strong) NSString *currentRomVersion;
@property(nonatomic, assign) int typeId;
@property(nonatomic, strong) NSString *typeName;
@property(nonatomic, assign) int meshLayerLevel;

@property(nonatomic,assign)NSInteger index;
@property(nonatomic,assign)NSInteger sequence;
@property(nonatomic,strong)NSData *Securtkey;
@property(nonatomic,strong)NSData *senddata;
@property(nonatomic,assign)BOOL blufisuccess;
@property(nonatomic,strong)NSTimer *connecttimer;
@property(nonatomic,strong)NSTimer *blufitimer;


@property(nonatomic,strong)NSMutableDictionary *sendInfo;

-(NSString*)descriptionStr;


typedef enum {
    EspDeviceStateIDLE,
    EspDeviceStateOfflice,
    EspDeviceStateLocal,
    EspDeviceStateCloud,
    EspDeviceStateUpgradeLocal,
    EspDeviceStateUpgradeCloud,
    EspDeviceStateDeleted,
}EspDeviceState;

- (void)addState:(EspDeviceState)state;
- (void)removeState:(EspDeviceState)state;
- (void)clearState;
- (BOOL)isState:(EspDeviceState)state;
- (EspDeviceCharacteristic *)getCharacteristicForCid:(int)cid;
- (NSArray<EspDeviceCharacteristic *> *)getCharacteristics;
- (void)addOrReplaceCharacteristic:(EspDeviceCharacteristic *)characteristic;
- (void)addOrReplaceCharacteristics:(NSArray<EspDeviceCharacteristic *> *)characteristics;
- (void)removeCharacteristicForCid:(int)cid;
- (void)clearCharacteristics;
- (void)notifyStatusChanged;

//获取设备详细信息
//- (NSMutableArray*)getDetailInfo:(EspDevice *)device;
//获取指定数据信息
//- (NSMutableArray*)getStatusInfo:(EspDevice *)device statusIDs:(NSArray*)statusIDs;
//设置指定数据信息
//- (BOOL*)setStatusInfo:(EspDevice *)device statusIDs:(NSDictionary*)statusIDAndValues;
@end
