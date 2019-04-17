//
//  ESPFBYBLEDataParsing.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/20.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "ESPFBYBLEDataParsing.h"

#import "PacketCommand.h"
#import "DH_AES.h"

@interface ESPFBYBLEDataParsing ()

@property(nonatomic,strong) RSAObject *rsaobject;

@end

@implementation ESPFBYBLEDataParsing
{
    EspDevice *Device;
    CBPeripheral *peripheral;
    CBCharacteristic *characteristic;
}



- (void)SendNegotiateWithDevice:(CBPeripheral *)peripherals withCBCharacteristic:(CBCharacteristic *)characteristics withEspDevice:(EspDevice *)device{
    
    Device = device;
    peripheral = peripherals;
    characteristic = characteristics;
    
}

- (void)SendNegotiateDataWithDevice {
    
    if (!self.rsaobject) {
        self.rsaobject = [DH_AES DHGenerateKey];
    }
    NSInteger datacount = 139;
    //    //发送数据长度
    uint16_t length = self.rsaobject.P.length + self.rsaobject.g.length + self.rsaobject.PublickKey.length+6;
    [peripheral writeValue:[PacketCommand SetNegotiatelength:length Sequence:Device.sequence] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    Device.sequence = Device.sequence + 1;
    //发送数据,需要分包
    Device.senddata = [PacketCommand GenerateNegotiateData:self.rsaobject];
    NSInteger number = Device.senddata.length / datacount + ((Device.senddata.length % datacount)>0? 1:0);
    
    for(NSInteger i = 0; i < number; i++){
        if (i == number-1){
            NSData *data=[PacketCommand SendNegotiateData:Device.senddata Sequence:Device.sequence Frag:NO TotalLength:Device.senddata.length];
            [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            Device.sequence = Device.sequence + 1;
        } else {
            NSData *data = [PacketCommand SendNegotiateData:[Device.senddata subdataWithRange:NSMakeRange(0, datacount)] Sequence:Device.sequence Frag:YES TotalLength:Device.senddata.length];
            [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            Device.sequence = Device.sequence + 1;
            Device.senddata = [Device.senddata subdataWithRange:NSMakeRange(datacount, Device.senddata.length-datacount)];
        }
    }
}

- (void)SendNegotiateWriteDataWithDevice:(NSData *)data {
    
    if (peripheral!=nil && characteristic!=nil) {
        NSLog(@"<<<<<<<<蓝牙发送数据：%@",data);
        [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        Device.sequence = Device.sequence + 1;
    } else {
        NSLog(@"error:peripheral write characteristic nil");
    }
}


@end
