//
//  ESPAliyunSDKUse.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/7/29.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>

//账号及用户
#import <IMSApiClient/IMSConfiguration.h>
#import <ALBBOpenAccountCloud/ALBBOpenAccountSDK.h>
#import <IMSThingCapability/IMSThingCapability.h>
#import <IMSAuthentication/IMSCredentialManager.h>
// 发现设备
#import <IMLDeviceCenter/IMLDeviceCenter.h>

#import <IMSAccount/IMSAccountService.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESPAliyunSDKUse : NSObject

typedef void(^deviceBindingBlock)(NSDictionary *resultIotid);
@property (nonatomic, copy)deviceBindingBlock deviceBindingBlock;

typedef void(^deviceBindingErrorBlock)(NSDictionary *errorMsg);
@property (nonatomic, copy)deviceBindingErrorBlock deviceBindingErrorBlock;

typedef void(^deviceStatusBlock)(NSArray *resultStatusArr);
typedef void(^deviceUnbindBlock)(NSArray *unbindResultArr);
typedef void(^deviceListBlock)(NSDictionary *resultdeviceDic);

typedef void(^startDiscoveryDevices)(NSArray * devices);
@property (nonatomic, copy)startDiscoveryDevices startDiscoveryDevicesBlock;

typedef void(^wifiDeviceUpgradeBlock)(NSDictionary *upgradeResult);
typedef void(^deviceUpgradeListBlock)(NSDictionary *deviceListResult);
typedef void(^deviceUpgradeStatusBlock)(NSDictionary *deviceStatusResult);
typedef void(^queryProductsInfoBlock)(NSDictionary *queryProductsInfoResult);


+ (instancetype)sharedClient;

/**
 阿里云飞燕平台用户登录

 @param baseViewController 当前的控制器
 @param success 成功回调
 @param failure 失败回调
 */
- (void)aliyunPresentLogin:(UIViewController *)baseViewController
                              andSuccess:(void(^)(ALBBOpenAccountUser *dic))success
                              andFailure:(void(^)(NSString *errorMsg))failure;

/**
 退出登录
 */
- (void)aliyunLogout;

/**
 是否已有帐号登录

 @return 返回值
 */
- (BOOL)isAliyunLogin;

/**
 获取阿里云绑定设备列表
 */
- (void)getAliyunDeviceList:(deviceListBlock)completionHandler;

/**
 发现本地的已配网设备，或者已配网设备、路由器发现的待配设备。发现的待配设备信息可以作为后续设备配网的入参信息
 */
- (void)aliStartDiscoveryDeviceCount:(int)count withBlock:(startDiscoveryDevices)didFoundBlock;

/**
 H5直接调用发现设备

 @param type 类型
 @param didFoundBlock 回调
 */
- (void)startDiscoveryDevicewithType:(int)type withBlock:(startDiscoveryDevices)didFoundBlock;

// 停止发现设备
- (void)aliStopDiscoveryDevice;

/**
 设备绑定

 @param deviceInfo 设备信息
 @param deviceBindingSuccess 成功回调
 @param failure 失败回调
 */
- (void)aliDeviceBinding:(NSDictionary *)deviceInfo
              andSuccess:(deviceBindingBlock)deviceBindingSuccess
              andFailure:(deviceBindingErrorBlock)failure;

/**
 设备解绑
 */
- (void)unbindDeviceRequest:(NSString *)deviceIotId andBlock:(deviceUnbindBlock)deviceUnbindBlock;

/**
 获取设备状态

 @param message 设备唯一标示iotId
 @param deviceStatus 成功回调
 */
- (void)getAliyunDeviceStatus:(NSString *)message andSuccess:(deviceStatusBlock)deviceStatus;

/**
 获取设备属性

 @param message 设备唯一标示iotId
 @param deviceStatus 成功回调
 */
- (void)getAliyunDeviceProperties:(NSString *)message andSuccess:(deviceStatusBlock)deviceStatus;

/**
 设置设备属性

 @param message 设备唯一标示iotId
 @param deviceStatus 成功回调
 */
- (void)setAliyunDeviceProperties:(NSString *)message andSuccess:(deviceStatusBlock)deviceStatus;

/**
 查询升级设备信息列表

 @param completionHandler 数据回调
 */
- (void)loadOTAUpgradeDeviceList:(deviceUpgradeListBlock)completionHandler;

/**
 查询正在升级的设备信息列表
 
 @param completionHandler 数据回调
 */
- (void)loadOTAIsUpgradingDeviceList:(deviceUpgradeListBlock)completionHandler;

/**
 wifi设备升级固件
 
 @param iotIds 设备id
 @param completionHandler 升级回调
 */
- (void)upgradeWifiDeviceFirmware:(NSArray<NSString *> *)iotIds completionHandler:(wifiDeviceUpgradeBlock)completionHandler;

/**
 查询设备固件信息、升级进度

 @param iotId 设备id
 @param completionHandler 升级进度回调
 */
- (void)loadOTAFirmwareDetailAndUpgradeStatus:(NSString *)iotId
                            completionHandler:(deviceUpgradeStatusBlock)completionHandler;

/**
 通过iotId查询产品信息（netType）

 @param iotId 设备id
 @param completionHandler 查询结果回调
 */
- (void)queryProductsInfoWithIotId:(NSString *)iotId
                completionHandler:(queryProductsInfoBlock)completionHandler;

@end

NS_ASSUME_NONNULL_END
