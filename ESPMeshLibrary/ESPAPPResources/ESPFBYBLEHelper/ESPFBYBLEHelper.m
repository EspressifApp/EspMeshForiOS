//
//  ESPFBYBLEHelper.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/20.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "ESPFBYBLEHelper.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import "PacketCommand.h"
#import "EspDevice.h"
#import "DH_AES.h"
#import "ESPFBYBLEDataParsing.h"

API_AVAILABLE(ios(10.0))
@interface ESPFBYBLEHelper ()<CBCentralManagerDelegate,CBPeripheralDelegate>
// 中心管理者(管理设备的扫描和连接)
@property (nonatomic, strong) CBCentralManager *centralManager;
// 存储的设备
@property (nonatomic, strong) NSMutableArray *peripherals;
// 扫描到的设备
@property (nonatomic, strong) CBPeripheral *cbPeripheral;
// 文本
//@property (strong, nonatomic) UITextView *peripheralText;
// 外设状态
@property (nonatomic, assign) CBManagerState peripheralState;

@property(nonatomic,strong) RSAObject *rsaobject;

@property(nonatomic,strong)ESPBLEIO *espBleIO;

@end

// 蓝牙4.0设备名
static NSString * const kBlePeripheralName = @"light_e290";
// 通知服务
static NSString * const kNotifyServerUUID = @"FF02";
// 写服务
static NSString * const kWriteServerUUID = @"FFFF";
// 通知特征值
static NSString * const kNotifyCharacteristicUUID = @"FF02";
// 写特征值
static NSString * const kWriteCharacteristicUUID = @"FF01";
@implementation ESPFBYBLEHelper
{
    EspDevice *Device;
}
- (NSMutableArray *)peripherals
{
    if (!_peripherals) {
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}

- (CBCentralManager *)centralManager
{
    if (!_centralManager)
    {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return _centralManager;
}

- (void)initBle {
    
    [self centralManager];
}

- (void)stopScan {
    
    [self.centralManager stopScan];
}

- (void)startScan:(FBYBleDeviceBackBlock)device {
    
    NSLog(@"扫描设备");
    _bleScanSuccessBlock = device;
    if (@available(iOS 10.0, *)) {
        if (self.peripheralState ==  CBManagerStatePoweredOn)
        {
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        }
    } else {
        // Fallback on earlier versions
    }
}

- (void)disconnect {
    
    NSLog(@"清空设备");
    [self.peripherals removeAllObjects];
    
    if (self.cbPeripheral != nil)
    {
        // 取消连接
        NSLog(@"%@",@"取消连接");
        [self.centralManager cancelPeripheralConnection:self.cbPeripheral];
    }
}

- (void)connectBle {
    
    if (self.cbPeripheral != nil)
    {
        NSLog(@"连接设备");
        NSLog(@"%@",@"连接设备");
        [self.centralManager connectPeripheral:self.cbPeripheral options:nil];
    } else{
        NSLog(@"%@",@"无设备可连接");
    }
}

// 状态更新时调用
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBManagerStateUnknown:{
            NSLog(@"为知状态");
            self.peripheralState = central.state;
        }
            break;
        case CBManagerStateResetting:
        {
            NSLog(@"重置状态");
            self.peripheralState = central.state;
        }
            break;
        case CBManagerStateUnsupported:
        {
            NSLog(@"不支持的状态");
            self.peripheralState = central.state;
        }
            break;
        case CBManagerStateUnauthorized:
        {
            NSLog(@"未授权的状态");
            self.peripheralState = central.state;
        }
            break;
        case CBManagerStatePoweredOff:
        {
            NSLog(@"关闭状态");
            self.peripheralState = central.state;
        }
            break;
        case CBManagerStatePoweredOn:
        {
            NSLog(@"开启状态－可用状态");
            self.peripheralState = central.state;
            NSLog(@"%ld",(long)self.peripheralState);
        }
            break;
        default:
            break;
    }
}

/**
 扫描到设备
 
 @param central 中心管理者
 @param peripheral 扫描到的设备
 @param advertisementData 广告信息
 @param RSSI 信号强度
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"%@",[NSString stringWithFormat:@"发现设备,设备名:%@",peripheral.name]);
    if (peripheral.name == nil) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    NSData *macData = nil;
    NSString *ouiStr = nil;
    NSString *versionStr = nil;
    NSString *tid = nil;
    NSString *bssid = nil;
    NSData *ManufacturerData = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];//没有这个字段
    if (!ManufacturerData || ManufacturerData.length<13)
    {
        versionStr = @"-1";
        bssid = @"000000000000";
        tid = @"0";
    }else{
        Byte *testByte = (Byte *)[ManufacturerData bytes];
        NSString *hexStr=@"";
        for(int i=0;i<[ManufacturerData length];i++)
        {
            NSString *newHexStr = [NSString stringWithFormat:@"%x",testByte[i]&0xff]; ///16进制数
            if([newHexStr length]==1)
                hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
            else
                hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
        }
        NSLog(@"bytes 的16进制数为:%@",[hexStr substringWithRange:NSMakeRange(12, 12)]);
        bssid = [hexStr substringWithRange:NSMakeRange(12, 12)].lowercaseString;
        versionStr = [NSString stringWithFormat:@"%d",testByte[5] & 3];
        tid = [NSString stringWithFormat:@"%d",testByte[12] | testByte[13] << 8];
        NSData *macDataoui = [ManufacturerData subdataWithRange:NSMakeRange(2, 3)];
        ouiStr  =[[NSString alloc] initWithData:macDataoui encoding:NSUTF8StringEncoding];
    }
    NSString *macStr=[[NSString alloc]initWithData:macData encoding:NSASCIIStringEncoding];
    EspDevice* device=[[EspDevice alloc] init];
    device.uuidBle=peripheral.identifier.UUIDString;
    device.RSSI=RSSI.intValue;
    device.name=peripheral.name;
    device.mac=macStr;
    device.ouiMDF = ouiStr;
    device.version = versionStr;
    device.deviceTid = tid;
    device.bssid = bssid;
    weakSelf.bleScanSuccessBlock(device);
    NSLog(@"发现设备uuid:%@,name:%@,距离:%d,mac:%@,标识码OUI:%@,版本号：%@,设备类型:%@",peripheral.identifier.UUIDString,peripheral.name,RSSI.intValue,macStr,ouiStr,versionStr,tid);
    
    if (![self.peripherals containsObject:peripheral])
    {
        [self.peripherals addObject:peripheral];
        NSLog(@"%@",peripheral);
        
        if ([peripheral.name isEqualToString:kBlePeripheralName])
        {
            NSLog(@"%@",[NSString stringWithFormat:@"设备名:%@",peripheral.name]);
            self.cbPeripheral = peripheral;
            
            NSLog(@"%@",@"开始连接");
            [self.centralManager connectPeripheral:peripheral options:nil];
        }
    }else {
        
        //        [self.peripherals addObject:peripheral];
        
    }
}

/**
 连接失败
 
 @param central 中心管理者
 @param peripheral 连接失败的设备
 @param error 错误信息
 */

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
//    [self showMessage:@"连接失败"];
    NSLog(@"%@",@"连接失败");
//    [self startScan];
//    if ([peripheral.name isEqualToString:kBlePeripheralName])
//    {
//        [self.centralManager connectPeripheral:peripheral options:nil];
//    }
}

/**
 连接断开
 
 @param central 中心管理者
 @param peripheral 连接断开的设备
 @param error 错误信息
 */

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%@",@"断开连接");
//    [self startScan];
}

/**
 连接成功
 
 @param central 中心管理者
 @param peripheral 连接成功的设备
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"连接设备:%@成功",peripheral.name);
    [self.centralManager stopScan];
    
    // 设置设备的代理
    peripheral.delegate = self;
    // services:传入nil  代表扫描所有服务
    [peripheral discoverServices:nil];
}

/**
 扫描到服务
 
 @param peripheral 服务对应的设备
 @param error 扫描错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    // 遍历所有的服务
    for (CBService *service in peripheral.services)
    {
        NSLog(@"服务:%@",service.UUID.UUIDString);
        // 获取对应的服务
        if (![service.UUID.UUIDString isEqualToString:kWriteServerUUID])
        {
            return;
        }
        // 根据服务去扫描特征
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

/**
 扫描到对应的特征
 
 @param peripheral 设备
 @param service 特征对应的服务
 @param error 错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"%@",peripheral);
    // 遍历所有的特征
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        NSLog(@"特征值:%@",characteristic.UUID.UUIDString);
        if ([characteristic.UUID.UUIDString isEqualToString:kWriteCharacteristicUUID]) {
            // 写入数据
            NSLog(@"写入特征值");
//            [self SendNegotiateDataWithDevice:peripheral withCBCharacteristic:characteristic];
            ESPFBYBLEDataParsing *bleDataParsing = [[ESPFBYBLEDataParsing alloc]init];
            [bleDataParsing SendNegotiateWithDevice:peripheral withCBCharacteristic:characteristic withEspDevice:Device];
            [bleDataParsing SendNegotiateDataWithDevice];
        }
        
        if ([characteristic.UUID.UUIDString isEqualToString:kNotifyCharacteristicUUID])
        {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

/**
 根据特征读到数据
 
 @param peripheral 读取到数据对应的设备
 @param characteristic 特征
 @param error 错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if ([characteristic.UUID.UUIDString isEqualToString:kNotifyCharacteristicUUID])
    {
        NSData *data = characteristic.value;
        NSLog(@"%@",data);
        
//        [[ESPBLEIO init] analyseData:[NSMutableData dataWithData:characteristics.value]];
        
        self.espBleIO = [[ESPBLEIO alloc]init];
        
        [self.espBleIO analyseData:[NSMutableData dataWithData:characteristic.value]];
        
    }
}

-(void)SendNegotiateDataWithDevice:(CBPeripheral *)peripheral withCBCharacteristic:(CBCharacteristic *)characteristic{
    if (!self.rsaobject) {
        self.rsaobject = [DH_AES DHGenerateKey];
    }
    NSInteger datacount = 139;
    //    //发送数据长度
    uint16_t length = self.rsaobject.P.length + self.rsaobject.g.length + self.rsaobject.PublickKey.length+6;
    //    [self writeStructDataWithDevice:[PacketCommand SetNegotiatelength:length Sequence:Device.sequence]];
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
            //            [self writeStructDataWithDevice:data];
        } else {
            NSData *data = [PacketCommand SendNegotiateData:[Device.senddata subdataWithRange:NSMakeRange(0, datacount)] Sequence:Device.sequence Frag:YES TotalLength:Device.senddata.length];
            [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            Device.sequence = Device.sequence + 1;
            //            [self writeStructDataWithDevice:data];
            Device.senddata = [Device.senddata subdataWithRange:NSMakeRange(datacount, Device.senddata.length-datacount)];
        }
    }
}

@end
