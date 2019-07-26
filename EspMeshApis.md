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
3. 蓝牙配网
4. 停止配网
5. 开启UDP扫描
6. 发送多个设备命令
7. 发送单个设备命令
8. 设备升级
9. 停止OTA升级
10. 重启设备命令

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
 停止配网
 */
- (void)stopConfigureBlufi;
```

```
/**
 开启UDP扫描

 @param success UDP扫描成功的回调
 @param failure UDP扫描失败的回调
 */
- (void)scanDevicesAsyncSuccess:(DevicesAsyncSuccessBlock)success andFailure:(void(^)(int fail))failure;
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
 @"root_response":@""
 }
 @param messageDic 发送设备命令的信息
 @param success 发送设备命令成功的回调
 @param failure 发送设备命令失败的回调
 */
- (void)requestDevicesMulticastAsync:(NSDictionary *)messageDic andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *dic))failure;
```

```
/**
 发送单个设备命令
 messageDic = @{
 @"request":@"",
 @"callback":@"",
 @"tag":@"",
 @"mac":@"",
 @"host":@"",
 @"root_response":@""
 }
 @param messageDic 发送设备命令的信息
 @param success 发送设备命令成功的回调
 @param failure 发送设备命令失败的回调
 */
- (void)requestDeviceAsync:(NSDictionary *)messageDic andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *dic))failure;
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
 @"macs":@[],
 @"host":@""
 }
 @param messageDic 重启设备命令的信息
 */
- (void)reboot:(NSDictionary *)messageDic;
```