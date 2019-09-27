//
//  ESPAliyunSDKUse.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/7/29.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import "ESPAliyunSDKUse.h"
#import "IMSLifeClient.h"
#import "ESPAliyunSDKInit.h"
#import "ESPDataConversion.h"
#import "IMSDeviceClient.h"

NSString *const NET_WIFI_TYPE = @"NET_WIFI";
NSString *const NET_CELLULAR_TYPE = @"NET_CELLULAR";
NSString *const NET_BT_TYPE = @"NET_BT";
NSString *const NET_ZIGBEE_TYPE = @"NET_ZIGBEE";
NSString *const NET_ETHERNET_TYPE = @"NET_ETHERNET";
NSString *const NET_OTHER_TYPE = @"NET_OTHER";

#define ValidDict(f) (f!=nil && [f isKindOfClass:[NSDictionary class]])
#define ValidArray(f) (f!=nil && [f isKindOfClass:[NSArray class]] && [f count]>0)
@interface ESPAliyunSDKUse ()

@property (nonatomic, strong) NSDictionary *deviceInfo;
@property (strong, nonatomic)NSTimer *timer;
@property (strong, nonatomic)NSTimer *scanTimer;

@property (strong, nonatomic)NSMutableArray *devicesArr;

@end

@implementation ESPAliyunSDKUse

+ (instancetype)sharedClient {
    static ESPAliyunSDKUse *client = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[[self class] alloc] init];
    });
    
    return client;
}

- (void)aliyunPresentLogin:(UIViewController *)baseViewController andSuccess:(void (^)(ALBBOpenAccountUser * _Nonnull))success andFailure:(void (^)(NSString * _Nonnull))failure {
    // 获取当前会话
    ALBBOpenAccountSession *session = [ALBBOpenAccountSession sharedInstance];
    if (![session isLogin]) {
        // 获取账号UI服务
        id<ALBBOpenAccountUIService> uiService = ALBBService(ALBBOpenAccountUIService);
        // 显示登录窗口，presentingViewController将通过present方式展示登陆界面viewcontroller
        [uiService presentLoginViewController:baseViewController success:^(ALBBOpenAccountSession *currentSession) {
            // 登录成功，currentSession为当前会话信息
            ALBBOpenAccountUser *currentUser = [currentSession getUser];
            success(currentUser);
            
        } failure:^(NSError *error) {
            // 登录失败对应的错误；取消登录同样会返回一个错误码
            failure(@"登录失败");
        }];
    }else {
//        [session logout];
        failure(@"已登陆");
    }
}

- (void)aliyunLogout {
    ALBBOpenAccountSession *session = [ALBBOpenAccountSession sharedInstance];
    if ([session isLogin]) {
        //清除本地通讯缓存的数据
//        [kIMSThingManager clearLocalCache];
//        [session logout];
        [[IMSAccountService sharedService] logout];
    }
}

- (BOOL)isAliyunLogin {
    ALBBOpenAccountSession *session = [ALBBOpenAccountSession sharedInstance];
    BOOL islogin = [session isLogin];
    return islogin;
}

- (void)getAliyunDeviceList:(deviceListBlock)completionHandler {
    IMSCredential *credential = [IMSCredentialManager sharedManager].credential;
    NSString *identityId = credential.identityId;
    NSString *iotToken = credential.iotToken;
    NSLog(@"identityId：%@，iotToken：%@",identityId,iotToken);
    
    ALBBOpenAccountSession *session = [ALBBOpenAccountSession sharedInstance];
    NSString *sessionID = session.sessionID;
    NSLog(@"sessionID ---> %@",sessionID);
    
    if (identityId == nil || iotToken == nil) {
        [[IMSCredentialManager sharedManager] asyncRefreshCredential:^(NSError * _Nullable error, IMSCredential * _Nullable credential) {
            if (error) {
                //刷新出错，参考错误码 IMSCredentialManagerErrorCode 处理
                NSLog(@"刷新错误：%@", error);
            } else {
                NSString *identityId = credential.identityId;
                NSString *iotToken = credential.iotToken;
                NSLog(@"刷新成功 identityId：%@,iotToken：%@", identityId, iotToken);
            }
        }];
    }
    
    [[IMSLifeClient sharedClient] loadUserDeviceListWithCompletionHandler:^(NSArray *list, NSError *error) {
        if (!error && list) {
            if (list != nil) {
                NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:0];
                resultDic[@"data"] = list;
                resultDic[@"code"] = @"200";
                completionHandler(resultDic);
            }
        }else {
            // 如果返回401未授权或者用户凭证失败，则提示重新登录；
            if (error.code == 401) {
                [[IMSAccountService sharedService] logout];
            }
            NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:0];
            resultDic[@"data"] = @[];
            resultDic[@"code"] = [NSString stringWithFormat:@"%ld",(long)error.code];
            completionHandler(resultDic);
            
        }
    }];
}

- (void)aliStartDiscoveryDeviceCount:(int)count withBlock:(startDiscoveryDevices)didFoundBlock {
    _startDiscoveryDevicesBlock = didFoundBlock;
    self.devicesArr = [NSMutableArray arrayWithCapacity:0];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"startDiscoveryDevice"];
    [self startDiscoveryDevicewithType:count withBlock:^(NSArray * _Nonnull devices) {
        
    }];
    //        超时
//    NSTimer* scanTimer=[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(cancelDiscovery) userInfo:nil repeats:false];
//    [[NSRunLoop currentRunLoop] addTimer:tmpTimer forMode:NSDefaultRunLoopMode];
    if (self.scanTimer) {
        [self.scanTimer invalidate];
        self.scanTimer=nil;
    }
    self.scanTimer=[NSTimer scheduledTimerWithTimeInterval:180 target:self selector:@selector(cancelDiscovery) userInfo:nil repeats:true];
    [[NSRunLoop mainRunLoop] addTimer:self.scanTimer forMode:NSDefaultRunLoopMode];
    
}

- (void)cancelDiscovery {
    if (self.scanTimer) {
        [self.scanTimer invalidate];
        self.scanTimer=nil;
    }
    NSArray *allLanDevicesArray = [kLKLocalDeviceMgr getLanDevices];
    NSLog(@"allLanDevicesArray ---> %@",allLanDevicesArray);
    NSMutableArray *allDeviceArr = [NSMutableArray arrayWithCapacity:0];
    if (ValidArray(allLanDevicesArray)) {
        for (int i = 0; i < allLanDevicesArray.count; i ++) {
            IMLCandDeviceModel *device = allLanDevicesArray[i];
            NSMutableDictionary *deviceDic = [NSMutableDictionary dictionaryWithCapacity:0];
            deviceDic[@"productKey"] = device.productKey;
            deviceDic[@"deviceName"] = device.deviceName;
            if (device.token) {
                deviceDic[@"token"] = device.token;
                [allDeviceArr addObject:deviceDic];
                NSSet *set = [NSSet setWithArray:allDeviceArr];
                NSArray *allArray = [set allObjects];
                [ESPDataConversion fby_saveNSUserDefaults:allArray withKey:@"startDiscoveryAllDevice"];
            }
            
        }
    }
//    [self aliStopDiscoveryDevice];
    NSArray *deviceArrs = [ESPDataConversion fby_getNSUserDefaults:@"startDiscoveryDevice"];
    if (ValidArray(deviceArrs)) {
        _startDiscoveryDevicesBlock(deviceArrs);
    }else {
        _startDiscoveryDevicesBlock(@[]);
    }
}

- (void)startDiscoveryDevicewithType:(int)type withBlock:(startDiscoveryDevices)didFoundBlock {
    if (type == 0) {
        NSArray *allDevices = [ESPDataConversion fby_getNSUserDefaults:@"startDiscoveryAllDevice"];
        didFoundBlock(allDevices);
    }else {
        [[IMLLocalDeviceMgr sharedMgr] startDiscovery:^(NSArray *devices, NSError *err) {
            NSLog(@"devices ---> %@",devices);
            if (ValidArray(devices)) {
                for (int i = 0; i < devices.count; i ++) {
                    IMLCandDeviceModel *device = devices[i];
                    NSMutableDictionary *deviceDic = [NSMutableDictionary dictionaryWithCapacity:0];
                    deviceDic[@"productKey"] = device.productKey;
                    deviceDic[@"deviceName"] = device.deviceName;
                    NSLog(@"device.mac --> %@", device.mac);
                    if (device.token) {
                        deviceDic[@"token"] = device.token;
                        NSString *tokenTwoStr = [device.token substringToIndex:2];
                        if ([[tokenTwoStr lowercaseString] isEqualToString:@"ff"]) {
                            NSArray *baseDeviceArr = @[deviceDic];
                            [ESPDataConversion fby_saveNSUserDefaults:baseDeviceArr withKey:@"startDiscoveryDevice"];
                            [self cancelDiscovery];
                        }else {
                            [self.devicesArr addObject:deviceDic];
                            NSSet *set = [NSSet setWithArray:self.devicesArr];
                            NSArray *allArray = [set allObjects];
                            if (allArray.count == type) {
                               [self cancelDiscovery];
                            }
                        }
                    }
                    
                }
            } else if (err) {
                [ESPDataConversion fby_saveNSUserDefaults:_devicesArr withKey:@"startDiscoveryDevice"];
                NSLog(@"本地发现设备出错: %@", err);
            }
        }];
    }
    
}

- (void)aliStopDiscoveryDevice {
    [[IMLLocalDeviceMgr sharedMgr] stopDiscovery];
}

- (void)aliDeviceBinding:(NSDictionary *)deviceInfo andSuccess:(deviceBindingBlock)deviceBindingSuccess andFailure:(deviceBindingErrorBlock)failure {
    if (!ValidDict(deviceInfo)) {
        return;
    }
    _deviceBindingBlock = deviceBindingSuccess;
    _deviceBindingErrorBlock = failure;
    self.deviceInfo = deviceInfo;
    NSString *key = deviceInfo[@"productKey"];
    if (key) {
        [[IMSLifeClient sharedClient] queryNetTypeWithProductKey:key completionHandler:^(NSString *type, NSError *error) {
            if (error) {
                NSMutableDictionary *errorDic = [NSMutableDictionary dictionaryWithCapacity:0];
                errorDic[@"code"] = @"8010";
                errorDic[@"message"] = [NSString stringWithFormat:@"调用queryNetTypeWithProductKey方法根据productKey获取绑定类型失败:%@",error];
                errorDic[@"deviceInfo"] = self.deviceInfo;
                _deviceBindingErrorBlock(errorDic);
                NSLog(@"queryNetTypeWithProductKey error:%@", error);
            }else {
                NSLog(@"productKey:%@ netType:%@", key, type);
                if ([type isEqualToString:NET_WIFI_TYPE] || [type isEqualToString:NET_ETHERNET_TYPE]) {
                    [self bindWiFiTypeDevice];
                }
            }
        }];
    }
}

- (void)bindWiFiTypeDevice {
    if (self.deviceInfo) {
        NSString *key = self.deviceInfo[@"productKey"];
        NSString *name = self.deviceInfo[@"deviceName"];
        NSString *token = self.deviceInfo[@"token"];
        
        if (key && name) {
            if (!token) {
                [self getDeviceToken:^(NSString *token, BOOL boolSuccess) {
                    if (boolSuccess && token) {
                        [self bindDeviceWithKey:key name:name token:token completionHandler:^(NSString *iotId, NSError *error) {
                            [self bindCompletionHandler:iotId error:error];
                        }];
                    } else {
                        NSMutableDictionary *errorDic = [NSMutableDictionary dictionaryWithCapacity:0];
                        errorDic[@"code"] = @"8011";
                        errorDic[@"message"] = @"获取设备token失败";
                        errorDic[@"deviceInfo"] = self.deviceInfo;
                        _deviceBindingErrorBlock(errorDic);
                    }
                }];
            } else {
                [self bindDeviceWithKey:key name:name token:token completionHandler:^(NSString *iotId, NSError *error) {
                    [self bindCompletionHandler:iotId error:error];
                }];
            }
        } else {
            NSMutableDictionary *errorDic = [NSMutableDictionary dictionaryWithCapacity:0];
            errorDic[@"code"] = @"8011";
            errorDic[@"message"] = @"设备信息参数缺失";
            errorDic[@"deviceInfo"] = self.deviceInfo;
            _deviceBindingErrorBlock(errorDic);
        }
    }
}

- (void)bindCompletionHandler:(NSString *)iotId error:(NSError *)error {
    if (error) {
        NSMutableDictionary *errorDic = [NSMutableDictionary dictionaryWithCapacity:0];
        errorDic[@"code"] = @"8010";
        errorDic[@"message"] = [NSString stringWithFormat:@"绑定失败:%@",error];
        errorDic[@"deviceInfo"] = self.deviceInfo;
        _deviceBindingErrorBlock(errorDic);
    } else if (iotId) {
        NSMutableDictionary *successDic = [NSMutableDictionary dictionaryWithCapacity:0];
        successDic[@"code"] = @"8000";
        successDic[@"iotId"] = iotId;
        successDic[@"deviceInfo"] = self.deviceInfo;
        _deviceBindingBlock(successDic);
    } else {
        NSMutableDictionary *errorDic = [NSMutableDictionary dictionaryWithCapacity:0];
        errorDic[@"code"] = @"8011";
        errorDic[@"message"] = @"绑定完成缺少iotId";
        errorDic[@"deviceInfo"] = self.deviceInfo;
        _deviceBindingErrorBlock(errorDic);
    }
}

- (void)getDeviceToken:(void(^)(NSString *token, BOOL boolSuccess))completion {
    NSString *key = self.deviceInfo[@"productKey"];
    NSString *name = self.deviceInfo[@"deviceName"];
    
    [[IMLLocalDeviceMgr sharedMgr] getDeviceToken:key ? : @"" deviceName:name ? :@"" timeout:20 resultBlock:^(NSString *token, BOOL boolSuccess) {
        if (completion) {
            completion(token, boolSuccess);
        }
    }];
}

- (void)bindDeviceWithKey:(NSString *)key
                     name:(NSString *)name
                    token:(NSString *)token
        completionHandler:(void (^)(NSString *iotId, NSError *error))completion {
    [[IMSLifeClient sharedClient] bindWifiDeviceWithProductKey:key deviceName:name token:token completionHandler:^(NSString *iotId, NSError *error) {
        if (completion) {
            completion(iotId, error);
        }
    }];
}

- (void)unbindDeviceRequest:(NSString *)deviceIotId andBlock:(deviceUnbindBlock)deviceUnbindBlock {
    NSArray *deviceIotIdArr = [ESPDataConversion objectFromJsonString:deviceIotId];
    NSMutableArray *unbindSuccessDeviceIotId = [NSMutableArray arrayWithCapacity:0];
    __block NSUInteger iotIdCount = deviceIotIdArr.count;
    for (int i = 0; i < deviceIotIdArr.count; i ++) {
        if ([ESPDataConversion isNull:deviceIotIdArr[i]]) {
            iotIdCount --;
            continue;
        }
        [[IMSLifeClient sharedClient] unbindDeviceWithIotId:deviceIotIdArr[i] completionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"解绑失败%@", error.localizedDescription);
            } else {
                [unbindSuccessDeviceIotId addObject:deviceIotIdArr[i]];
                NSLog(@"解绑成功");
            }
            if (iotIdCount == 1) {
                deviceUnbindBlock(unbindSuccessDeviceIotId);
            }
            iotIdCount --;
        }];
    }
}

- (void)getAliyunDeviceStatus:(NSString *)message andSuccess:(deviceStatusBlock)deviceStatus {
    NSArray *iotIdArr = [ESPDataConversion objectFromJsonString:message];
    if (!ValidArray(iotIdArr)) {
        return;
    }
    NSMutableArray *deviceStatusArr = [NSMutableArray arrayWithCapacity:0];
    __block NSUInteger iotIdCount = iotIdArr.count;
    for (int i = 0; i < iotIdArr.count; i ++) {
        if ([ESPDataConversion isNull:iotIdArr[i]]) {
            iotIdCount --;
            continue;
        }
        IMSThing *thingShell = [kIMSThingManager buildThing:iotIdArr[i]];// _iotId为云端给设备颁发的唯一标识
        [[thingShell getThingActions] getStatus:^(IMSThingActionsResponse * _Nullable response) {
            if (response.success) {
                NSDictionary *properties = [response.dataObject valueForKey:@"data"];
                NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithDictionary:properties];
                resultDic[@"iotId"] = iotIdArr[i];
                if (ValidDict(resultDic)) {
                    [deviceStatusArr addObject:resultDic];
                }
                NSLog(@"获取设备状态:properties%@",properties);
            }else {
                NSLog(@"获取状态失败");
            }
            if (iotIdCount == 1) {
                deviceStatus(deviceStatusArr);
            }
            iotIdCount --;
            //        [self showMessage:[NSString stringWithFormat:@"获取设备状态:properties%@",properties]];
            //格式如下：
            /* {
             "status":1 //
             "time":1232341455
             }
             
             说明：status表示设备生命周期，目前有以下几个状态，
             0:未激活；1：上线；3：离线；8：禁用；time表示当前状态的开始时间；
             */
        }];
    }
}

- (void)getAliyunDeviceProperties:(NSString *)message andSuccess:(deviceStatusBlock)deviceStatus {
    NSArray *iotIdArr = [ESPDataConversion objectFromJsonString:message];
    if (!ValidArray(iotIdArr)) {
        return;
    }
    NSMutableArray *deviceStatusArr = [NSMutableArray arrayWithCapacity:0];
    __block NSUInteger iotIdCount = iotIdArr.count;
    for (int i = 0; i < iotIdArr.count; i ++) {
        if ([ESPDataConversion isNull:iotIdArr[i]]) {
            iotIdCount --;
            continue;
        }
        IMSThing *thingShell = [kIMSThingManager buildThing:iotIdArr[i]];// _iotId为云端给设备颁发的唯一标识
        [[thingShell getThingActions] getPropertiesFull:^(IMSThingActionsResponse * _Nullable response) {
            if (response.success) {
                NSDictionary * properties = [response.dataObject valueForKey:@"data"];
                NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithDictionary:properties];
                resultDic[@"iotId"] = iotIdArr[i];
                NSLog(@"获取设备属性:properties%@",properties);
                if (ValidDict(resultDic)) {
                    [deviceStatusArr addObject:resultDic];
                }
            }else {
                NSLog(@"获取属性失败");
            }
            if (iotIdCount == 1) {
                deviceStatus(deviceStatusArr);
            }
            iotIdCount --;
        }];
    }
}

- (void)setAliyunDeviceProperties:(NSString *)message andSuccess:(deviceStatusBlock)deviceStatus {
    NSDictionary *deviceDic = [ESPDataConversion objectFromJsonString:message];
    if (!ValidDict(deviceDic)) {
        return;
    }
    NSDictionary *items = [deviceDic objectForKey:@"properties"];
    NSArray *iotIdArr = [deviceDic objectForKey:@"iotId"];
    NSMutableArray *deviceStatusArr = [NSMutableArray arrayWithCapacity:0];
    __block NSUInteger iotIdCount = iotIdArr.count;
    for (int i = 0; i < iotIdArr.count; i ++) {
        if ([ESPDataConversion isNull:iotIdArr[i]]) {
            iotIdCount --;
            continue;
        }
        IMSThing *thingShell = [kIMSThingManager buildThing:iotIdArr[i]];// _iotId为云端给设备颁发的唯一标识
        //items 为key-value对，具体的值请参考 物的模型 TSL-属性以及其 datatype
        [[thingShell getThingActions] setProperties:items responseHandler:^(IMSThingActionsResponse * _Nullable response) {
            
            if (response.success) {
                NSLog(@"设置属性成功");
                [deviceStatusArr addObject:iotIdArr[i]];
            }else {
                NSLog(@"设置属性失败");
            }
            if (iotIdCount == 1) {
                if (ValidArray(deviceStatusArr)) {
                    NSString *deviceIotIdStr = [ESPDataConversion jsonConfigureFromObject:deviceStatusArr];
                    [self getAliyunDeviceProperties:deviceIotIdStr andSuccess:^(NSArray * _Nonnull resultStatusArr) {
                        deviceStatus(resultStatusArr);
                    }];
                }
            }
            iotIdCount --;
        }];
    }
}

- (void)loadOTAUpgradeDeviceList:(deviceUpgradeListBlock)completionHandler {
    [[IMSDeviceClient sharedClient] loadOTAUpgradeDeviceList:^(id  _Nonnull data, NSError * _Nonnull error) {
        NSDictionary *resultDic = [self messageBlock:data withError:error];
        completionHandler(resultDic);
    }];
}

- (void)loadOTAIsUpgradingDeviceList:(deviceUpgradeListBlock)completionHandler {
    [[IMSDeviceClient sharedClient] loadOTAIsUpgradingDeviceList:^(id  _Nonnull data, NSError * _Nonnull error) {
        NSDictionary *resultDic = [self messageBlock:data withError:error];
        completionHandler(resultDic);
    }];
}

- (void)upgradeWifiDeviceFirmware:(NSArray<NSString *> *)iotIds completionHandler:(wifiDeviceUpgradeBlock)completionHandler {
    [[IMSDeviceClient sharedClient] upgradeWifiDeviceFirmwareWithIotIds:iotIds completionHandler:^(NSDictionary * _Nonnull data, NSError * _Nonnull error) {
        NSDictionary *resultDic = [self messageBlock:data withError:error];
        completionHandler(resultDic);
    }];
}

- (void)loadOTAFirmwareDetailAndUpgradeStatus:(NSString *)iotId completionHandler:(deviceUpgradeStatusBlock)completionHandler {
    [[IMSDeviceClient sharedClient] loadOTAFirmwareDetailAndUpgradeStatusWithIotId:iotId completionHandler:^(id  _Nonnull data, NSError * _Nonnull error) {
        NSDictionary *resultDic = [self messageBlock:data withError:error];
        completionHandler(resultDic);
    }];
}

- (void)queryProductsInfoWithIotId:(NSString *)iotId completionHandler:(queryProductsInfoBlock)completionHandler {
    [[IMSDeviceClient sharedClient] queryProductInfoWithIotId:iotId completionHandler:^(id  _Nonnull data, NSError * _Nonnull error) {
        NSDictionary *resultDic = [self messageBlock:data withError:error];
        completionHandler(resultDic);
    }];
}

- (NSDictionary *)messageBlock:(id)data withError:(NSError *)error {
    NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:0];
    if (error) {
        resultDic[@"data"] = error.userInfo;
        resultDic[@"code"] = @"8014";
    } else {
        resultDic[@"data"] = data;
        resultDic[@"code"] = @"200";
    }
    return resultDic;
}
@end
