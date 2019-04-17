//
//  ESPNewWebViewController.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/27.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "ESPMeshManager.h"
#import "QRCodeReaderDelegate.h"

@protocol NativeApisProtocol <JSExport>

//关闭蓝牙扫描
- (void)stopBleScan;
// 初始化视图
- (void)hideCoverImage;
//APP版本检测
- (void)checkAppVersion;
//APP版本更新
- (void)appVersionUpdate:(NSString *)message;
//用户登录信息
- (void)userGuestLogin;
//获取系统语言
- (void)getLocale;
//用户登录
- (void)userLogin:(NSString *)message;
//开启蓝牙扫描
- (void)startBleScan;
//获取topo结构
- (void)scanTopo;
//开启UDP扫描
- (void)scanDevicesAsync;
//hwdevice_table表  保存本地配对信息
- (void)saveHWDevice:(NSString *)message;
- (void)saveHWDevices:(NSString *)message;
- (void)deleteHWDevice:(NSString *)message;
- (void)deleteHWDevices:(NSString *)message;
- (void)loadHWDevices;
//发送多个设备命令
- (void)requestDevicesMulticastAsync:(NSString *)message;
//发送单个设备命令
- (void)requestDeviceAsync:(NSString *)message;
//发送多个设备命令防止重复操作
- (void)addQueueTask:(NSString *)message;
//表  Group组
- (void)saveGroup:(NSString *)message;
- (void)saveGroups:(NSString *)message;
- (void)loadGroups;
- (void)deleteGroup:(NSString *)message;
//Mac  Mac表
- (void)saveMac:(NSString *)message;
- (void)deleteMac:(NSString *)message;
- (void)deleteMacs:(NSString *)message;
- (void)loadMacs;
// 获取APP版本信息
- (void)getAppInfo;
//获取配网记录
- (void)loadAPs;
//蓝牙配网
- (void)startConfigureBlufi:(NSString *)message;
- (void)stopConfigureBlufi;
//meshId表
- (void)saveMeshId:(NSString *)message;
- (void)deleteMeshId:(NSString *)message;
- (void)loadLastMeshId;
- (void)loadMeshIds;
//扫描二维码
- (void)scanQRCode;
//设备升级
- (void)startOTA:(NSString *)message;
//下载升级文件
- (void)downloadLatestRom;
//获取本地升级文件
- (void)getUpgradeFiles;
//JS 注册系统通知
- (void)registerPhoneStateChange;
//文件 Key - Value 增删改查
- (void)saveValuesForKeysInFile:(NSString *)message;
- (void)removeValuesForKeysInFile:(NSString *)message;
- (void)loadValueForKeyInFile:(NSString *)message;
- (void)loadAllValuesInFile:(NSString *)message;

- (void)clearBleCache;
- (void)removeDevicesForMacs:(NSString *)message;
//停止OTA升级
- (void)stopOTA:(NSString *)message;
//重启设备命令
- (void)reboot:(NSString *)message;
//保存本地事件
- (void)saveDeviceEventsPosition:(NSString *)message;
- (void)loadDeviceEventsPositioin:(NSString *)message;
- (void)loadAllDeviceEventsPosition:(NSString *)message;
- (void)deleteDeviceEventsPosition:(NSString *)message;
- (void)deleteAllDeviceEventsPosition:(NSString *)message;
//跳转系统设置页面
- (void)gotoSystemSettings:(NSString *)message;
@end

@interface ESPNewWebViewController : UIViewController<QRCodeReaderDelegate>

@end
