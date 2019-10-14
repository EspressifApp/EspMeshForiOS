//
//  IMSTmallSpeakerApi.m
//  ESPAliyunDemo
//
//  Created by fanbaoying on 2019/9/27.
//  Copyright © 2019 fby. All rights reserved.
//

#import "IMSTmallSpeakerApi.h"

#import <IMSApiClient/IMSApiClient.h>
#import <IMSAuthentication/IMSAuthentication.h>
#import <IMSAccount/IMSAccountService.h>

@implementation IMSTmallSpeakerApi


// 用户绑定淘宝Id
+ (void)bindTaobaoIdWithParams:(NSDictionary *)para
                    completion:(void (^)(NSError *error, NSDictionary *info))completion {
    [self requestTmallSpeakerApi:@"/account/taobao/bind" version:@"1.0.5" params:para completion:completion];
}

// 封装的请求类，依赖请求类#import <IMSApiClient/IMSApiClient.h>
+ (void)requestTmallSpeakerApi:(NSString *)api
                       version:(NSString *)ver
                        params:(NSDictionary *)para
                    completion:(void (^)(NSError *, id))completion {
    
    IMSIoTRequestBuilder *builder = [[IMSIoTRequestBuilder alloc] initWithPath:api
                                                                    apiVersion:ver
                                                                        params:para];
    [builder setScheme:@"https"];
    
    IMSRequest *request = [[builder setAuthenticationType:IMSAuthenticationTypeIoT] build];
    [IMSRequestClient asyncSendRequest:request responseHandler:^(NSError * _Nullable error, IMSResponse * _Nullable response) {
        if (completion) {
            //返回请求过期后，需要重新登录；重新登录后重新初始化主框架，不需要重新请求
            if (response.code == 401) {
                if (NSClassFromString(@"IMSAccountService") != nil) {
                    // 先退出登录
                    if ([[IMSAccountService sharedService] isLogin]) {
                        [[IMSAccountService sharedService] logout];
                    }
                    return;
                }
            }
            
            if (!error && response.code == 200) {
                completion(error, response.data);
                return ;
            }
            
            NSError *bError = [NSError errorWithDomain:NSURLErrorDomain
                                                  code:response.code
                                              userInfo:@{NSLocalizedDescriptionKey: response.localizedMsg ? : @"服务器应答错误"}];
            completion(bError, nil);
            return;
        }
    }];
}

// 用户解绑淘宝Id
+ (void)unbindTaobaoIdWithParams:(NSDictionary *)para
                      completion:(void (^)(NSError *error, NSDictionary *info))completion {
    [self requestTmallSpeakerApi:@"/account/thirdparty/unbind" version:@"1.0.5" params:para completion:completion];
}

// 查询用户绑定的淘宝Id
+ (void)getTaobaoIdWithParams:(NSDictionary *)para
                   completion:(void (^)(NSError *error, NSDictionary *info))completion {
    [self requestTmallSpeakerApi:@"/account/thirdparty/get" version:@"1.0.5" params:para completion:completion];
}

@end
