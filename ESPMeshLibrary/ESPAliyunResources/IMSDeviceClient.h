//
//  IMSDeviceClient.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/9/9.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>

//#if __has_include(<IMSBusinessProtocol/IMSBusinessProtocol.h>)
//#import <IMSBusinessProtocol/IMSBusinessProtocol.h>
//#endif

NS_ASSUME_NONNULL_BEGIN

@interface IMSDeviceClient : NSObject

+ (instancetype)sharedClient;

/**
 查询升级设备信息列表
 
 @param completionHandler completionHandler description
 */
- (void)loadOTAUpgradeDeviceList:(void (^)(id data, NSError *error))completionHandler;

/**
 查询正在升级的设备信息列表

 @param completionHandler completionHandler description
 */
- (void)loadOTAIsUpgradingDeviceList:(void (^)(id data, NSError *error))completionHandler;

/**
 查询设备固件信息、升级进度
 
 @param iotId 设备id
 @param completionHandler completionHandler description
 */
- (void)loadOTAFirmwareDetailAndUpgradeStatusWithIotId:(NSString *)iotId
                                     completionHandler:(void (^)(id data, NSError *error))completionHandler;

/**
 wifi设备升级固件
 
 @param iotIds 设备id
 @param completionHandler 设备id
 */
- (void)upgradeWifiDeviceFirmwareWithIotIds:(NSArray<NSString *> *)iotIds completionHandler:(void (^)(NSDictionary *data, NSError *error))completionHandler;

/**
 通过iotId查询产品信息（netType）
 
 @param iotId iotId
 @param completionHandler 设备信息
 */
- (void)queryProductInfoWithIotId:(NSString *)iotId
                completionHandler:(void (^)(id data, NSError *error))completionHandler;
@end

NS_ASSUME_NONNULL_END
