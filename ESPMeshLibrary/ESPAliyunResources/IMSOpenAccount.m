//
//  IMSOpenAccount.m
//  IMSAccount
//
//  Created by Hager Hu on 01/11/2017.
//

#import "IMSOpenAccount.h"

#import <ALBBOpenAccountCloud/ALBBOpenAccountSDK.h>
#import <ALBBOpenAccountCloud/ALBBOpenAccountUser.h>

#import <IMSApiClient/IMSConfiguration.h>
#import <IMSAccount/IMSAccountService.h>

NSString * _Nonnull const IMSNotificationAccountLogin = @"IMSNotificationAccountLogin";
NSString * _Nonnull const IMSNotificationAccountLogout = @"IMSNotificationAccountLogout";

@implementation IMSOpenAccount

#pragma mark - IMSAccountProtocol

+ (instancetype)sharedInstance {
    static IMSOpenAccount *account;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        account = [[[self class] alloc] init];
    });
    
    return account;
}

- (id)init {
    if (self = [super init]) {
        IMSConfiguration *configuration = [IMSConfiguration sharedInstance];
        NSLog(@"%@ = = %@",configuration.authCode, configuration.appKey);
        //设置安全图片
        [[ALBBOpenAccountSDK sharedInstance] setSecGuardImagePostfix:configuration.authCode];
        //设置环境
        TaeSDKEnvironment taeEnv = TaeSDKEnvironmentRelease;
        if (configuration.serverEnv == IMSServerDaily) {
            taeEnv = TaeSDKEnvironmentDaily;
            [[ALBBOpenAccountSDK sharedInstance] setGwHost:@"sdk.openaccount.aliyun.com"];
        } else if (configuration.serverEnv == IMSServerPreRelease) {
            taeEnv = TaeSDKEnvironmentPreRelease;
        }
        //IMSAccountLogInfo(@"IMSConfiguration env:%d Account env:%d", configuration.serverEnv, taeEnv);
        [[ALBBOpenAccountSDK sharedInstance] setTaeSDKEnvironment:taeEnv];
        // 与 @一宵 沟通，不存在初始化失败的情况，所以不需要抛到外层处理
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [[ALBBOpenAccountSDK sharedInstance] asyncInit:^{
            //IMSAccountLogInfo(@"accountSDK success");
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            //IMSAccountLogInfo(@"accountSDK error:%@", error);
            dispatch_semaphore_signal(semaphore);
        }];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    return self;
}

- (NSString *)accountDidLoginSuccessNotificationName {
    return IMSNotificationAccountLogin;
}

- (NSString *)accountDidLogoutSuccessNotificationName {
    return IMSNotificationAccountLogout;
}

- (NSString *)accountType {
    return @"OA_SESSION";
}

- (NSString *)token {
    return [ALBBOpenAccountSession sharedInstance].sessionID;
}

- (BOOL)isLogin {
    return [[ALBBOpenAccountSession sharedInstance] isLogin];
}

- (void)logout {
    [[NSNotificationCenter defaultCenter] postNotificationName:IMSNotificationAccountLogout object:nil];
    return [[ALBBOpenAccountSession sharedInstance] logout];
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

#pragma mark - IMSAccountUIProtocol

- (void)showLoginWithController:(UIViewController *)controller
                        success:(void (^)(NSDictionary *))success
                        failure:(void (^)(NSError *))failure {
    
    //被挤号，客户端不做解绑等操作，这里不加IMS退出登录通知，单纯退出即可
    [self logout];
}


#pragma mark - CustomUI

@end
