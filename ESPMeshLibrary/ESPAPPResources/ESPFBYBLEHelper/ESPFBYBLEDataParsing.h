//
//  ESPFBYBLEDataParsing.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/20.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "EspDevice.h"


@interface ESPFBYBLEDataParsing : NSObject

//获取设备信息
- (void)SendNegotiateWithDevice:(CBPeripheral *)peripherals withCBCharacteristic:(CBCharacteristic *)characteristics withEspDevice:(EspDevice *)device;

//发送自定义写入数据
- (void)SendNegotiateDataWithDevice;

//发送写入的数据
- (void)SendNegotiateWriteDataWithDevice:(NSData *)data;

@end

