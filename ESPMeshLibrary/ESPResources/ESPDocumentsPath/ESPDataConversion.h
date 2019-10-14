//
//  ESPDataConversion.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/1/4.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EspDevice.h"
#import "ESPMeshManager.h"
#import "ESPHomeService.h"
#import "ESPDocumentsPath.h"
#import "ESPUploadHandleTool.h"
#import "ESPSniffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface ESPDataConversion : NSObject

typedef void(^scanDeviceTopoBlock)(NSArray *resultArr);
typedef void(^sendDeviceSnifferBlock)(NSArray *snifferResultArr);
typedef void(^sendDeviceStatusBlock)(NSDictionary *statusResultDic);

// 判空
+ (BOOL)isNull:(NSObject *)object;
//JSON字符串转化为对象
+ (id)objectFromJsonString:(NSString *)jsonString;
//字典转json字符串方法
+ (NSString *)jsonFromObject:(id)objdata;
//字典转json字符串方法jsonConfigureFromObject
+ (NSString *)jsonConfigureFromObject:(id)objdata;
//18位随机字符串
+ (NSString *)getRandomStringWithLength;
//16位随机字符串
+ (NSString *)getRandomAESKey;
//characters格式转换
+ (NSMutableArray*)getJSCharacters:(NSMutableArray*)oldCharas;

/**
 keychain存

 @param value 要存的对象的key值
 @param key 要保存的value值
 @return 保存结果
 */
+ (BOOL)fby_saveNSUserDefaults:(id)value withKey:(NSString *)key;

/**
 keychain取

 @param key 对象的key值
 @return 获取的对象
 */
+ (id)fby_getNSUserDefaults:(NSString *)key;

// 多个mac地址分类获取对应本地存储的IP地址
+ (NSDictionary *)deviceRequestIpWithMac:(NSArray *)macArr;
+ (NSDictionary *)deviceRequestIpWithGroup:(NSArray *)groupArr;
// 单个mac地址分类获取对应本地存储的IP地址
+ (NSString *)deviceRequestIp:(NSString *)macStr;

// 设备扫描中通过Mac地址获取本地缓存数据
+ (NSArray *)DeviceOfScanningUDPData:(NSMutableArray *)macArr;

/**
 更新房间信息

 @param msg 页面调用方法传送信息
 */
+ (void)updateGroupInformation:(id)msg;

/**
 设备详细信息获取后重新封装

 @param responDic 网络请求获取到的设备详细信息
 @param newDevice 设备存储的基本信息
 @return 重新封装后的设备信息
 */
+ (NSMutableDictionary *)deviceDetailData:(NSDictionary *)responDic withEspDevice:(EspDevice *)newDevice;

/**
 获取设备Topo结构

 @param scanTopoArr 成功结果回调
 @param failure 失败结果回调
 */
+ (void)scanDeviceTopo:(scanDeviceTopoBlock)scanTopoArr andFailure:(void(^)(int fail))failure;

/**
 下载设备升级文件

 @param downloadSuccess 成功回调
 @param failure 失败回调
 */
+ (void)downloadDeviceOTAFiles:(void(^)(NSString *successMsg))downloadSuccess andFailure:(void(^)(int fail))failure;

/**
 上报设备sniffer变化信息

 @param mac 设备Mac地址
 @param snifferSuccess 成功回调
 @param failure 失败回调
 */
+ (void)sendDeviceSnifferInfo:(NSString *)mac withSnifferSuccess:(sendDeviceSnifferBlock)snifferSuccess andFailure:(void(^)(int fail))failure;

/**
 设备状态变化上报

 @param msgDic 设备信息
 @param statusSuccess 设备上报成功回调
 @param failure 设备上报失败回调
 */
+ (void)sendDevicesStatusChanged:(NSDictionary *)msgDic withDeviceStatusSuccess:(sendDeviceStatusBlock)statusSuccess andFailure:(void(^)(int fail))failure;

/**
 设备上线下线变化上报

 @param msgDic 设备信息
 @param statusSuccess 设备上报成功回调
 @param failure 设备上报失败回调
 */
+ (void)sendDevicesFoundOrLost:(NSDictionary *)msgDic withDeviceStatusSuccess:(sendDeviceStatusBlock)statusSuccess andFailure:(void(^)(int fail))failure;

/**
 发送Wi-Fi状态

 @param wifiSuccess Wi-Fi状态回调
 */
+ (void)sendAPPWifiStatus:(void(^)(NSString *message))wifiSuccess;

//设置状态栏背景颜色和字体颜色
+ (void)setSystemStatusBar:(id)message;
@end

NS_ASSUME_NONNULL_END
