[[简体中文]](ESPMeshLocalApi_zh_rCN.md)

# ESP-Mesh Local Api

## One: Introduction

ESPMesh is an App that integrates bluetooth distribution network and wi-fi control, The App is available in the App Store.
The main functions of ESPMesh are as follows:

* Wi-fi network configuration function based on bluetooth channel
* Send control commands over a wi-fi network
* OTA upgrades for remote and local devices
* UDP and mDNS scanning

## Two: interface directory

1. <a href="#1">Enable bluetooth scan</a>
2. <a href="#2">Turn off bluetooth scan</a>
3. <a href="#3">Get bluetooth status</a>
4. <a href="#4">Bluetooth connection</a>
5. <a href="#5">Send custom data</a>
6. <a href="#6">Device negotiation encryption</a>
7. <a href="#7">Notifies the device to enter encryption mode</a>
8. <a href="#8">Bluetooth config network</a>
9. <a href="#9">Bluetooth disconnection</a>
10. <a href="#10">Enable UDP scanning</a>
11. <a href="#11">Send multiple device commands</a>
12. <a href="#12">Device upgrades</a>
13. <a href="#13">Stop OTA upgrade</a>
14. <a href="#14">Restart device command</a>

## Three: details of the interface

### 1. <a name="1">Enable bluetooth scan</a>

```
/**
 Enable bluetooth scan

 @param success Bluetooth scan successful callback
 @param failure Callback for failed bluetooth scan
 */
- (void)startBleScanSuccess:(BleScanSuccessBlock)success andFailure:(void(^)(int fail))failure;
```

### 2. <a name="2">Turn off bluetooth scan</a>

```
/**
 Turn off bluetooth scan
 */
- (void)stopBleScan;
```

### 3. <a name="3">Get bluetooth status</a>

```
// Get bluetooth status, Implement the following proxy method via <BleDelegate>
- (void)bleUpdateStatusBlock:(CBCentralManager *)central;
```
### 4. <a name="4">Bluetooth connection</a>

```
/**
 Bluetooth connection

 @param deviceInfo Bluetooth connection parameters
 @param success Bluetooth connection successful callback
 @param failure Bluetooth connection failed callback
 */
+ (void)BleConnection:(NSDictionary *)deviceInfo andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *dic))failure;
```

### 5. <a name="5">Send custom data</a>

```
/**
 Send custom data
 
 @param dataMessage Custom data that needs to be sent
 */
- (void)sendMDFCustomDataToDevice:(NSData *)dataMessage;
```

### 6. <a name="6">Device negotiation encryption</a>

```
/**
 Device negotiation encryption
 */
- (void)sendDevicesNegotiatesEncryption;
```

### 7. <a name="7">Notifies the device to enter encryption mode</a>

```
/**
 Notifies the device to enter encryption mode
 */
- (void)notifyDevicesToEnterEncryptionMode;
```

### 8. <a name="8">Bluetooth config network</a>

```
/**
 Bluetooth config network
 messageDic = @{
 @"ssid":@"",
 @"password":@"",
 @"ble_addr":@""
 }
 @param messageDic Bluetooth config network information
 @param success Successful callback of bluetooth config network
 @param failure failed callback of bluetooth config network
 */
- (void)startConfigureBlufi:(NSDictionary *)messageDic andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *dic))failure;
```

### 9. <a name="9">Bluetooth disconnection</a>

```
/**
 Bluetooth disconnection
 */
- (void)stopConfigureBlufi;
```

### 10. <a name="10">Enable UDP scanning</a>

```
/**
 Enable UDP scanning

 @param success UDP scans successful callbacks, There are two scenarios for callbacks: 1. Gets device basic information onDeviceScanning, 2. Get device details DevicesOfScanUDP.
 @param failure UDP scan failed callback, fail is 8010 ande 8011，8010 contains (allArray Incorrect format、getMeshInfoFromHost Network request failed、Device basic information tempInfosArr is empty), 8011 failed to load local storage data for device details query.
 */
+ (void)scanDevicesAsyncSuccess:(DevicesAsyncSuccessBlock)success andFailure:(void(^)(int fail))failure;
```

### 11. <a name="11">Send multiple device commands</a>

```
/**
 Send multiple device commands
 messageDic = @{
 @"request":@"",
 @"callback":@"",
 @"tag":@"",
 @"mac":@"",
 @"host":@"",
 @"root_response":@"",
 @"isSendQueue":@""
 }
 @param messageDic Send device command information
 @param success Successful callback to send device command
 @param failure Failed callback to send device command
 */
+ (void)requestDevicesMulticastAsync:(NSDictionary *)messageDic andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(NSDictionary *failureDic))failure;
```

### 12. <a name="12">Device upgrades</a>

```
/**
 Device upgrades
 messageDic = @{
 @"macs":@"",
 @"bin":@"",
 @"host":@"",
 @"type":@""
 }
 @param messageDic Information about equipment upgrades
 @param success Callback for successful device upgrade
 @param failure callback for a failed device upgrade
 */
- (void)startOTA:(NSDictionary *)messageDic Success:(startOTASuccessBlock)success andFailure:(void(^)(int fail))failure;
```

### 13. <a name="13">Stop OTA upgrade</a>

```
/**
 Stop OTA upgrade
 messageDic = @{
 @"host":@[]
 }
 @param messageDic Stop OTA upgrade information
 */
- (void)stopOTA:(NSDictionary *)messageDic;
```

### 14. <a name="14">Restart device command</a>

```
/**
 Restart device command
 messageDic = @{
 @"macs":@[]
 }
 @param messageDic Restart device command information
 */
- (void)reboot:(NSDictionary *)messageDic;
```