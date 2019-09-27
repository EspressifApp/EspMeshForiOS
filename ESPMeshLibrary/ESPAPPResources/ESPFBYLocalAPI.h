//
//  ESPFBYLocalAPI.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/9/3.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "ESPCheckAppVersion.h"
#import "ESPDataConversion.h"
#import "ESPAPPResources.h"
#import "ESPFBYDataBase.h"
#import "YTKKeyValueStore.h"
#import "NSString+URL.h"
#import "ESPLoadHyperlinksViewController.h"
#import "QRCodeReaderViewController.h"
#import "ESPUDP3232.h"
//#import <objc/runtime.h>

#import "QRCodeReaderDelegate.h"

#define ESPMeshAppleID @"1420425921"
#define ValidDict(f) (f!=nil && [f isKindOfClass:[NSDictionary class]])
#define ValidArray(f) (f!=nil && [f isKindOfClass:[NSArray class]] && [f count]>0)
NS_ASSUME_NONNULL_BEGIN
//@protocol SendMsgDelegate <NSObject>
//
//-(void)sendMsg:(NSString*)methodName param:(id)params;
//
//@end

@protocol ESPFBYLocalAPIDelegate <NSObject>
// 引导页视图隐藏代理
- (void)hideGuidePageView;
- (void)sendLocalMsg:(NSString*)methodName param:(id)params;
- (void)webViewLoadMainPage:(NSString *)loadPageName;

@end

@protocol NativeApisProtocols <JSExport>
//APP版本检测
- (void)checkAppVersion;
//获取系统语言
- (void)getLocale;
// 初始化视图
- (void)hideCoverImage;
// 获取APP版本信息
- (void)getAppInfo;
//JS 注册系统通知
- (void)registerPhoneStateChange;
//开启UDP扫描
- (void)scanDevicesAsync;
//hwdevice_table表  保存本地配对信息
- (void)saveHWDevice:(NSString *)message;
- (void)saveHWDevices:(NSString *)message;
- (void)deleteHWDevice:(NSString *)message;
- (void)deleteHWDevices:(NSString *)message;
- (void)loadHWDevices;
//关闭蓝牙扫描
- (void)stopBleScan;
//开启蓝牙扫描
- (void)startBleScan;
//APP版本更新
- (void)appVersionUpdate:(NSString *)message;
//获取topo结构
- (void)scanTopo;
//更新房间信息
- (void)updateDeviceGroup:(NSString *)message;
//发送多个设备命令
- (void)requestDevicesMulticast:(NSString *)message;
//发送单个设备命令
- (void)requestDevice:(NSString *)message;
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
//设备升级
- (void)startOTA:(NSString *)message;
//下载升级文件
- (void)downloadLatestRom;
//获取本地升级文件
- (void)getUpgradeFiles;
//停止OTA升级
- (void)stopOTA:(NSString *)message;
//重启设备命令
- (void)reboot:(NSString *)message;
- (void)clearBleCache;
- (void)removeDevicesForMacs:(NSString *)message;
//文件 Key - Value 增删改查
- (void)saveValuesForKeysInFile:(NSString *)message;
- (void)removeValuesForKeysInFile:(NSString *)message;
- (void)loadValueForKeyInFile:(NSString *)message;
- (void)loadAllValuesInFile:(NSString *)message;
//保存本地事件
- (void)saveDeviceEventsCoordinate:(NSString *)message;
- (void)loadDeviceEventsCoordinate:(NSString *)message;
- (void)loadAllDeviceEventsCoordinate:(NSString *)message;
- (void)deleteDeviceEventsCoordinate:(NSString *)message;
- (void)deleteAllDeviceEventsCoordinate;
//table信息存储(ipad)
- (void)saveDeviceTable:(NSString *)message;
- (void)loadDeviceTable;
//table设备信息存储(ipad)
- (void)saveTableDevices:(NSString *)message;
- (void)loadTableDevices;
- (void)removeTableDevices:(NSString *)message;
- (void)removeAllTableDevices;
//跳转系统设置页面
- (void)gotoSystemSettings:(NSString *)message;
//加载超链接
- (void)newWebView:(NSString *)message;
//扫描二维码
- (void)scanQRCode;
//本地 (app) 和阿里云 (cloud) 页面加载
- (void)mainPageLoad:(NSString *)message;
@end

@interface ESPFBYLocalAPI : NSObject

@property (weak, nonatomic)id<ESPFBYLocalAPIDelegate> delegate;
//@property (weak, nonatomic)id<SendMsgDelegate> messageDelegate;
/**
 * 单例构造方法
 * @return ESPFBYLocalAPI共享实例
 */
+ (instancetype)share;

/**
 给JavaScript提供运行的上下文环境

 @param context JavaScript
 @param localVC 根视图
 @return JavaScript
 */
- (JSContext *)getLocalJSContext:(JSContext *)context withLocalVC:(UIViewController *)localVC;

/**
 设备状态变化监视
 */
- (void)deviceStatusChangeMonitoring;

@end

NS_ASSUME_NONNULL_END
