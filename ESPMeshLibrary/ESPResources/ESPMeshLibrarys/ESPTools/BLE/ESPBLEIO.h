//
//  BabyBLEIO.h
//  OznerLibrarySwifty
//
//  Created by 赵兵 on 2016/12/27.
//  Copyright © 2016年 net.ozner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BabyBluetooth.h"
#import "EspDevice.h"

enum ConfigureNumber {
    ConfigureSuccessful = 300,
    BleConnectSuccessful,
    FoundCharacteristic,
    WriteDataSuccessful,
    NotificationSuccessful,
    ControlPacketConfigureData,
    NegotiateSecuritykeySuccessful,
    DeviceConnectWIFISuccessful,
    PeripheralStateConnected,
    NotifyDeviceEncryptionMode,
    BleDisconnectSuccessful,
    CustomDataBlock,
};

enum BleConfigureFailNumber {
    RetrievePeripheralFailed = 9000,
    PeripheralStateDisconnected,
    CentralManagerStatePoweredOff,
    BleConnectFailed,
    BleAbnormalDisconnect,
    BleSetNotifyFailed,
    NotificationStateFailed,
    BleDataCallbackFailed,
    CharacteristicNotifyLimits,
    PeripheralWriteCharacteristicNil,
    CRCFailed,
    AnalyseDataFailed,
    WiFiOpmodeFailed,
    DeviceConnectWiFiFailed,
    NotifyDataFailed,
};


@interface ESPBLEIO : NSObject
{
@public
    BabyBluetooth *baby;
}
typedef void(^BLEIOCallBackBlock)(NSString *msg);
@property(strong,nonatomic)CBPeripheral *currPeripheral;
@property (nonatomic, copy) BLEIOCallBackBlock BleCallBackBlock;
@property (nonatomic, copy) BLEIOCallBackBlock CallBackBlock;

/**
 蓝牙连接

 @param device 连接蓝牙的设备信息
 @param BleCallBackBlock 蓝牙连接回调
 @return self
 */
- (instancetype)init:(EspDevice*)device callBackBlock:(BLEIOCallBackBlock)BleCallBackBlock;

/**
 断开蓝牙连接
 */
- (void)disconnectBLE;

/**
 收到设备返回的数据解析

 @param data 设备返回的数据
 */
- (void)analyseData:(NSMutableData *)data;

/**
 调用发送自定义数据

 @param dataMessage 需要发送的自定义数据
 */
- (void)sendMDFCustomData:(NSData *)dataMessage;

/**
 发送设备协商加密数据
 */
- (void)sendDeviceNegotiatesEncryption;

/**
 通知设备进入加密模式
 */
- (void)notifyDeviceToEnterEncryptionMode;

/**
 设备蓝牙配网

 @param info 配网参数
 @param timeOut 超时时间
 @param callBackBlock 配网回调
 */
- (void)sendDistributionNetworkDataToDevice:(NSMutableDictionary*)info timeOut:(NSInteger)timeOut callBackBlock:(BLEIOCallBackBlock)callBackBlock;

@end
