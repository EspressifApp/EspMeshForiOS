//
//  ESPFBYAliyunAPI.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/9/3.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "ESPAliyunSDKUse.h"
#import "ESPDataConversion.h"
#import "ESPFBYDataBase.h"

NS_ASSUME_NONNULL_BEGIN
@protocol ESPFBYAliyunAPIDelegate <NSObject>

-(void)sendAliyunMsg:(NSString*)methodName param:(id)params;

@end

@protocol AliyunNativeApisProtocol <JSExport>
//用户是否登录
- (void)isAliUserLogin;
//用户登录信息
- (void)getAliUserInfo;
//用户登出
- (void)aliUserLogout;
//用户登录
- (void)aliUserLogin;
// 获取阿里云绑定设备列表
- (void)getAliDeviceList;
// 发现本地的已配网设备，或者已配网设备、路由器发现的待配设备。发现的待配设备信息可以作为后续设备配网的入参信息
- (void)aliStartDiscovery;
// 停止扫描设备
- (void)aliStopDiscovery;
// 设备绑定
- (void)aliDeviceBinding:(NSString *)message;
// 设备解绑
- (void)aliDeviceUnbindRequest:(NSString *)message;
// 获取设备状态
- (void)getAliDeviceStatus:(NSString *)message;
// 获取设备属性
- (void)getAliDeviceProperties:(NSString *)message;
// 修改设备属性
- (void)setAliDeviceProperties:(NSString *)message;
// 获取升级设备信息列表
- (void)getAliOTAUpgradeDeviceList;
// 获取正在升级的设备信息列表
- (void)getAliOTAIsUpgradingDeviceList;
// 升级Wi-Fi设备
- (void)aliUpgradeWifiDevice:(NSString *)message;
// 查询设备固件信息、升级进度
- (void)aliQueryDeviceUpgradeStatus:(NSString *)message;
// 用户绑定淘宝Id
- (void)aliUserBindTaobaoId;
// 查询用户绑定的淘宝Id
- (void)getAliUserId:(NSString *)message;
// 用户解绑淘宝Id
- (void)aliUserUnbindId:(NSString *)message;
@end

@interface ESPFBYAliyunAPI : NSObject

@property (weak, nonatomic)id<ESPFBYAliyunAPIDelegate> delegate;

/**
 * 单例构造方法
 * @return ESPFBYLocalAPI共享实例
 */
+ (instancetype)share;

- (JSContext *)getAliyunJSContext:(JSContext *)context withAliyunVC:(UIViewController *)aliyunVC;

@end

NS_ASSUME_NONNULL_END
