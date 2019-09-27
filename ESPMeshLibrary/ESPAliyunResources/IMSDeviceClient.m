//
//  IMSDeviceClient.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/9/9.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import "IMSDeviceClient.h"
#import <IMSApiClient/IMSApiClient.h>
#import <IMSAuthentication/IMSAuthentication.h>

NSString *const IMSDeviceServerErrorDomain = @"ServerErrorDomain";

@implementation IMSDeviceClient

+ (instancetype)sharedClient {
    static IMSDeviceClient *client = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[[self class] alloc] init];
    });
    
    return client;
}


- (id)init {
    if (self = [super init]) {
//        [IMSLog registerTag:LOGTAG_DEVICE];
    }
    
    return self;
}

#pragma mark -

- (void)requestWithPath:(NSString *)path
                version:(NSString *)version
                 params:(NSDictionary *)params
      completionHandler:(void (^)(NSError *error, id data))completionHandler {
    IMSIoTRequestBuilder *builder = [[IMSIoTRequestBuilder alloc] initWithPath:path apiVersion:version params:params];
    IMSRequest *request = [[builder setAuthenticationType:IMSAuthenticationTypeIoT] build];
    
    NSLog(@"Request: %@", request);
    [IMSRequestClient asyncSendRequest:request responseHandler:^(NSError *error, IMSResponse *response) {
        NSLog(@"Request: %@\nError:%@\nResponse: %ld %@", request, error, (long)response.code, response.data);
        if (error == nil && response.code != 200) {
            NSDictionary *info = @{
                                   @"message" : response.message ? : @"",
                                   NSLocalizedDescriptionKey : response.localizedMsg ? : @"",
                                   };
            error = [NSError errorWithDomain:IMSDeviceServerErrorDomain code:response.code userInfo:info];
        } else if (error) {
            NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
            NSString *localizedDesc;
            switch (underlyingError.code) {
                case kCFURLErrorTimedOut:
                    localizedDesc = @"网络请求超时";
                    break;
                case kCFURLErrorNotConnectedToInternet:
                    localizedDesc = @"网络错误";
                    break;
                case kCFURLErrorBadServerResponse:
                    localizedDesc = @"服务异常";
                    break;
                default:
                    break;
            }
            
            if (localizedDesc.length > 0) {
                NSDictionary *info = @{
                                       NSLocalizedDescriptionKey : localizedDesc ? : [NSNull null]
                                       };
                error = [NSError errorWithDomain:IMSDeviceServerErrorDomain code:underlyingError.code userInfo:info];
            } else {
                NSDictionary *info = @{
                                       @"message" : response.message ? : @"",
                                       NSLocalizedDescriptionKey : response.localizedMsg.length > 0 ? response.localizedMsg : @"服务端未返回错误信息",
                                       @"rawData" : response ? : [NSNull null]
                                       };
                error = [NSError errorWithDomain:IMSDeviceServerErrorDomain code:response.code userInfo:info];
            }
        }
        
        if (completionHandler) {
            completionHandler(error, response.data);
        }
    }];
}

- (void)loadOTAUpgradeDeviceList:(void (^)(id data, NSError *error))completionHandler {
    NSString *path = @"/thing/ota/listByUser";
    NSString *version = @"1.0.2";
    
    NSDictionary *params = @{
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                if (error) {
                    completionHandler(nil, error);
                } else {
//                    NSArray *list = [MTLJSONAdapter modelsOfClass:[IMSOTAUpgradeDeviceInfoModel class] fromJSONArray:data error:&error];
                    completionHandler(data, nil);
                }
            }
        }];
}

- (void)loadOTAIsUpgradingDeviceList:(void (^)(id data, NSError *error))completionHandler {
    NSString *path = @"/thing/ota/upgrade/listByUser";
    NSString *version = @"1.0.2";
    
    NSDictionary *params = @{
                             };
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                if (error) {
                    completionHandler(nil, error);
                } else {
                    //                    NSArray *list = [MTLJSONAdapter modelsOfClass:[IMSOTAUpgradeDeviceInfoModel class] fromJSONArray:data error:&error];
                    completionHandler(data, nil);
                }
            }
        }];
}

- (void)loadOTAFirmwareDetailAndUpgradeStatusWithIotId:(NSString *)iotId
                                     completionHandler:(void (^)(id data, NSError *error))completionHandler {
    NSString *path = @"/thing/ota/info/progress/getByUser";
    NSString *version = @"1.0.2";
    
    NSDictionary *params = @{@"iotId": iotId ?: @""};
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                if (error) {
                    completionHandler(nil, error);
                } else {
                    NSLog(@"查询设备升级信息回调: %@",data);
//                    IMSOTAFirmwareInfoModel *firmwareInfo = [MTLJSONAdapter modelOfClass:[IMSOTAFirmwareInfoModel class] fromJSONDictionary:data[@"otaFirmwareDTO"] error:&error];
//                    NSDictionary *dic = [MTLJSONAdapter JSONDictionaryFromModel:firmwareInfo error:nil];
//                    NSLog(@"%@", dic);
//                    IMSOTAProgressInfoModel *progressInfo = [MTLJSONAdapter modelOfClass:[IMSOTAProgressInfoModel class] fromJSONDictionary:data[@"otaUpgradeDTO"] error:&error];
                    completionHandler(data, nil);
                }
            }
        }];
}

- (void)upgradeWifiDeviceFirmwareWithIotIds:(NSArray<NSString *> *)iotIds completionHandler:(void (^)(NSDictionary *data, NSError *error))completionHandler {
    NSString *path = @"/thing/ota/batchUpgradeByUser";
    NSString *version = @"1.0.2";
    
    NSDictionary *params = @{@"iotIds": iotIds ?: @[]};
    
    [self requestWithPath:path
                  version:version
                   params:params
        completionHandler:^(NSError *error, id data) {
            if (completionHandler) {
                completionHandler(data, error);
            }
        }];
}

- (void)queryProductInfoWithIotId:(NSString *)iotId
                completionHandler:(void (^)(id data, NSError *error))completionHandler{
    NSString *path = @"/thing/detailInfo/queryProductInfo";
    NSString *version = @"1.1.1";
    
    NSDictionary *params = @{
                             @"iotId": iotId ?: @""
                             };
    
    [self requestWithPath:path version:version params:params completionHandler:^(NSError *error, id data) {
        if (completionHandler) {
            if (error) {
                completionHandler(nil, error);
            } else {
                completionHandler(data, nil);
            }
        }
    }];
}
@end
