//
//  ESPAPPResources.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/2/28.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESPMeshManager.h"

NS_ASSUME_NONNULL_BEGIN
@interface ESPAPPResources : NSObject
typedef void(^BleScanSuccessBlock)(NSArray *BleScanArr);
@property (nonatomic, copy)BleScanSuccessBlock BleScanSuccess;

typedef void(^DevicesAsyncSuccessBlock)(NSArray *DevicesAsyncArr);
@property (nonatomic, copy)DevicesAsyncSuccessBlock DevicesAsyncSuccess;

typedef void(^startOTASuccessBlock)(NSArray *startOTAArr);
@property (nonatomic, copy)startOTASuccessBlock startOTASuccess;

/**
 *  开启蓝牙扫描
 *
 *  @param success  蓝牙扫描成功的回调
 *  @param failure  蓝牙扫描失败的回调
 *
 */
- (void)startBleScanSuccess:(BleScanSuccessBlock)success andFailure:(void(^)(int fail))failure;

/**
 *  关闭蓝牙扫描
 *
 */
- (void)stopBleScan;

/**
 *  蓝牙配网
 *
 *  @param messageDic 蓝牙配网的信息
 *  @param success  蓝牙配网成功的回调
 *  @param failure  蓝牙配网失败的回调
 *
 */
- (void)startConfigureBlufi:(NSDictionary *)messageDic andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *dic))failure;

/**
 *  停止配网
 *
 */
- (void)stopConfigureBlufi;

/**
 *  开启UDP扫描
 *
 *  @param success  UDP扫描成功的回调
 *  @param failure  UDP扫描失败的回调
 *
 */
- (void)scanDevicesAsyncSuccess:(DevicesAsyncSuccessBlock)success andFailure:(void(^)(int fail))failure;


/**
 *  发送多个设备命令
 *
 *  @param messageDic 发送设备命令的信息
 *  @param success  发送设备命令成功的回调
 *  @param failure  发送设备命令失败的回调
 *
 */
- (void)requestDevicesMulticastAsync:(NSDictionary *)messageDic andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *dic))failure;

/**
 *  发送单个设备命令
 *
 *  @param messageDic 发送设备命令的信息
 *  @param success  发送设备命令成功的回调
 *  @param failure  发送设备命令失败的回调
 *
 */
- (void)requestDeviceAsync:(NSDictionary *)messageDic andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *dic))failure;

/**
 *  设备升级
 *
 *  @param messageDic 设备升级的信息
 *  @param success  设备升级成功的回调
 *  @param failure  设备升级失败的回调
 *
 */
- (void)startOTA:(NSDictionary *)messageDic Success:(startOTASuccessBlock)success andFailure:(void(^)(int fail))failure;

/**
 *  停止OTA升级
 *
 *  @param messageDic 停止OTA升级的信息
 *
 */
- (void)stopOTA:(NSDictionary *)messageDic;

/**
 *  重启设备命令
 *
 *  @param messageDic 重启设备命令的信息
 *
 */
- (void)reboot:(NSDictionary *)messageDic;

@end

NS_ASSUME_NONNULL_END
