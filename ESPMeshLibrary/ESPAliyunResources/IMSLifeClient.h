//
//  IMSLifeClient.h
//  AlinkAppExpress
//
//  Created by Hager Hu on 11/01/2018.
//

#import <Foundation/Foundation.h>

@interface IMSLifeClient : NSObject

+ (instancetype)sharedClient;

#pragma mark -

- (void)createVirtualDeviceWithProductKey:(NSString *)key
                        completionHandler:(void (^)(NSDictionary *info, NSError *error))completionHandler;


- (void)bindVirtualDeviceWithKey:(NSString *)key
                      deviceName:(NSString *)name
                completionHandler:(void (^)(NSError *error))completionHandler;

#pragma mark -

- (void)queryProductInfoWithKey:(NSString *)key
              completionHandler:(void (^)(NSDictionary *info, NSError *error))completionHandler;

- (void)queryNetTypeWithProductKey:(NSString *)key
                 completionHandler:(void (^)(NSString *type, NSError *error))completionHandler;

- (void)bindWifiDeviceWithProductKey:(NSString *)key
                          deviceName:(NSString *)name
                               token:(NSString *)token
                   completionHandler:(void (^)(NSString *iotId, NSError *error))completionHandler;

- (void)bindGPRSDeviceWithProductKey:(NSString *)key
                          deviceName:(NSString *)name
                   completionHandler:(void (^)(NSString *iotId, NSError *error))completionHandler;

- (void)bindZIGBEEDeviceWithProductKey:(NSString *)key
                            deviceName:(NSString *)name
                     completionHandler:(void (^)(NSString *iotId, NSError *error))completionHandler;

- (void)bindBTDeviceWithProductKey:(NSString *)key
                        deviceName:(NSString *)name
                 completionHandler:(void (^)(NSString *iotId, NSError *error))completionHandler;

#pragma mark -

- (void)loadUserDeviceListWithCompletionHandler:(void (^)(NSArray *list, NSError *error))completionHandler;

- (void)loadVirtualDeviceListWithCompletionHandler:(void (^)(NSArray *list, NSError *error))completionHandler;

- (void)loadSupportProductListWithCompletionHandler:(void (^)(NSArray *list, NSError *error))completionHandler;

#pragma mark - 移动推送

- (void)bindAPNSChannelWithDeviceId:(NSString *)deviceId
                  completionHandler:(void (^)(NSError *error))completionHandler;

- (void)unbindAPNSChannelWithDeviceId:(NSString *)deviceId
                  completionHandler:(void (^)(NSError *error))completionHandler;

#pragma mark - LampPanel(灯具面板)

- (void)lampPanelBaseInfoRequestWithIotId:(NSString *)iotId
                        completionHandler:(void (^)(NSError *error, NSDictionary *data))completionHandler;

- (void)lampPanelAttributeInfoRequestWithIotId:(NSString *)iotId
                             completionHandler:(void (^)(NSError *error, NSDictionary *data))completionHandler;

- (void)setLampPanelAttributeWithIotId:(NSString *)iotId
                                    items:(NSDictionary *)items
                        completionHandler:(void (^)(NSError *error, NSDictionary *data))completionHandler;

- (void)invokeLampPanelSrviceWithIotId:(NSString *)iotId
                                  args:(NSInteger)switchVaule
                     completionHandler:(void (^)(NSError *error))completionHandler;

- (void)setDeviceNickNameWithIotId:(NSString *)iotId
                          nickName:(NSString *)nickName
                 completionHandler:(void (^)(NSError *error))completionHandler;

- (void)unbindDeviceWithIotId:(NSString *)iotId
            completionHandler:(void (^)(NSError *error))completionHandler;


@end
