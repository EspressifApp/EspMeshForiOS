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
typedef void(^BleScanSuccessBlock)(NSDictionary *BleScanDic);

typedef void(^DevicesAsyncSuccessBlock)(NSDictionary *DevicesAsyncDic);

typedef void(^startOTASuccessBlock)(NSDictionary *startOTADic);

typedef void(^startOTAProgressBlock)(NSDictionary *startOTADic);

/**
 开启蓝牙扫描

 @param success 蓝牙扫描成功的回调
 @param failure 蓝牙扫描失败的回调
 */
+ (void)startBleScanSuccess:(BleScanSuccessBlock)success andFailure:(void(^)(int fail))failure;

/**
 关闭蓝牙扫描
 */
+ (void)stopBleScan;

/**
 蓝牙连接

 @param deviceInfo 蓝牙连接参数
 @param success 蓝牙连接成功回调
 @param failure 蓝牙连接失败回调
 */
+ (void)BleConnection:(NSDictionary *)deviceInfo andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *dic))failure;

/**
 蓝牙配网
 messageDic = @{
 @"ssid":@"",
 @"password":@"",
 @"ble_addr":@"",
 @"ScanBLEDevices":@{}
 }
 @param messageDic 蓝牙配网的信息
 @param success 蓝牙配网成功的回调
 @param failure 蓝牙配网失败的回调
 */
+ (void)startBLEConfigure:(NSDictionary *)messageDic andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *dic))failure;

/**
 停止配网
 */
+ (void)stopConfigureBlufi;

/**
 开启UDP扫描

 @param success UDP扫描成功的回调，回调有两种情况：1. 获取到设备基本信息onDeviceScanning回调，2. 获取到设备详细信息DevicesOfScanUDP
 @param failure UDP扫描失败的回调，fail分8010和8011，8010包含(allArray格式不正确、getMeshInfoFromHost网络请求失败、设备基本信息tempInfosArr为空)，8011为获取设备详情失败查询加载本地存储数据
 */
+ (void)scanDevicesAsyncSuccess:(DevicesAsyncSuccessBlock)success andFailure:(void(^)(int fail))failure;

/**
 发送多个设备命令
 messageDic = @{
 @"request":@"",
 @"callback":@"",
 @"tag":@"",
 @"mac":@"",
 @"host":@"",
 @"root_response":@"",
 @"isSendQueue":@""
 }
 @param messageDic 发送设备命令的信息
 @param success 发送设备命令成功的回调
 @param failure 发送设备命令失败的回调
 */
+ (void)requestDevicesMulticastAsync:(NSDictionary *)messageDic andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *failureDic))failure;

/**
 发送单个设备命令(该方法弃用，功能与requestDevicesMulticastAsync方法合并)
 messageDic = @{
 @"request":@"",
 @"callback":@"",
 @"tag":@"",
 @"mac":@"",
 @"host":@"",
 @"root_response":@""
 }
 @param messageDic 发送设备命令的信息
 @param success 发送设备命令成功的回调
 @param failure 发送设备命令失败的回调
 */
- (void)requestDeviceAsync:(NSDictionary *)messageDic andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(NSDictionary * _Nonnull))failure;
/**
 设备升级
 messageDic = @{
 @"macs":@"",
 @"bin":@"",
 @"host":@"",
 @"type":@""
 }
 @param message 设备升级的信息
 @param successOTA 设备升级成功的回调
 @param failure 设备升级失败的回调
 */
+ (void)startOTA:(NSString *)message Success:(startOTASuccessBlock)successOTA andFailure:(void(^)(int fail))failure;

/**
 设备升级进度查询

 @param successOTA 设备升级成功回调
 @param failure 设备升级失败回调
 */
+ (void)networkRequestOTAProgress:(startOTAProgressBlock)successOTA andFailure:(void(^)(int fail))failure;

/**
 停止OTA升级
 message = {
 "host":[]
 }

 @param message H5传入停止OTA升级的IP地址
 @param sessionTask 本地正在进行中的网络请求
 */
+ (void)stopOTA:(NSString *)message withSessionTask:(NSURLSessionTask *)sessionTask;

/**
 重启设备命令
 message = {
 "macs":[]
 }

 @param message H5传入重启设备的MAC地址
 */
+ (void)reboot:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
