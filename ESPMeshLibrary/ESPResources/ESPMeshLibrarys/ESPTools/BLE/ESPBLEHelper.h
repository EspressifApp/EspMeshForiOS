//
//  BabyBLEHelper.h
//  OznerLibrarySwifty
//
//  Created by 赵兵 on 2016/12/27.
//  Copyright © 2016年 net.ozner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BabyBluetooth.h"
#import "EspDevice.h"
@interface ESPBLEHelper : NSObject

typedef void (^BLEScanSccessBlock)(EspDevice*device);
typedef void (^BLEScanFailedBlock)(int code);
@property (nonatomic, copy) BLEScanSccessBlock successBlock;
@property (nonatomic, copy) BLEScanFailedBlock failBlock;//1:蓝牙未打开
/**
 * 单例构造方法
 * @return BabyBluetooth共享实例
 */
+ (instancetype)share;
//开始扫描
-(void)starScan:(BLEScanSccessBlock)successBlock failblock:(BLEScanFailedBlock)failBlock;
//停止扫描
-(void)cancelScan;

@end
