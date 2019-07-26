//
//  ESPFBYDataBase.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/7/24.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESPFBYDataBase : NSObject
+ (void)espDataBaseInit:(NSString *)message;

//hwdevice_table表  保存本地配对信息
+ (void)saveHWDevicefby:(NSString *)message;
+ (void)saveHWDevicesfby:(NSString *)message;
+ (void)deleteHWDevicefby:(NSString *)message;
+ (void)deleteHWDevicesfby:(NSString *)message;
+ (NSString *)loadHWDevicesfby;

//表  Group组
+ (id)saveGroupfby:(NSString *)message;
+ (void)saveGroupsfby:(NSString *)message;
+ (NSString *)loadGroupsfby;
+ (void)deleteGroupfby:(NSString *)message;

//Mac  Mac表
+ (void)saveMacfby:(NSString *)message;
+ (void)deleteMacfby:(NSString *)message;
+ (void)deleteMacsfby:(NSString *)message;
+ (NSString *)loadMacsfby;

//meshId表
+ (void)saveMeshIdfby:(NSString *)message;
+ (void)deleteMeshIdfby:(NSString *)message;
+ (NSString *)loadLastMeshIdfby;
+ (NSString *)loadMeshIdsfby;

//文件 Key - Value 增删改查
+ (void)saveValuesForKeysInFilefby:(NSString *)message;
+ (void)removeValuesForKeysInFilefby:(NSString *)message;
+ (NSString *)loadValueForKeyInFilefby:(NSString *)message;
+ (NSString *)loadAllValuesInFilefby:(NSString *)message;

//保存本地事件
+ (void)saveDeviceEventsCoordinatefby:(NSString *)message;
+ (NSString *)loadDeviceEventsCoordinatefby:(NSString *)message;
+ (NSString *)loadAllDeviceEventsCoordinatefby:(NSString *)message;
+ (void)deleteDeviceEventsCoordinatefby:(NSString *)message;
+ (void)deleteAllDeviceEventsCoordinatefby;

//table信息存储(ipad)
+ (void)saveDeviceTablefby:(NSString *)message;
+ (NSString *)loadDeviceTablefby;

//table设备信息存储(ipad)
+ (void)saveTableDevicesfby:(NSString *)message;
+ (NSString *)loadTableDevicesfby;
+ (void)removeTableDevicesfby:(NSString *)message;
+ (void)removeAllTableDevicesfby;

// 保存配网记录
+ (void)saveObject:(NSDictionary *)objItem withNameTable:(NSString *)nameTable withId:(NSString *)ssid;

// 获取配网记录
+ (NSArray *)getAllItemsFromTablefby:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
