//
//  ESPUDPUtils.h
//  Esp32Mesh
//
//  Created by zhaobing on 2018/6/12.
//  Copyright © 2018年 AE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"
#import "EspDevice.h"
@interface ESPRootScanUDP : NSObject
//typedef void (^UDPScanSccessBlock)(EspDevice* devixe);//type:http  https
typedef void (^UDPScanSccessBlock)(NSArray *devixe);//type:http  https
typedef void (^UDPScanFailedBlock)(int code);
@property (nonatomic, copy) UDPScanSccessBlock successBlock;
@property (nonatomic, copy) UDPScanFailedBlock failBlock;//1:蓝牙未打开
/**
 * 单例构造方法
 * @return BabyBluetooth共享实例
 */
+ (instancetype)share;
//开始扫描
-(void)starScan:(UDPScanSccessBlock)successBlock failblock:(UDPScanFailedBlock)failBlock;
//停止扫描
-(void)cancelScan;
@end
