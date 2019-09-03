//
//  IMSLifeClient.m
//  AlinkAppExpress
//
//  Created by Hager Hu on 11/01/2018.
//

#import "IMSLifeClient.h"

//#import "IMSLifeLog.h"

#import <IMSApiClient/IMSApiClient.h>
#import <IMSAuthentication/IMSAuthentication.h>

NSString *ServerErrorDomain = @"ServerErrorDomain";


@implementation IMSLifeClient

+ (instancetype)sharedClient {
    static IMSLifeClient *client = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[[self class] alloc] init];
    });
    
    return client;
}


- (id)init {
    if (self = [super init]) {
//        [IMSLog registerTag:LOGTAG_LIFE];
    }
    
    return self;
}


#pragma mark - 虚拟设备

- (void)createVirtualDeviceWithProductKey:(NSString *)key
                        completionHandler:(void (^)(NSDictionary *info, NSError *error))completionHandler {
    NSString *path = @"/thing/virtual/register";
    NSString *version = @"1.0.0";
    
    NSDictionary *params = @{
                             @"productKey": key ? :@"",
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(data, error);
            }
        }];
}


- (void)bindVirtualDeviceWithKey:(NSString *)key
                      deviceName:(NSString *)name
                completionHandler:(void (^)(NSError *error))completionHandler {
    NSString *path = @"/thing/virtual/binduser";
    NSString *version = @"1.0.0";
    
    NSDictionary *params = @{
                             @"productKey": key ? : @"",
                             @"deviceName": name ? : @"",
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(error);
            }
        }];
}


#pragma mark - 添加设备

- (void)queryProductInfoWithKey:(NSString *)key
              completionHandler:(void (^)(NSDictionary *info, NSError *error))completionHandler {
    NSString *path = @"/thing/detailInfo/queryProductInfo";
    NSString *version = @"1.1.1";
    
    NSDictionary *params = @{
                             @"productKey": key ? :@"",
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(data, error);
            }
        }];
}


- (void)bindWifiDeviceWithProductKey:(NSString *)key
                          deviceName:(NSString *)name
                               token:(NSString *)token
                   completionHandler:(void (^)(NSString *iotId, NSError *error))completionHandler {
    NSString *path = @"/awss/enrollee/user/bind";
    NSString *version = @"1.0.2";
    
    NSDictionary *params = @{
                             @"productKey" : key ? : @"",
                             @"deviceName": name ? : @"",
                             @"token": token ? : @"",
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(data, error);
            }
        }];
}


- (void)bindGPRSDeviceWithProductKey:(NSString *)key
                          deviceName:(NSString *)name
                   completionHandler:(void (^)(NSString *iotId, NSError *error))completionHandler {
    NSString *path = @"/awss/gprs/user/bind";
    NSString *version = @"1.0.2";
    
    NSDictionary *params = @{
                             @"productKey" : key ? : @"",
                             @"deviceName": name ? : @"",
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(data, error);
            }
        }];
}

- (void)bindZIGBEEDeviceWithProductKey:(NSString *)key
                            deviceName:(NSString *)name
                     completionHandler:(void (^)(NSString *iotId, NSError *error))completionHandler {
    NSString *path = @"/awss/subdevice/bind";
    NSString *version = @"1.0.2";
    
    NSDictionary *params = @{
                             @"productKey" : key ?: @"",
                             @"deviceName" : name ?: @"",
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(data, error);
            }
        }];
}

- (void)bindBTDeviceWithProductKey:(NSString *)key
                        deviceName:(NSString *)name
                 completionHandler:(void (^)(NSString *iotId, NSError *error))completionHandler {
    NSString *path = @"/awss/time/window/user/bind";
    NSString *version = @"1.0.3";
    
    NSDictionary *params = @{
                             @"productKey" : key ?: @"",
                             @"deviceName" : name ?: @"",
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(data, error);
            }
        }];
}

#pragma mark -

- (void)loadUserDeviceListWithCompletionHandler:(void (^)(NSArray *list, NSError *error))completionHandler {
    NSString *path = @"/uc/listBindingByAccount";
    NSString *version = @"1.0.2";
    NSDictionary *params = @{@"pageNo":@1,
                             @"pageSize":@100
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler([data objectForKey:@"data"], error);
            }
        }];
}


- (void)loadVirtualDeviceListWithCompletionHandler:(void (^)(NSArray *list, NSError *error))completionHandler {
    NSString *path = @"/uc/listBindingByAccount";
    NSString *version = @"1.0.2";
    NSDictionary *params = @{
                             @"thingType": @"VIRTUAL",
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler([data objectForKey:@"data"], error);
            }
        }];
}


- (void)loadSupportProductListWithCompletionHandler:(void (^)(NSArray *list, NSError *error))completionHandler {
    NSString *path = @"/thing/productInfo/getByAppKey";
    NSString *version = @"1.1.1";
    
    NSDictionary *params = @{};
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(data, error);
            }
        }];
}


- (void)queryNetTypeWithProductKey:(NSString *)key
                 completionHandler:(void (^)(NSString *type, NSError *error))completionHandler {
    NSString *path = @"/thing/detailInfo/queryProductInfoByProductKey";
    NSString *version = @"1.1.2";
    
    NSDictionary *params = @{
                             @"productKey": key ? :@"",
                             };
    
    [self requestWithPath:path version:version params:params completionHandler:^(NSError *error, id data) {
        if (completionHandler) {
            NSString *netType = @"";
            if ([data isKindOfClass:[NSDictionary class]]) {
                netType = data[@"netType"];
            }
            
            completionHandler(netType, error);
        }
    }];
}


#pragma mark -

- (void)bindAPNSChannelWithDeviceId:(NSString *)deviceId
                  completionHandler:(void (^)(NSError *error))completionHandler {
    NSString *path = @"/uc/bindPushChannel";
    NSString *version = @"1.0.2";
    NSDictionary *params = @{
                             @"deviceId": deviceId ? : @"",
                             @"deviceType": @"iOS",
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(error);
            }
        }];
}


- (void)unbindAPNSChannelWithDeviceId:(NSString *)deviceId
                    completionHandler:(void (^)(NSError *error))completionHandler {
    NSString *path = @"/uc/unbindPushChannel";
    NSString *version = @"1.0.0";
    NSDictionary *params = @{
                             @"deviceId": deviceId ? : @"",
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(error);
            }
    }];
}


#pragma mark - LampPanel(灯具面板)

- (void)lampPanelBaseInfoRequestWithIotId:(NSString *)iotId
                        completionHandler:(void (^)(NSError *error, NSDictionary *data))completionHandler {
    NSString *path = @"/thing/info/get";
    NSString *version = @"1.0.2";
    NSDictionary *params = @{@"iotId":iotId};
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(error,data);
            }
        }];
}

- (void)lampPanelAttributeInfoRequestWithIotId:(NSString *)iotId
                             completionHandler:(void (^)(NSError *error, NSDictionary *data))completionHandler {
    NSString *path = @"/thing/properties/get";
    NSString *version = @"1.0.2";
    NSDictionary *params = @{@"iotId":iotId};
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(error,data);
            }
    }];
}


- (void)setLampPanelAttributeWithIotId:(NSString *)iotId
                                    items:(NSDictionary *)items
                        completionHandler:(void (^)(NSError *error, NSDictionary *data))completionHandler; {
    NSString *path = @"/thing/properties/set";
    NSString *version = @"1.0.2";
    NSDictionary *params = @{@"iotId":iotId,
                             @"items":items
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(error,data);
            }
        }];
}

- (void)invokeLampPanelSrviceWithIotId:(NSString *)iotId
                                  args:(NSInteger)switchVaule
                     completionHandler:(void (^)(NSError *error))completionHandler {
    NSString *path = @"/thing/service/invoke";
    NSString *version = @"1.0.0";
    NSDictionary *params = @{@"iotId":iotId,
                             @"identifier":@"reverseSwitch",
                             @"args":@{@"arg1":@(switchVaule)}
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(error);
            }
        }];
}

- (void)setDeviceNickNameWithIotId:(NSString *)iotId
                          nickName:(NSString *)nickName
                 completionHandler:(void (^)(NSError *error))completionHandler {
    NSString *path = @"/uc/setDeviceNickName";
    NSString *version = @"1.0.2";
    NSDictionary *params = @{@"iotId":iotId,
                             @"nickName":nickName
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(error);
            }
        }];
}

- (void)unbindDeviceWithIotId:(NSString *)iotId
            completionHandler:(void (^)(NSError *error))completionHandler {
    NSString *path = @"/uc/unbindAccountAndDev";
    NSString *version = @"1.0.2";
    NSDictionary *params = @{@"iotId":iotId};
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(error);
            }
        }];
}

#pragma mark -

- (void)requestWithPath:(NSString *)path
                version:(NSString *)version
                 params:(NSDictionary *)params
      completionHandler:(void (^)(NSError *error, id data))completionHandler {
    IMSIoTRequestBuilder *builder = [[IMSIoTRequestBuilder alloc] initWithPath:path apiVersion:version params:params];
    [builder setScheme:@"https://"];
    IMSRequest *request = [[builder setAuthenticationType:IMSAuthenticationTypeIoT] build];

    NSLog(@"Request: %@",request);
//    IMSLifeLogVerbose(@"Request: %@", request);
    [IMSRequestClient asyncSendRequest:request responseHandler:^(NSError *error, IMSResponse *response) {
//        IMSLifeLogVerbose(@"Request: %@\nError:%@\nResponse: %d %@", request, error, response.code, response.data);
        NSLog(@"请求返回结果: %@\nError:%@\nResponse: %ld %@", request, error, (long)response.code, response.data);
        if (error == nil && response.code != 200) {
            NSDictionary *info = @{
                                   @"message" : response.message ? : @"",
                                   NSLocalizedDescriptionKey : response.localizedMsg ? : @"",
                                   };
            error = [NSError errorWithDomain:ServerErrorDomain code:response.code userInfo:info];
        }

        if (completionHandler) {
            completionHandler(error, response.data);
        }
    }];
}


@end
