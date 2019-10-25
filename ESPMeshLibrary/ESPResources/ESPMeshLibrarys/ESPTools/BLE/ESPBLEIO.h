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
    ConfigureSuccessful = 300,          //配网成功
    BleConnectSuccessful,               //蓝牙连接成功
    FoundCharacteristic,                //发现特征
    WriteDataSuccessful,                //写入数据成功
    NotificationSuccessful,             //订阅特征通知
    ControlPacketConfigureData,         //控制包解析数据成功
    NegotiateSecuritykeySuccessful,     //协商加密成功
    DeviceConnectWIFISuccessful,        //设备连接Wi-Fi成功
    PeripheralStateConnected,           //外设连接状态
    NotifyDeviceEncryptionMode,         //加密模式通知
    BleDisconnectSuccessful,            //蓝牙正常断开连接
    CustomDataBlock,                    //发送自定义数据回调
};

enum BleConfigureFailNumber {
    RetrievePeripheralFailed = 9000,    //检索外设失败
    PeripheralStateDisconnected,        //外设断开连接状态
    CentralManagerStatePoweredOff,      //蓝牙关闭
    BleConnectFailed,                   //蓝牙连接失败
    BleAbnormalDisconnect,              //蓝牙异常断开连接
    BleSetNotifyFailed,                 //特征当前正在通知
    NotificationStateFailed,            //订阅特征通知失败
    BleDataCallbackFailed,              //订阅蓝牙设备返回数据失败
    CharacteristicNotifyLimits,         //特征通知限制
    PeripheralWriteCharacteristicNil,   //蓝牙数据发送失败
    CRCFailed,                          //数据校验失败
    AnalyseDataFailed,                  //数据解析失败
    WiFiOpmodeFailed,                   //Wi-Fi Opmode 失败
    DeviceConnectWiFiFailed,            //设备连接Wi-Fi失败
    NotifyDataFailed,                   //设备返回数据错误
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
 @param bleConnect 是否需要蓝牙连接
 @param BleCallBackBlock 蓝牙连接回调
 @return self
 */
- (instancetype)init:(EspDevice *)device withIsBleConnect:(BOOL)bleConnect callBackBlock:(BLEIOCallBackBlock)BleCallBackBlock;

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
