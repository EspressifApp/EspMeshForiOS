//
//  ESPRootScanmDNS.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/1/30.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EspDevice.h"
NS_ASSUME_NONNULL_BEGIN

@interface ESPRootScanmDNS : NSObject
//typedef void (^mDNSScanSccessBlock)(EspDevice* devixe);//type:http  https
typedef void (^mDNSScanSccessBlock)(NSArray *devixe);//type:http  https
typedef void (^mDNSScanFailedBlock)(int code);
@property (nonatomic, copy) mDNSScanSccessBlock successBlock;
@property (nonatomic, copy) mDNSScanFailedBlock failBlock;//1:蓝牙未打开
/**
 * 单例构造方法
 * @return BabyBluetooth共享实例
 */
+ (instancetype)share;
//开始扫描
-(void)starmDNSScan:(mDNSScanSccessBlock)successBlock failblock:(mDNSScanFailedBlock)failBlock;
//停止扫描
-(void)cancelmDNSScan;
@end

NS_ASSUME_NONNULL_END
