# ESP-Mesh Api

## 一：简介

ESPMesh是一款集蓝牙配网和Wi-Fi控制于一体的App，该App已在App Store上线。
ESPMesh实现的主要功能有如下几点：
* 基于蓝牙通道Wi-Fi 网络配置功能
* 通过Wi-Fi 网络发送控制命令
* 远程和本地设备OTA升级
* UDP和mDNS扫描

## 二：接口目录

1. 开启蓝牙扫描
2. 关闭蓝牙扫描
3. 获取蓝牙状态
4. 蓝牙连接
5. 发送自定义数据
6. 设备协商加密
7. 通知设备进入加密模式
8. 蓝牙配网
9. 蓝牙断开连接
10. 开启UDP扫描
11. 发送多个设备命令
12. 设备升级
13. 停止OTA升级
14. 重启设备命令

## 三：接口详情
```
/**
 开启蓝牙扫描

 @param success 蓝牙扫描成功的回调
 @param failure 蓝牙扫描失败的回调
 */
- (void)startBleScanSuccess:(BleScanSuccessBlock)success andFailure:(void(^)(int fail))failure;
```

```
/**
 关闭蓝牙扫描
 */
- (void)stopBleScan;
```

```
// 蓝牙状态,通过<BleDelegate>实现下面代理方法
- (void)bleUpdateStatusBlock:(CBCentralManager *)central;
```

```
/**
 蓝牙连接

 @param deviceInfo 蓝牙连接参数
 @param success 蓝牙连接成功回调
 @param failure 蓝牙连接失败回调
 */
+ (void)BleConnection:(NSDictionary *)deviceInfo andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *dic))failure;
```

```
/**
 调用发送自定义数据
 
 @param dataMessage 需要发送的自定义数据
 */
- (void)sendMDFCustomDataToDevice:(NSData *)dataMessage;
```

```
/**
 发送设备协商加密数据
 */
- (void)sendDevicesNegotiatesEncryption;
```

```
/**
 通知设备进入加密模式
 */
- (void)notifyDevicesToEnterEncryptionMode;
```

```
/**
 蓝牙配网
 messageDic = @{
 @"ssid":@"",
 @"password":@"",
 @"ble_addr":@""
 }
 @param messageDic 蓝牙配网的信息
 @param success 蓝牙配网成功的回调
 @param failure 蓝牙配网失败的回调
 */
- (void)startConfigureBlufi:(NSDictionary *)messageDic andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *dic))failure;
```

```
/**
 蓝牙断开连接
 */
- (void)stopConfigureBlufi;
```

```
/**
 开启UDP扫描

 @param success UDP扫描成功的回调，回调有两种情况：1. 获取到设备基本信息onDeviceScanning回调，2. 获取到设备详细信息DevicesOfScanUDP
 @param failure UDP扫描失败的回调，fail分8010和8011，8010包含(allArray格式不正确、getMeshInfoFromHost网络请求失败、设备基本信息tempInfosArr为空)，8011为获取设备详情失败查询加载本地存储数据
 */
+ (void)scanDevicesAsyncSuccess:(DevicesAsyncSuccessBlock)success andFailure:(void(^)(int fail))failure;
```

```
/**
 发送多个设备命令
 messageDic = @{
 @"request":@"",
 @"callback":@"",
 @"tag":@"",
 @"mac":@"",
 @"host":@"",
 @"root_response":@"",
 @"isSendQueue":@""
 }
 @param messageDic 发送设备命令的信息
 @param success 发送设备命令成功的回调
 @param failure 发送设备命令失败的回调
 */
+ (void)requestDevicesMulticastAsync:(NSDictionary *)messageDic andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *failureDic))failure;
```

```
/**
 设备升级
 messageDic = @{
 @"macs":@"",
 @"bin":@"",
 @"host":@"",
 @"type":@""
 }
 @param messageDic 设备升级的信息
 @param success 设备升级成功的回调
 @param failure 设备升级失败的回调
 */
- (void)startOTA:(NSDictionary *)messageDic Success:(startOTASuccessBlock)success andFailure:(void(^)(int fail))failure;
```

```
/**
 停止OTA升级
 messageDic = @{
 @"host":@[]
 }
 @param messageDic 停止OTA升级的信息
 */
- (void)stopOTA:(NSDictionary *)messageDic;
```

```
/**
 重启设备命令
 messageDic = @{
 @"macs":@[]
 }
 @param messageDic 重启设备命令的信息
 */
- (void)reboot:(NSDictionary *)messageDic;
```