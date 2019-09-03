//
//  ESPAliyunSDKInit.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/7/26.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import "ESPAliyunSDKInit.h"

// 日志初始化
#import <IMSLog/IMSLog.h>

//API通道
#import <IMSApiClient/IMSApiClient.h>
#import <AlinkAppExpress/LKAppExpress.h>

//账号及用户
#import <IMSApiClient/IMSConfiguration.h>
#import <ALBBOpenAccountCloud/ALBBOpenAccountSDK.h>

//身份认证
#import <IMSAccount/IMSAccountService.h>
#import <IMSAuthentication/IMSAuthentication.h>

//BoneMobile 容器 SDK
#import <IMSBoneKit/IMSBoneConfiguration.h>

// 设备
#import <IMSThingCapability/IMSThingCapability.h>

#import "IMSOpenAccount.h"

static NSString *const kIMSMobileChannelLaunchLogTag = @"MobileChannelDemo";
NSString * _Nonnull const IMSNotificationAccountLogin1 = @"IMSNotificationAccountLogin";
NSString * _Nonnull const IMSNotificationAccountLogout1 = @"IMSNotificationAccountLogout";
@interface ESPAliyunSDKInit () <LKAppExpConnectListener, IMSAccountProtocol>


@end

@implementation ESPAliyunSDKInit

- (void)LongLinksHandleToolInit {
    [self logInit];
    [self apiInit];
    [self longLinksInit];
    // 设备
    [self deviceinit];
//    [self userInit];
    [self identityInit];
    [self BoneMobileInit];
    
}

- (void)deviceinit {
    [kIMSThingManager startLocalAcceleration]; //初始化只需要添加此一行代码即可，此处会启动
    // 本地通信加速能力.
    // 当不再需要使用本地通信能力时，可调用下边接口停止
    // [kIMSThingManager stopLocalAcceleration];
}

//BoneMobile 容器 初始化
- (void)BoneMobileInit {
    IMSBoneConfiguration *configuration = [IMSBoneConfiguration sharedInstance];
    configuration.pluginEnvironment = IMSBonePluginEnvironmentRelease;
    // 设置
    [configuration set:@"region" value:@"china"];
}

// 长连接通道和账号及用户初始化
- (void)longLinksInit {
    IMSConfiguration *imsconfig = [IMSConfiguration sharedInstance];
    LKAEConnectConfig * config = [LKAEConnectConfig new];
    NSLog(@"appKey:%@",imsconfig.appKey);
    NSLog(@"authCode:%@",imsconfig.authCode);
    config.appKey = imsconfig.appKey;
    config.authCode = imsconfig.authCode;
    // 指定长连接服务器地址。 （默认不填，SDK会使用默认的地址及端口。默认为国内华东节点。不要带 "协议://"，如果置为空，底层通道会使用默认的地址）
    config.server = @"";
    // 开启动态选择Host功能。 (默认 NO，海外环境请设置为 YES。此功能前提为 config.server 不特殊指定。）
    config.autoSelectChannelHost = NO;
    [[LKAppExpress sharedInstance]startConnect:config connectListener:self];// self 需要实现 LKAppExpConnectListener 接口
}

// 日志初始化
- (void)logInit {
    //统一设置所有模块的日志 tag 输出级别
    [IMSLog setAllTagsLevel:IMSLogLevelAll];
    //可选：设置是否开启日志的控制台输出，建议在release版本中不要开启。
    [IMSLog showInConsole:NO];
}

// API通道初始化
- (void)apiInit {
    // 设置安全图片authCode
    [IMSConfiguration initWithHost:@"api.link.aliyun.com" serverEnv:IMSServerRelease];
}

// 初始化账号和用户
- (void)userInit {
    IMSConfiguration *conf = [IMSConfiguration sharedInstance];
    ALBBOpenAccountSDK *accountSDK = [ALBBOpenAccountSDK sharedInstance];
    [accountSDK setSecGuardImagePostfix:conf.authCode];
    // 设置账号服务器环境，默认为线上环境
    [accountSDK setTaeSDKEnvironment:TaeSDKEnvironmentRelease];
    // 设置账号服务器域名；如果是线上环境，可以不设置域名；
    [[ALBBOpenAccountSDK sharedInstance] setGwHost:@"sdk.openaccount.aliyun.com"];
    //如果需要切换到海外环境，请执行下面setDefaultOAHost方法，默认为大陆环境
    //[[ALBBOpenAccountSDK sharedInstance] setGwHost:@"sgp-sdk.openaccount.aliyun.com"];
    // 打开调试日志
    //    [[ALBBOpenAccountSDK sharedInstance] setDebugLogOpen:YES];
    // 初始化
    [accountSDK asyncInit:^{
        //        [self message:@"初始化成功"];
        //        [self showMessage:@"初始化成功"];
        NSLog(@"初始化成功");
        // 初始化成功
    } failure:^(NSError *error) {
        NSLog(@"初始化失败");
        // 初始化失败
    }];
}

//身份认证初始化
- (void)identityInit {
    IMSAccountService *accountService = [IMSAccountService sharedService];
    IMSOpenAccount *openAccount = [IMSOpenAccount sharedInstance];
    accountService.sessionProvider = openAccount;
    accountService.accountProvider = openAccount;
    // sessionProvider 需要开发者实现遵守IMSAccountProtocol协议的class 实例
//    accountService.sessionProvider = self;
    [IMSCredentialManager initWithAccountProtocol:accountService.sessionProvider];
    IMSIoTAuthentication *iotAuthDelegate = [[IMSIoTAuthentication alloc] initWithCredentialManager:IMSCredentialManager.sharedManager];
    [IMSRequestClient registerDelegate:iotAuthDelegate forAuthenticationType:IMSAuthenticationTypeIoT];
}

- (void)onConnectState:(LKAppExpConnectState)state {
    switch (state) {
        case LKAppExpConnectStateConnected: {
            IMSLogDebug(kIMSMobileChannelLaunchLogTag, @"已连接");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"IMSMobileChannelConnectedSussess" object:nil userInfo:nil];
            });
            break;
        }
        case LKAppExpConnectStateDisconnected: {
            IMSLogDebug(kIMSMobileChannelLaunchLogTag, @"已断连");
            break;
        }
        case LKAppExpConnectStateConnecting: {
            IMSLogDebug(kIMSMobileChannelLaunchLogTag, @"开始建联");
            break;
        }
        default:
            break;
    }
}

- (NSString *)accountDidLoginSuccessNotificationName {
    return IMSNotificationAccountLogin1;
}

- (NSString *)accountDidLogoutSuccessNotificationName {
    return IMSNotificationAccountLogout1;
}

- (NSString *)accountType {
    return @"OA_SESSION";
}

- (NSDictionary *)currentSession {
    NSMutableDictionary *info = [@{} mutableCopy];
    
    ALBBOpenAccountSession *session = [ALBBOpenAccountSession sharedInstance];
    if ([session isLogin]) {
        [info addEntriesFromDictionary:@{
                                         ACCOUNT_SESSION_KEY: session.sessionID ? :@"",
                                         }];
        
        ALBBOpenAccountUser *user = [ALBBOpenAccountSession sharedInstance].getUser;
        NSString *nickName = user.displayName;
        if (!nickName || [nickName length] == 0) {
            nickName = user.mobile;
        }
        [info addEntriesFromDictionary:@{
                                         ACCOUNT_USER_ID_KEY: user.accountId ? :@"",
                                         ACCOUNT_NICKNAME_KEY: nickName ? :@"",
                                         ACCOUNT_AVATAR_URL_KEY: user.avatarUrl ? :@"",
                                         }];
    }
    
    return info;
}

- (BOOL)isLogin {
    return [[ALBBOpenAccountSession sharedInstance] isLogin];
}

- (void)logout {
    [[NSNotificationCenter defaultCenter] postNotificationName:IMSNotificationAccountLogout1 object:nil];
    return [[ALBBOpenAccountSession sharedInstance] logout];
}

- (NSString *)token {
    return [ALBBOpenAccountSession sharedInstance].sessionID;
}

@end
