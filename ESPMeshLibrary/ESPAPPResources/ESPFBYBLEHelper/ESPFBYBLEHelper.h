//
//  ESPFBYBLEHelper.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/20.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESPBLEIO.h"
#import "EspDevice.h"

@interface ESPFBYBLEHelper : NSObject

typedef void(^FBYBleDeviceBackBlock)(EspDevice *device);

@property (nonatomic, copy) FBYBleDeviceBackBlock bleScanSuccessBlock;
//蓝牙初始化
- (void)initBle;
//停止扫描
- (void)stopScan;
//开始扫描
- (void)startScan:(FBYBleDeviceBackBlock)device;
//断开连接
- (void)disconnect;
//开始连接
- (void)connectBle;

@end

