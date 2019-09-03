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
typedef void(^deviceListBlock)(NSDictionary *resultdeviceDic);

typedef void(^startDiscoveryDevices)(NSArray * devices);
@property (nonatomic, copy)startDiscoveryDevices startDiscoveryDevicesBlock;

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
- (void)aliStartDiscoveryDevice:(startDiscoveryDevices)didFoundBlock;

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
- (void)unbindDeviceRequest:(NSString *)deviceIotId;

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

@end

NS_ASSUME_NONNULL_END
