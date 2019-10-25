//
//  ESPMeshManager.h
//  ESPMeshLibrary
//
//  Created by zhaobing on 2018/6/20.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESPBLEHelper.h"
#import "ESPRootScanUDP.h"
#import "ESPBLEIO.h"
#import "EspDevice.h"
#import "ESPRootScanmDNS.h"

NS_ASSUME_NONNULL_BEGIN

@interface ESPMeshManager : NSObject

typedef void (^MeshManagerCallBack)(NSString *msg);
#pragma mark - 工具方法

/**
 * 单例构造方法
 * @return BabyBluetooth共享实例
 */
+ (instancetype)share;



//***********************获取当前Wi-Fi名***********************
-(nullable NSString *)getCurrentWiFiSsid;
//获取当前BSSID
-(nullable NSString *)getCurrentBSSID;
//***********************BLE ***********************
//扫描蓝牙附近所有蓝牙Mesh设备
-(void)starScanBLE:(BLEScanSccessBlock)successBlock failblock:(BLEScanFailedBlock)failBlock;
//结束扫描
-(void)cancelScanBLE;
/**
 设备蓝牙连接

 @param device 连接蓝牙的设备信息
 @param bleConnect 是否需要蓝牙连接
 @param callBackBlock 蓝牙连接回调
 */
-(void)starBLEPair:(EspDevice*)device withIsBleConnect:(BOOL)bleConnect callBackBlock:(BLEIOCallBackBlock)callBackBlock;
/**
 断开蓝牙连接
 */
-(void)cancleBLEPair;
/**
 调用发送自定义数据
 
 @param dataMessage 需要发送的自定义数据
 */
- (void)sendMDFCustomDataToDevice:(NSData *)dataMessage;
/**
 发送设备协商加密数据
 */
- (void)sendDevicesNegotiatesEncryption;
/**
 通知设备进入加密模式
 */
- (void)notifyDevicesToEnterEncryptionMode;

/**
 发送配网数据给设备

 @param info 设备配网信息
 @param timeOut 超时时间
 @param callBackBlock 配网回调
 */
- (void)sendDistributionNetworkDataToDevices:(NSMutableDictionary*)info timeOut:(NSInteger)timeOut callBackBlock:(BLEIOCallBackBlock)callBackBlock;

//***********************UDP ***********************
//扫描已联网设备根节点1025
-(void)starScanRootUDP:(UDPScanSccessBlock)successBlock failblock:(UDPScanFailedBlock)failBlock;
-(void)cancelScanRootUDP;
//***********************UDP 3232监听设备变化回掉***********************

//***********************mDNS ***********************
//扫描已联网设备根节点1025
-(void)starScanRootmDNS:(mDNSScanSccessBlock)successBlock failblock:(mDNSScanFailedBlock)failBlock;
-(void)cancelScanRootmDNS;
//***********************mDNS 2333监听设备变化回掉***********************

//***********************TCP/Http ***********************
//获取root device的详细信息及子节点mac信息等等
- (NSMutableArray*)getMeshInfoFromHost:(EspDevice *)device;

-(void)StarOTA:(NSArray<EspDevice *> *)devices binPath:(NSString *)binPath callback:(MeshManagerCallBack)callback;
//JS发送方法
//JS返回方法
NS_ASSUME_NONNULL_END
@end
