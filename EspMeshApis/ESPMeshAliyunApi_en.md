[[简体中文]](ESPMeshAliyunApi_zh_rCN.md)

## ESP-Mesh Aliyun Api

## One: interface directory

1. <a href="#1">User login</a>
2. <a href="#2">User logout</a>
3. <a href="#3">Whether the user is logged in</a>
4. <a href="#4">User login information</a>
5. <a href="#5">Get aliyun binding device list</a>
6. <a href="#6">Discovery a list of local config network devices</a>
7. <a href="#7">Stop discovery local device</a>
8. <a href="#8">Device binding</a>
9. <a href="#9">Device unbind</a>
10. <a href="#10">Get device status</a>
11. <a href="#11">Get device properties</a>
12. <a href="#12">Set device properties</a>
13. <a href="#13">Query upgrade device information list</a>
14. <a href="#14">Upgrade wi-fi device</a>
15. <a href="#15">Device upgrade progress query</a>
16. <a href="#16">Query the list of device information being upgraded</a>

## Two: details of the interface

### 1. <a name="1">User login</a>

```
- (void)aliUserLogin;
```

Return method name: onAliUserLogin, Parameter format:

```
{"mobileLocationCode":"86","mobile":"13661215411","accountId":707374,"oauthInfoDict":{"SidExpiredTime":1650874674},"hasPassword":true,"openaccountInfoDict":{"mobile":"13661617154","enableDevice":"true","pwdVersion":0,"id":707374,"mobileLocationCode":"86","status":1,"domainId":8191367,"mobileConflictAccount":"false","subAccount":"false","hasPassword":"true"}}
```

### 2. <a name="2">User logout</a>

```
- (void)aliUserLogout;
```

No return parameter

### 3. <a name="3">Whether the user is logged in</a>

```
- (void)isAliUserLogin;
```
Return method name: onIsAliUserLogin, Parameter format:

```
{"isLogin":true}
```

### 4. <a name="4">User login information</a>

```
- (void)getAliUserInfo;
```

Return method name: onGetAliUserInfo, Parameter format:

```
{"mobileLocationCode":"86","mobile":"13661215411","accountId":707374,"oauthInfoDict":{"SidExpiredTime":1650874674},"hasPassword":true,"openaccountInfoDict":{"mobile":"13661617154","enableDevice":"true","pwdVersion":0,"id":707374,"mobileLocationCode":"86","status":1,"domainId":8191367,"mobileConflictAccount":"false","subAccount":"false","hasPassword":"true"}}
```

### 5. <a name="5">Get aliyun binding device list</a>

```
- (void)getAliDeviceList;
```

Return method name: onGetAliyunDeviceList, Parameter format:

```
{
"data":[{
	"isEdgeGateway": false,
	"thingType": "DEVICE",
	"categoryImage": "http:\/\/iotx-paas-admin.oss-cn-shanghai.aliyuncs.com\/publish\/image\/1559630650729.png",
	"netType": "NET_WIFI",
	"nodeType": "GATEWAY",
	"gmtModified": 1565332471000,
	"productName": "乐鑫mesh_light001",
	"owned": 1,
	"productImage": "http:\/\/iotx-paas-admin.oss-cn-shanghai.aliyuncs.com\/publish\/image\/1526474600174.png",
	"identityId": "5051op63326c1491234567876ff4c90d303e284376089",
	"productModel": "001",
	"productKey": "a10BnLLzGv4",
	"deviceName": "test5",
	"identityAlias": "13661617154",
	"iotId": "SrFIr31Ou41234rtyjhUzw6000100",
	"status": 1
}]
"code":"200/401"
}

```

### 6. <a name="6">Discovery a list of local config network devices</a>

```
- (void)aliStartDiscovery;
```

Return method name: onAliStartDiscovery, Parameter format:

```
{
[]
}
```


### 7. <a name="7">Stop discovery local device</a>

```
- (void)aliStopDiscovery;
```

No return parameter

### 8. <a name="8">Device binding</a>

```
// message is the information waiting for the binding device to get，Format for {"productKey":"","deviceName":"","token":""}
- (void)aliDeviceBinding:(NSString *)message;
```

Return method name: onAliDeviceBind, Parameter format:

```
// Successful format onAliDeviceBind
{
"code":"8000",//8010:There are failure tips and reasons for failure，8011:There are failure tips and reasons for no failure
"iotId":""
"deviceInfo":{
	"productKey":"",
	"deviceName":"",
	"token":""
	}
}
```

### 9. <a name="9">Device unbind</a>

```
// message is the iotId unbinding device，Format for ["iotId1","iotId2","iotId3".....]
- (void)aliDeviceUnbindRequest:(NSString *)message;
```
No return parameter

### 10. <a name="10">Get device status</a>

```
// message is the iotId of the device，Format for ["iotId1","iotId2","iotId3".....]
- (void)getAliDeviceStatus:(NSString *)message;
```

Return method name: onGetAliDeviceStatus, Parameter format:

```
[
	{ 	"status":1 ,
  		"time":1232341455,
  		"iotId": ""
	},
	{ 	"status":2 ,
  		"time":1232341466,
  		"iotId": ""
	},
	...
]
```

Explain: status represents the device life cycle, There are several status, 0:inactive; 1:online; 3:offline; 8:disable; time represents the start time of the current state.

### 11. <a name="11">Get device properties</a>


```
// message is the iotId of the device, Format for ["iotId1","iotId2","iotId3".....]
- (void)getAliDeviceProperties:(NSString *)message;
```

Return method name: onGetAliDeviceProperties, Parameter format:

```
[
	{
      "_sys_device_mid": {
             "time": 1516356290173,
             "value": "example.demo.module-id"
             },
      "WorkMode": {
             "time": 1516347450295,
             "value": 0
             },
      "_sys_device_pid": {
             "time": 1516356290173,
             "value": "example.demo.partner-id"
             }
    },
	{
      "_sys_device_mid": {
             "time": 1516356290173,
             "value": "example.demo.module-id"
             },
      "WorkMode": {
             "time": 1516347450295,
             "value": 0
             },
      "_sys_device_pid": {
             "time": 1516356290173,
             "value": "example.demo.partner-id"
             },
      "iotId": ""
    },
	...
]
```

### 12. <a name="12">Set device properties</a>


```
// message is the iotId of the device, Format for {"iotId":["iotId1","iotId2","iotId3".....],"properties":{"Brightness":90}}
- (void)setAliDeviceProperties:(NSString *)message;
```

Modify the color properties data format for:


```
{
"HSVColor":{"Hue":0,
             "Saturation":0,
             "Value":0
             }
}                             
```

Modify switch properties data format for:

```
//Shutdown
{"LightSwitch":0}
//open
{"LightSwitch":1}
```

Return method name: onSetAliDeviceProperties, Parameter format:

```
[
	{
      "_sys_device_mid": {
             "time": 1516356290173,
             "value": "example.demo.module-id"
             },
      "WorkMode": {
             "time": 1516347450295,
             "value": 0
             },
      "_sys_device_pid": {
             "time": 1516356290173,
             "value": "example.demo.partner-id"
             },
             "iotId": ""
    },
	{
      "_sys_device_mid": {
             "time": 1516356290173,
             "value": "example.demo.module-id"
             },
      "WorkMode": {
             "time": 1516347450295,
             "value": 0
             },
      "_sys_device_pid": {
             "time": 1516356290173,
             "value": "example.demo.partner-id"
             },
             "iotId": ""
    },
	...
]
```

### 13. <a name="13">Query upgrade device information list</a>

```
- (void)getAliOTAUpgradeDeviceList;

```


Return method name: onGetAliOTAUpgradeDeviceList, Parameter format:

```
{
	"data": [{
		"status": 1,
		"netType": "NET_WIFI",
		"image": "http:\/\/iotx-paas-admin.oss-cn-shanghai.aliyuncs.com\/publish\/image\/1526474600174.png",
		"iotId": "SrFIr31Ou4123456345000100",
		"deviceName": "mesh_light"
	}],
	"code": "200"
}
```

### 14. <a name="14">Upgrade wi-fi device</a>

```
// message is the iotId of the device, Format for ["iotId1","iotId2","iotId3".....]
- (void)aliUpgradeWifiDevice:(NSString *)message;
```

Return method name: onAliUpgradeWifiDevice, Parameter format:

```
{
	"data": "",
	"code": "200"
}
```

### 15. <a name="15">Device upgrade progress query</a>

```
// message is the iotId of a device, Format for "iotId1"
- (void)aliQueryDeviceUpgradeStatus:(NSString *)message;
```

Return method name: onAliQueryDeviceUpgradeStatus, Parameter format:

```
{
	"data": {
		"otaFirmwareDTO": {
			"desc": "",
			"md5": "c632cb3b2db912345567493fec96f628e",
			"currentVersion": "1.1.0",
			"size": "1544032",
			"currentTimestamp": 1567689273000,
			"version": "0.1.1",
			"timestamp": 1568102959000,
			"name": "test2",
			"url": "https:\/\/iotx-ota.oss-cn-shanghai.aliyuncs.com\/ota\/5ee5b4366534b9f490ad0970e2d59e0f\/ck0dk0h6q0000246uc6mxq0mv.bin?Expires=1568709521&OSSAccessKeyId=cS8uRRy54RszYWna&Signature=qiN0qhy4SpG4BepqlRGUwxY4dRs%3D"
		},
		"otaUpgradeDTO": {
			"iotId": "SrFIr31234565678Uzw6000100",
			"success": false,
			"needConfirm": false,
			"upgradeStatus": 0,
			"startTime": 1568623115000,
			"step": 0,
			"desc": "waiting"
		}
	},
	"code": "200"
}
```

### 16. <a name="16">Query the list of device information being upgraded</a>


```
- (void)getAliOTAIsUpgradingDeviceList;

```

Return method name: onGetAliOTAIsUpgradingDeviceList, Parameter format:

```
{
	"data": [{
            "iotId": "xxxx",
            "step": 10,
            "desc": "xxxxxx",
            "success": false,
            "needConfirm": true,
            "upgradeStatus": 0
        },
        {
            "iotId": "xxxx",
            "step": 10,
            "desc": "xxxxxx",
            "success": false,
            "needConfirm": true,
            "upgradeStatus": 0
        }],
	"code": "200"
}
```
















