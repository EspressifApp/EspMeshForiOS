//
//  ESPFBYAliyunAPI.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/9/3.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import "ESPFBYAliyunAPI.h"
@interface ESPFBYAliyunAPI ()<AliyunNativeApisProtocol>{
    
}
@property (strong, nonatomic)UIViewController *aliyunViewController;
@end

@implementation ESPFBYAliyunAPI
//单例模式
+ (instancetype)share {
    static ESPFBYAliyunAPI *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[ESPFBYAliyunAPI alloc]init];
    });
    return share;
}

- (JSContext *)getAliyunJSContext:(JSContext *)context withAliyunVC:(UIViewController *)aliyunVC {
    self.aliyunViewController = aliyunVC;
    context[@"aliyun"] = self;
    return context;
}
//用户是否登录
- (void)isAliUserLogin {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL isLogin = [[ESPAliyunSDKUse sharedClient] isAliyunLogin];
        NSString *paramjson=[ESPDataConversion jsonFromObject:@{@"isLogin":@(isLogin)}];
        [self.delegate sendAliyunMsg:@"onIsAliUserLogin" param:paramjson];
    });
}
//用户登录信息
- (void)getAliUserInfo {
    // 获取当前会话
    ALBBOpenAccountSession *session = [ALBBOpenAccountSession sharedInstance];
    if ([session isLogin]) {
        // 获取用户信息
        ALBBOpenAccountUser *user = session.getUser;
        NSString* paramjson = [NSString stringWithFormat:@"%@",user];
        [self.delegate sendAliyunMsg:@"onGetAliUserInfo" param:paramjson];
    }else {
        [self.delegate sendAliyunMsg:@"onGetAliUserInfo" param:@"账号未登录"];
    }
}
//用户登出
- (void)aliUserLogout {
    [[ESPAliyunSDKUse sharedClient] aliyunLogout];
}
//用户登录
- (void)aliUserLogin {
    [[ESPAliyunSDKUse sharedClient] aliyunPresentLogin:_aliyunViewController andSuccess:^(ALBBOpenAccountUser * _Nonnull dic) {
        NSString* paramjson = [NSString stringWithFormat:@"%@",dic];
        if ([dic mobile]!=nil){
            NSString* username = [dic mobile];
            [ESPFBYDataBase espDataBaseInit:username];
        }
        [self.delegate sendAliyunMsg:@"onAliUserLogin" param:paramjson];
    } andFailure:^(NSString * _Nonnull errorMsg) {
        [self.delegate sendAliyunMsg:@"onAliUserLogin" param:errorMsg];
    }];
}

// 获取阿里云绑定设备列表
- (void)getAliDeviceList {
    [[ESPAliyunSDKUse sharedClient] getAliyunDeviceList:^(NSDictionary * _Nonnull resultdeviceDic) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:resultdeviceDic];
        [self.delegate sendAliyunMsg:@"onGetAliDeviceList" param:json];
    }];
}
// 发现本地的已配网设备
- (void)aliStartDiscovery {
    [[ESPAliyunSDKUse sharedClient] startDiscoveryDevicewithType:0 withBlock:^(NSArray * _Nonnull devices) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:devices];
        [self.delegate sendAliyunMsg:@"onAliStartDiscovery" param:json];
    }];
}
// 停止扫描设备
- (void)aliStopDiscovery {
    [[ESPAliyunSDKUse sharedClient] aliStopDiscoveryDevice];
}
//设备绑定
- (void)aliDeviceBinding:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    [[ESPAliyunSDKUse sharedClient] aliDeviceBinding:msg andSuccess:^(NSDictionary * _Nonnull resultIotid) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:resultIotid];
        [self.delegate sendAliyunMsg:@"onAliDeviceBind" param:json];
    } andFailure:^(NSDictionary * _Nonnull errorMsg) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:errorMsg];
        [self.delegate sendAliyunMsg:@"onAliDeviceBind" param:json];
    }];
}
// 设备解绑
- (void)aliDeviceUnbindRequest:(NSString *)message {
    [[ESPAliyunSDKUse sharedClient] unbindDeviceRequest:message andBlock:^(NSArray * _Nonnull unbindResultArr) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:unbindResultArr];
        [self.delegate sendAliyunMsg:@"onAliDeviceUnbind" param:json];
    }];
}
// 获取设备状态
- (void)getAliDeviceStatus:(NSString *)message {
    [[ESPAliyunSDKUse sharedClient] getAliyunDeviceStatus:message andSuccess:^(NSArray * _Nonnull resultStatusArr) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:resultStatusArr];
        [self.delegate sendAliyunMsg:@"onGetAliDeviceStatus" param:json];
    }];
}
// 获取设备属性
- (void)getAliDeviceProperties:(NSString *)message {
    [[ESPAliyunSDKUse sharedClient] getAliyunDeviceProperties:message andSuccess:^(NSArray * _Nonnull resultStatusArr) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:resultStatusArr];
        [self.delegate sendAliyunMsg:@"onGetAliDeviceProperties" param:json];
    }];
}
// 修改设备属性
- (void)setAliDeviceProperties:(NSString *)message {
    [[ESPAliyunSDKUse sharedClient] setAliyunDeviceProperties:message andSuccess:^(NSArray * _Nonnull resultStatusArr) {
        NSLog(@"setAliDeviceProperties ---> %@",resultStatusArr);
        //        NSString* json=[ESPDataConversion jsonConfigureFromObject:resultStatusArr];
        //        [self sendAliyunMsg:@"onGetAliDeviceProperties" param:json];
    }];
}
// 获取升级设备信息列表
- (void)getAliOTAUpgradeDeviceList {
    BOOL isLogin = [[ESPAliyunSDKUse sharedClient] isAliyunLogin];
    if (isLogin) {
        [[ESPAliyunSDKUse sharedClient] loadOTAUpgradeDeviceList:^(NSDictionary * _Nonnull deviceListResult) {
            NSString* json=[ESPDataConversion jsonConfigureFromObject:deviceListResult];
            [self.delegate sendAliyunMsg:@"onGetAliOTAUpgradeDeviceList" param:json];
        }];
    }else {
        NSLog(@"用户未登录");
    }
}
// 获取正在升级的设备信息列表
- (void)getAliOTAIsUpgradingDeviceList {
    [[ESPAliyunSDKUse sharedClient] loadOTAIsUpgradingDeviceList:^(NSDictionary * _Nonnull deviceListResult) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:deviceListResult];
        [self.delegate sendAliyunMsg:@"onGetAliOTAIsUpgradingDeviceList" param:json];
    }];
}
// 升级Wi-Fi设备
- (void)aliUpgradeWifiDevice:(NSString *)message {
    NSArray *msg=[ESPDataConversion objectFromJsonString:message];
    [[ESPAliyunSDKUse sharedClient] upgradeWifiDeviceFirmware:msg completionHandler:^(NSDictionary * _Nonnull upgradeResult) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:upgradeResult];
        [self.delegate sendAliyunMsg:@"onAliUpgradeWifiDevice" param:json];
    }];
}

// 查询设备固件信息、升级进度
- (void)aliQueryDeviceUpgradeStatus:(NSString *)message {
    [[ESPAliyunSDKUse sharedClient] loadOTAFirmwareDetailAndUpgradeStatus:message completionHandler:^(NSDictionary * _Nonnull deviceStatusResult) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:deviceStatusResult];
        [self.delegate sendAliyunMsg:@"onAliQueryDeviceUpgradeStatus" param:json];
    }];
}
@end
