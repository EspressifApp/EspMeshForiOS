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
@interface ESPUDP3232 : NSObject
typedef void (^SccessBlock)(NSString* type,NSString*mac);//type:http  https
//typedef void (^SccessBlock)(NSDictionary *UDPResultDic);
typedef void (^UDPScanFailedBlock)(int code);
@property (nonatomic, copy) SccessBlock successBlock;
@property (nonatomic, copy) UDPScanFailedBlock failBlock;//1:蓝牙未打开
/**
 * 单例构造方法
 * @return BabyBluetooth共享实例
 */
+ (instancetype)share;
//开始扫描
-(void)starScan:(SccessBlock)successBlock failblock:(UDPScanFailedBlock)failBlock;
//停止扫描
-(void)cancelScan;
@end
