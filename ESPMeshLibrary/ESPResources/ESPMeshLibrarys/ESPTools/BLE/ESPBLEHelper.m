//
//  BabyBLEHelper.m
//  OznerLibrarySwifty
//
//  Created by 赵兵 on 2016/12/27.
//  Copyright © 2016年 net.ozner. All rights reserved.
//

#import "ESPBLEHelper.h"
#import "ESPMeshManager.h"
#define BleFilterName @"light"
#define ValidDict(f) (f!=nil && [f isKindOfClass:[NSDictionary class]])
@implementation ESPBLEHelper
{
    BabyBluetooth *baby;
    
}
//单例模式
+ (instancetype)share {
    static ESPBLEHelper *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[ESPBLEHelper alloc]init];
    });
    return share;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        //初始化BabyBluetooth 蓝牙库
        baby = [BabyBluetooth shareBabyBluetooth];
        //设置蓝牙委托
        [self babyDelegate];
        
    }
    return self;
    
}

-(void)starScan:(BLEScanSccessBlock)successBlock failblock:(BLEScanFailedBlock)failBlock{
   
    _successBlock=successBlock;
    _failBlock=failBlock;
    //停止之前的连接
    [baby cancelAllPeripheralsConnection];
    baby.scanForPeripherals().begin();//.stop(scanTimer);
}
 //停止扫描
-(void)cancelScan{
    [baby cancelScan];
}
- (float)calcDistByRSSI:(int)rssi
{
    int iRssi = abs(rssi);
    float power = (iRssi-59)/(10*2.0);
    return pow(10, power);
}



//蓝牙网关初始化和委托方法设置
-(void)babyDelegate{
    
    __weak typeof(self) weakSelf = self;
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        [weakSelf.delegate bleUpdateStatusBlock:central];
        if (@available(iOS 10.0, *)) {
            if (central.state != CBManagerStatePoweredOn) {
                if (weakSelf.failBlock) {
                    weakSelf.failBlock(1);
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:@"appBleStateNotification" object:@{@"enable":@false}];
            }else if (central.state != CBManagerStatePoweredOff) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"appBleStateNotification" object:@{@"enable":@true}];
            }
        }else {
            if (central.state != CBCentralManagerStatePoweredOn) {
                if (weakSelf.failBlock) {
                    weakSelf.failBlock(1);
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:@"appBleStateNotification" object:@{@"enable":@false}];
            }else if (central.state != CBCentralManagerStatePoweredOff) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"appBleStateNotification" object:@{@"enable":@true}];
            }
        }
    }];
    
    //设置扫描到设备的委托
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        
        NSString *ouiStr = @"";
        NSString *versionStr = nil;
        NSString *tid = nil;
        NSString *bssid = nil;
        NSData *ManufacturerData = nil;
        BOOL onlyBeacon;
        if (ValidDict(advertisementData)) {
            ManufacturerData = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];//没有这个字段
            if (ManufacturerData.length == 14) {
                NSData *macDataoui = [ManufacturerData subdataWithRange:NSMakeRange(2, 3)];
                ouiStr  =[[NSString alloc] initWithData:macDataoui encoding:NSUTF8StringEncoding];
            }else if (ManufacturerData.length == 12) {
                NSData *macDataoui = [ManufacturerData subdataWithRange:NSMakeRange(2, 3)];
                ouiStr  =[[NSString alloc] initWithData:macDataoui encoding:NSUTF8StringEncoding];
            }
        }
        if (!ManufacturerData || [ouiStr isEqualToString:@""] )
        {
            NSString* mac=[peripheral.name componentsSeparatedByString:@"_"].lastObject;
            if (mac.length==6) {
                mac=[NSString stringWithFormat:@"000000%@",mac];
            } else if (mac.length == 4) {
                mac=[NSString stringWithFormat:@"00000000%@",mac];
            }
            versionStr = @"-1";
            bssid = mac;
            tid = @"0";
            onlyBeacon = false;
        }else{
            
            Byte *testByte = (Byte *)[ManufacturerData bytes];
//            for (int i = 0; i < [ManufacturerData length]; i ++) {
//                NSLog(@"testByte---->%d\n",testByte[i]);
//            }
            NSString *hexStr=@"";
            for(int i=0;i<[ManufacturerData length];i++)
            {
                NSString *newHexStr = [NSString stringWithFormat:@"%x",testByte[i]&0xff]; ///16进制数
                if([newHexStr length]==1)
                    hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
                else
                    hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
            }
//            NSLog(@"bytes 的16进制数为:%@",[hexStr substringWithRange:NSMakeRange(12, 12)]);
            bssid = [hexStr substringWithRange:NSMakeRange(12, 12)].lowercaseString;
            versionStr = [NSString stringWithFormat:@"%d",testByte[5] & 3];
            onlyBeacon = (testByte[5] & 16) != 0;
            tid = [NSString stringWithFormat:@"%d",testByte[12] | testByte[13] << 8];
        }
        EspDevice* device=[[EspDevice alloc] init];
        device.uuidBle=peripheral.identifier.UUIDString;
        device.RSSI=RSSI.intValue;
        device.name=peripheral.name;
        device.mac=bssid;
        device.ouiMDF = ouiStr;
        device.version = versionStr;
        device.deviceTid = tid;
        device.bssid = bssid;
        device.onlyBeacon = onlyBeacon;
        weakSelf.successBlock(device);
//        NSLog(@"发现设备uuid:%@,name:%@,距离:%d,mac:%@,标识码OUI:%@,版本号：%@,设备类型:%@",peripheral.identifier.UUIDString,peripheral.name,RSSI.intValue,bssid,ouiStr,versionStr,tid);
    }];
    
    
    //设置查找设备的过滤器
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        if (peripheralName == nil) {
            return NO;
        }//Other_undefined
        if ([peripheralName.lowercaseString containsString:@"other"]) {
            return NO;
        }
        return YES;
    }];
    
    
    [baby setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
        NSLog(@"setBlockOnCancelScanBlock");
       // weakSelf.babyBLEScanFailedBlock(2);
    }];
    
    
    
    //示例:
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    //NSArray *scanForPeripheralsWithServices = @[[CBUUID UUIDWithString:@"FFF0"]];
    //连接设备->
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
}
@end
