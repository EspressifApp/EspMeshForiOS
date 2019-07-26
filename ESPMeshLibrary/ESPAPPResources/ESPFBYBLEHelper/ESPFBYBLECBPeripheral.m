//
//  ESPFBYBLECBPeripheral.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/5/5.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import "ESPFBYBLECBPeripheral.h"
#define kPeripheralName @"FBYDevice" //外围设备名称
#define kServiceUUID @"C4FB2349-72FE-4CA2-94D6-1F3CB16331EE" //服务的UUID
#define kCharacteristicUUID @"6A3E4B28-522D-4B3B-82A9-D5E2004534FC" //特征的
@implementation ESPFBYBLECBPeripheral
+(id)shared{
    static dispatch_once_t onceToken;
    static ESPFBYBLECBPeripheral *per = nil;
    dispatch_once(&onceToken, ^{
        per = [[ESPFBYBLECBPeripheral alloc]init];
    });
    return per;
    
}

-(void)setup{
    self.peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
}


-(void)addSe{
    CBUUID *characteristicUUID=[CBUUID UUIDWithString:kCharacteristicUUID];
    CBMutableCharacteristic *characteristicM=[[CBMutableCharacteristic alloc]initWithType:characteristicUUID properties:CBCharacteristicPropertyNotify|CBCharacteristicPropertyWriteWithoutResponse|CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable|CBAttributePermissionsReadEncryptionRequired|CBAttributePermissionsWriteEncryptionRequired];
    CBUUID *serviceUUID=[CBUUID UUIDWithString:kServiceUUID];
    //创建服务
    CBMutableService *serviceM=[[CBMutableService alloc]initWithType:serviceUUID primary:YES];
    //设置服务的特征
    [serviceM setCharacteristics:@[characteristicM]];
    
    /*将服务添加到外围设备*/
    [self.peripheralManager addService:serviceM];
}


-(void)adv{
    //添加服务后开始广播
    NSDictionary *dic=@{CBAdvertisementDataLocalNameKey:kPeripheralName};//广播设置
    [self.peripheralManager startAdvertising:dic];//开始广播
}

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    
    switch (peripheral.state) {
        case CBManagerStatePoweredOn:
            NSLog(@"BLE已打开.");
            
            break;
            
        default:
            NSLog(@"BLE已打开.异常");
            break;
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    NSLog(@"添加服务成功");
}

-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    NSLog(@"广播成功");
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"有服务订阅特征值");
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"有服务取消订阅特征值");
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    NSLog(@"收到读请求");
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests{
    NSLog(@"收到写请求");
    
}

@end
