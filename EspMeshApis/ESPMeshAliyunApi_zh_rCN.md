[[English]](ESPMeshAliyunApi_en.md)

# ESP-Mesh Aliyun Api

## 一：接口目录

1. <a href="#1">用户登录</a>
2. <a href="#2">用户登出</a>
3. <a href="#3">用户是否登录</a>
4. <a href="#4">用户登录信息</a>
5. <a href="#5">获取阿里云绑定设备列表</a>
6. <a href="#6">发现本地的已配网设备列表</a>
7. <a href="#7">停止发现设备</a>
8. <a href="#8">设备绑定</a>
9. <a href="#9">设备解绑</a>
10. <a href="#10">获取设备状态</a>
11. <a href="#11">获取设备属性</a>
12. <a href="#12">修改设备属性</a>
13. <a href="#13">查询升级设备信息列表</a>
14. <a href="#14">升级Wi-Fi设备</a>
15. <a href="#15">设备升级进度查询</a>
16. <a href="#16">查询正在升级的设备信息列表</a>
17. <a href="#17">用户绑定淘宝Id</a>
18. <a href="#18">查询用户绑定的淘宝Id</a>
19. <a href="#19">用户解绑淘宝Id</a>

## 二：接口详情

### 1. <a name="1">用户登录</a>

```
- (void)aliUserLogin;
```

返回数据方法名：onAliUserLogin，参数格式：

```
{"mobileLocationCode":"86","mobile":"13661215411","accountId":707374,"oauthInfoDict":{"SidExpiredTime":1650874674},"hasPassword":true,"openaccountInfoDict":{"mobile":"13661617154","enableDevice":"true","pwdVersion":0,"id":707374,"mobileLocationCode":"86","status":1,"domainId":8191367,"mobileConflictAccount":"false","subAccount":"false","hasPassword":"true"}}
```

### 2. <a name="2">用户登出</a>

```
- (void)aliUserLogout;
```

无返回参数

### 3. <a name="3">用户是否登录</a>

```
- (void)isAliUserLogin;
```
返回数据方法名：onIsAliUserLogin，参数格式：

```
{"isLogin":true}
```

### 4. <a name="4">用户登录信息</a>

```
- (void)getAliUserInfo;
```

返回数据方法名：onGetAliUserInfo，参数格式：

```
{"mobileLocationCode":"86","mobile":"13661215411","accountId":707374,"oauthInfoDict":{"SidExpiredTime":1650874674},"hasPassword":true,"openaccountInfoDict":{"mobile":"13661617154","enableDevice":"true","pwdVersion":0,"id":707374,"mobileLocationCode":"86","status":1,"domainId":8191367,"mobileConflictAccount":"false","subAccount":"false","hasPassword":"true"}}
```

### 5. <a name="5">获取阿里云绑定设备列表</a>

```
- (void)getAliDeviceList;
```

返回数据方法名：onGetAliyunDeviceList，参数格式：

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

### 6. <a name="6">发现本地的已配网设备列表</a>

```
- (void)aliStartDiscovery;
```

返回数据方法名：onAliStartDiscovery，参数格式：

```
{
[]
}
```


### 7. <a name="7">停止发现设备</a>

```
- (void)aliStopDiscovery;
```

无返回参数

### 8. <a name="8">设备绑定</a>

```
// message为待绑定设备获取到的信息，格式为{"productKey":"","deviceName":"","token":""}
- (void)aliDeviceBinding:(NSString *)message;
```

返回数据方法名：onAliDeviceBind参数格式：

```
// 成功格式onAliDeviceBind
{
"code":"8000",//8010:有失败提示和失败原因，8011:有失败提示无失败原因
"iotId":""
"deviceInfo":{
	"productKey":"",
	"deviceName":"",
	"token":""
	}
}
```

### 9. <a name="9">设备解绑</a>

```
// message为解绑设备iotId，格式为["iotId1","iotId2","iotId3".....]
- (void)aliDeviceUnbindRequest:(NSString *)message;
```
无参数返回

### 10. <a name="10">获取设备状态</a>

```
// message为设备iotId，格式为["iotId1","iotId2","iotId3".....]
- (void)getAliDeviceStatus:(NSString *)message;
```

返回数据方法名：onGetAliDeviceStatus 参数格式：

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

说明：status表示设备生命周期，目前有以下几个状态，0:未激活；1：上线；3：离线；8：禁用；time表示当前状态的开始时间；

### 11. <a name="11">获取设备属性</a>


```
// message为设备iotId，格式为["iotId1","iotId2","iotId3".....]
- (void)getAliDeviceProperties:(NSString *)message;
```

返回数据方法名：onGetAliDeviceProperties 参数格式：

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

### 12. <a name="12">修改设备属性</a>


```
// message为设备iotId，格式为{"iotId":["iotId1","iotId2","iotId3".....],"properties":{"Brightness":90}}
- (void)setAliDeviceProperties:(NSString *)message;
```

修改颜色properties数据格式为：


```
{
"HSVColor":{"Hue":0,
             "Saturation":0,
             "Value":0
             }
}                             
```

修改开关properties数据格式为：

```
//关
{"LightSwitch":0}
//开
{"LightSwitch":1}
```

返回数据方法名：onSetAliDeviceProperties 参数格式：

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

### 13. <a name="13">查询升级设备信息列表</a>

```
// 获取升级设备信息列表
- (void)getAliOTAUpgradeDeviceList;

```


返回方法名：onGetAliOTAUpgradeDeviceList，返回参数格式

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

### 14. <a name="14">升级Wi-Fi设备</a>

```
// message为设备iotId，格式为["iotId1","iotId2","iotId3".....]
- (void)aliUpgradeWifiDevice:(NSString *)message;
```

返回方法名：onAliUpgradeWifiDevice，返回参数格式

```
{
	"data": "",
	"code": "200"
}
```

### 15. <a name="15">设备升级进度查询</a>

```
// message 为单个设备iotId，格式为"iotId1"
- (void)aliQueryDeviceUpgradeStatus:(NSString *)message;
```

返回方法名：onAliQueryDeviceUpgradeStatus，返回参数格式

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

### 16. <a name="16">查询正在升级的设备信息列表</a>


```
// 获取升级设备信息列表
- (void)getAliOTAIsUpgradingDeviceList;

```

返回方法名：onGetAliOTAIsUpgradingDeviceList，返回参数格式

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

### 17. <a name="17">用户绑定淘宝Id</a>

```
// 用户绑定淘宝Id
- (void)aliUserBindTaobaoId;
```

返回方法名：onAliUserBindTaobaoId，返回参数格式

```
{
	"data": {
		"accountId": "2518246212",
		"accountType": "TAOBAO",
		"linkIdentityIds": [
			"50cbop901db40de4a**********f89728bf80584"
			]
	},
	"code": "200"
}
```

### 18. <a name="18">查询用户绑定的淘宝Id</a>

```
// 查询用户绑定的淘宝Id 此处message = {"accountType":"TAOBAO"}
- (void)getAliUserId:(NSString *)message;
```

返回方法名：onGetAliUserId，返回参数格式

```
{
	"data": {
		"accountId": "795255212",
		"accountType": "TAOBAO",
		"linkIdentityIds": "50cbop901db40de4a**********f89728bf80584"
	},
	"accountType": "TAOBAO",
	"code": "200"
}
```

### 19. <a name="19">用户解绑淘宝Id</a>

```
// 用户解绑淘宝Id 此处message = {"accountType":"TAOBAO"}
- (void)aliUserUnbindId:(NSString *)message;
```

返回方法名：onAliUserUnbindId，返回参数格式

```
{
	"data": {
		"message": "remove account link success!"
	},
	"accountType": "TAOBAO",
	"code": "200"
}
```













