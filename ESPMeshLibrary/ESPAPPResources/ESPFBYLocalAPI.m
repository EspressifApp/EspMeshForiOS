//
//  ESPFBYLocalAPI.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/9/3.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import "ESPFBYLocalAPI.h"
@interface ESPFBYLocalAPI ()<NativeApisProtocols,QRCodeReaderDelegate,BleDelegate>{
    BOOL isUDPScan;
    NSMutableDictionary* DevicesOfScanUDP;
    NSTimer *UPDTimer;
    
    NSTimer* BLETimer;
    NSMutableDictionary* ScanBLEDevices;
    BOOL isSendQueue;
    NSURLSessionTask *sessionTask;
}
@property (strong, nonatomic)UIViewController *localViewController;
@property (strong, nonatomic)NSTimer *OTATimer;
@end

@implementation ESPFBYLocalAPI

//单例模式
+ (instancetype)share {
    static ESPFBYLocalAPI *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[ESPFBYLocalAPI alloc]init];
    });
    return share;
}

- (JSContext *)getLocalJSContext:(JSContext *)context withLocalVC:(UIViewController *)localVC {
    isSendQueue = NO;
    context[@"espmesh"] = self;
    self.localViewController = localVC;
    ESPBLEHelper *espMesh = [ESPBLEHelper share];
    espMesh.delegate = self;
    return context;
}

- (void)deviceStatusChangeMonitoring {
    [[ESPUDP3232 share] starScan:^(NSString *type, NSString *mac) {
        if ([type containsString:@"http"]) {//http,https
            [self sendDeviceFoundOrLost:mac];
        } else if ([type containsString:@"status"]) {
            [self sendDeviceStatusChanged:mac];
        } else if ([type containsString:@"sniffer"]) {
            [self sendDeviceSnifferChanged:mac];
        }
    } failblock:^(int code) {}];
}

//APP版本检测
- (void)checkAppVersion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *appResultsDict = [[ESPCheckAppVersion sharedInstance] checkAppVersionNumber:ESPMeshAppleID];
        if (!ValidDict(appResultsDict)) {
            NSString* paramjson=[ESPDataConversion jsonFromObject:@{@"status":@"-1"}];
            [self.delegate sendLocalMsg:@"onCheckAppVersion" param:paramjson];
        }else {
            NSString *appStoreVersion = appResultsDict[@"version"];
            NSString *releaseNotesStr = appResultsDict[@"releaseNotes"];
            NSString* paramjson=[ESPDataConversion jsonConfigureFromObject:@{@"status":@"0",@"name":ESPMeshAppleID,@"version":appStoreVersion,@"notes":releaseNotesStr}];
            [self.delegate sendLocalMsg:@"onCheckAppVersion" param:paramjson];
        }
    });
}

//获取系统语言
- (void)getLocale {
    NSString *tmplanguageName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0];
    NSString *languageName=([tmplanguageName.lowercaseString containsString:@"zh"] ? @"zh":@"en");
    
    NSString* paramjson=[ESPDataConversion jsonFromObject:@{@"language":languageName,@"country":languageName,@"os":@"ios"}];
    [self.delegate sendLocalMsg:@"onLocaleGot" param:paramjson];
}

// 初始化视图
- (void)hideCoverImage {
    [self.delegate hideGuidePageView];
}

// 获取APP版本信息
- (void)getAppInfo {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    // app build版本
    //    NSString *app_build = [infoDictionary objectForKey:@"CFBundleVersion"];
    NSString* json=[ESPDataConversion jsonFromObject:@{@"version_name":app_Version,@"version_code":app_Version}];
    [self.delegate sendLocalMsg:@"onGetAppInfo" param:json];
}

//JS 注册系统通知
- (void)registerPhoneStateChange {
    dispatch_queue_t queue = dispatch_queue_create("my.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        //获取蓝牙状态
        [self isBluetoothEnable];
        //程序进入前台并处于活动状态调用
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendWifiStatus) name:UIApplicationDidBecomeActiveNotification object:nil];
        //注册Wi-Fi变化通知
        AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
        [manager startMonitoring];
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            [self sendWifiStatus];
        }];
    });
}
- (void)bleUpdateStatusBlock:(CBCentralManager *)central {
    NSDictionary *bleResultDic;
    if (central.state != CBManagerStatePoweredOn) {
        bleResultDic = @{@"enable":@false};
    }else if (central.state != CBManagerStatePoweredOff) {
        bleResultDic = @{@"enable":@true};
    }
    if (ValidDict(bleResultDic)) {
        [self appBleStateCallBack:bleResultDic];
    }
}
//判断手机蓝牙是否打开
- (void)isBluetoothEnable {
    //返回true/false
    bool bleStatusBool=[[BabyBluetooth shareBabyBluetooth] centralManager].state==5 ? true:false;
    NSString *paramjson=[ESPDataConversion jsonFromObject:@{@"enable":@(bleStatusBool)}];
    [self.delegate sendLocalMsg:@"onBluetoothStateChanged" param:paramjson];
}
//蓝牙变化通知
- (void)appBleStateCallBack:(NSDictionary *)message {
    NSString *paramjson=[ESPDataConversion jsonFromObject:message];
    [self.delegate sendLocalMsg:@"onBluetoothStateChanged" param:paramjson];
}

//wifi状态变化回掉
-(void)sendWifiStatus{
    [ESPDataConversion sendAPPWifiStatus:^(NSString * _Nonnull message) {
        [self.delegate sendLocalMsg:@"onWifiStateChanged" param:message];
    }];
}

//开启UDP扫描
- (void)scanDevicesAsync {
    isUDPScan=true;
    DevicesOfScanUDP=[NSMutableDictionary dictionaryWithCapacity:0];
    UPDTimer=[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(sendUDPResult) userInfo:nil repeats:false];
    [[NSRunLoop mainRunLoop] addTimer:UPDTimer forMode:NSDefaultRunLoopMode];
    [ESPAPPResources scanDevicesAsyncSuccess:^(NSDictionary * _Nonnull DevicesAsyncDic) {
        NSArray *onDeviceScanning = [DevicesAsyncDic objectForKey:@"onDeviceScanningResult"];
        if (onDeviceScanning != nil) {
            NSString* tmpjson=[ESPDataConversion jsonFromObject:onDeviceScanning];
            [self.delegate sendLocalMsg:@"onDeviceScanning" param:tmpjson];
        }else {
            DevicesOfScanUDP=[[NSMutableDictionary alloc]initWithDictionary:DevicesAsyncDic];
            [self sendUDPResult];
        }
    } andFailure:^(int fail) {
        switch (fail) {
            case 8010:
                [self sendUDPResult];
                break;
            case 8011:
                [self DevicesOfScanUDPData];
                [self sendUDPResult];
                break;
            case 8012:
                [self DevicesOfScanUDPData];
                [self sendUDPResult];
                break;
            default:
                break;
        }
    }];
}
//UDP Scan超时或者失败反馈
-(void)sendUDPResult{
    
    //    [[ESPMeshManager share] cancelScanRootUDP];
    //    [[ESPMeshManager share] cancelScanRootmDNS];
    [UPDTimer invalidate];
    if (DevicesOfScanUDP.count>0) {
        NSMutableArray* sendInfo=[NSMutableArray arrayWithCapacity:0];
        for (EspDevice* item in DevicesOfScanUDP.allValues) {
            [sendInfo addObject:item.sendInfo];
        }
        
        NSString* json=[ESPDataConversion jsonFromObject:sendInfo];
        [self.delegate sendLocalMsg:@"onDeviceScanned" param:json];
    }else{
        [self.delegate sendLocalMsg:@"onDeviceScanned" param:@"[]"];
    }
    isUDPScan=false;
}
- (void)DevicesOfScanUDPData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *keyData = [defaults objectForKey:@"DevicesOfScanUDPKeyArr"];
    NSArray *valueData = [defaults objectForKey:@"DevicesOfScanUDPValueArr"];
    for (int i = 0; i < keyData.count; i ++) {
        EspDevice *newDevice = [[EspDevice alloc]init];
        newDevice.sendInfo = valueData[i];
        self->DevicesOfScanUDP[keyData[i]]=newDevice;
    }
}
//hwdevice_table表  保存本地配对信息
- (void)saveHWDevice:(NSString *)message {
    [ESPFBYDataBase saveHWDevicefby:message];
}
- (void)saveHWDevices:(NSString *)message {
    [ESPFBYDataBase saveHWDevicesfby:message];
}
- (void)deleteHWDevice:(NSString *)message {
    [ESPFBYDataBase deleteHWDevicefby:message];
}
- (void)deleteHWDevices:(NSString *)message {
    [ESPFBYDataBase deleteHWDevicesfby:message];
}
- (void)loadHWDevices {
    NSString *json = [ESPFBYDataBase loadHWDevicesfby];
    [self.delegate sendLocalMsg:@"onLoadHWDevices" param:json];
}

//关闭蓝牙扫描
- (void)stopBleScan {
    if (BLETimer) {
        [BLETimer invalidate];
        BLETimer=nil;
    }
    [[ESPMeshManager share] cancelScanBLE];
}
//开启蓝牙扫描
- (void)startBleScan {
    //    [self sendBLEResult];
    ScanBLEDevices=[NSMutableDictionary dictionaryWithCapacity:0];
    if (BLETimer) {
        [BLETimer invalidate];
        BLETimer=nil;
    }
    BLETimer=[NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(sendBLEResult) userInfo:nil repeats:true];
    [[NSRunLoop mainRunLoop] addTimer:BLETimer forMode:NSDefaultRunLoopMode];
    [ESPAPPResources startBleScanSuccess:^(NSDictionary * _Nonnull BleScanDic) {
        NSString *bssid = [BleScanDic objectForKey:@"bssid"];
        self->ScanBLEDevices[bssid] = BleScanDic;
    } andFailure:^(int fail) {
        
    }];
}
-(void)sendBLEResult{
    if (ScanBLEDevices.count>0) {
        NSMutableArray *tmpArr = [NSMutableArray arrayWithCapacity:0];
        NSArray *allKeyArr = ScanBLEDevices.allKeys;
        for (int i = 0; i < allKeyArr.count; i ++) {
            [tmpArr addObject:ScanBLEDevices[allKeyArr[i]]];
        }
        NSMutableArray* sendArr = [NSMutableArray arrayWithCapacity:0];
        for (int i=0; i<tmpArr.count; i++) {
            
            if (ValidDict(tmpArr[i])) {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:tmpArr[i]];
                [dict removeObjectForKey:@"device"];
                [sendArr addObject:dict];
            }
        }
        NSString* json=[ESPDataConversion jsonFromObject:sendArr];
        [self.delegate sendLocalMsg:@"onScanBLE" param:json];
    }
}

//APP版本更新
- (void)appVersionUpdate:(NSString *)message {
    BOOL updateBool = [[ESPCheckAppVersion sharedInstance] appVersionUpdate];
    if (updateBool) {
        NSString* paramjson=[ESPDataConversion jsonFromObject:@{@"status":@"0",@"message":@"更新成功"}];
        [self.delegate sendLocalMsg:@"onCheckAppVersion" param:paramjson];
    }else {
        NSString* paramjson=[ESPDataConversion jsonFromObject:@{@"status":@"-1",@"message":@"更新失败"}];
        [self.delegate sendLocalMsg:@"onCheckAppVersion" param:paramjson];
    }
}

//获取topo结构
- (void)scanTopo {
    [ESPDataConversion scanDeviceTopo:^(NSArray * _Nonnull resultArr) {
        NSString* json=[ESPDataConversion jsonFromObject:resultArr];
        [self.delegate sendLocalMsg:@"onTopoScanned" param:json];
    } andFailure:^(int fail) {
        NSString* json=[ESPDataConversion jsonFromObject:@[]];
        [self.delegate sendLocalMsg:@"onTopoScanned" param:json];
    }];
}
//更新房间信息
- (void)updateDeviceGroup:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    [ESPDataConversion updateGroupInformation:msg];
}
//发送多个设备命令防止重复操作
- (void)addQueueTask:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    isSendQueue = YES;
    
    if ([[msg objectForKey:@"method"] isEqualToString:[NSString stringWithFormat:@"requestDevicesMulticast"]]) {
        [self requestDevicesMulticast:[msg objectForKey:@"argument"]];
    } else if ([[msg objectForKey:@"method"] isEqualToString:[NSString stringWithFormat:@"requestDevice"]]) {
        [self requestDevice:[msg objectForKey:@"argument"]];
    }
}

//发送多设备命令
- (void)requestDevicesMulticast:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSMutableDictionary *messageDic = [[NSMutableDictionary alloc]initWithDictionary:msg];
    messageDic[@"isSendQueue"] = @(isSendQueue);
    [ESPAPPResources requestDevicesMulticastAsync:messageDic andSuccess:^(NSDictionary * _Nonnull dic) {
        NSMutableDictionary *resultDic = [[NSMutableDictionary alloc]initWithDictionary:dic];
        NSString *callbackStr = [resultDic objectForKey:@"callbackStr"];
        [resultDic removeObjectForKey:@"callbackStr"];
        NSString *json = [ESPDataConversion jsonFromObject:resultDic];
        [self.delegate sendLocalMsg:callbackStr param:json];
    } andFailure:^(NSDictionary * _Nonnull failureDic) {
        int code = [[failureDic objectForKey:@"code"] intValue];
        if (code == 8010) {
            NSString *callBackStr = [failureDic objectForKey:@"callbackStr"];
            [self.delegate sendLocalMsg:callBackStr param:@""];
        }else if (code == 8011) {
            NSString *macsStr = [failureDic objectForKey:@"resetMacsStr"];
            [self->DevicesOfScanUDP removeObjectForKey:macsStr];
        }
    }];
    isSendQueue = NO;
}
//发送单个设备命令
- (void)requestDevice:(NSString *)message {
    [self requestDevicesMulticast:message];
}
//表  Group组
- (void)saveGroup:(NSString *)message {
    id key = [ESPFBYDataBase saveGroupfby:message];
    if (key == nil) {
        return;
    }
    [self.delegate sendLocalMsg:@"onSaveGroup" param:key];
}
- (void)saveGroups:(NSString *)message {
    [ESPFBYDataBase saveGroupsfby:message];
}
- (void)loadGroups {
    NSString *json = [ESPFBYDataBase loadGroupsfby];
    [self.delegate sendLocalMsg:@"onLoadGroups" param:json];
}
- (void)deleteGroup:(NSString *)message {
    [ESPFBYDataBase deleteGroupfby:message];
}
//Mac  Mac表
- (void)saveMac:(NSString *)message {
    [ESPFBYDataBase saveMacfby:message];
}
- (void)deleteMac:(NSString *)message {
    [ESPFBYDataBase deleteMacfby:message];
}
- (void)deleteMacs:(NSString *)message {
    [ESPFBYDataBase deleteMacsfby:message];
}
- (void)loadMacs {
    NSString* json=[ESPFBYDataBase loadMacsfby];
    [self.delegate sendLocalMsg:@"onLoadMacs" param:json];
}
//获取配网记录
- (void)loadAPs {
    NSArray* dataArr=[ESPFBYDataBase getAllItemsFromTablefby:@"ap_table"];
    NSMutableArray* needArr=[NSMutableArray arrayWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
        [needArr addObject:item];
    }
    NSString* json=[ESPDataConversion jsonFromObject:needArr];
    [self.delegate sendLocalMsg:@"onLoadAPs" param:json];
}
//蓝牙配网
- (void)startConfigureBlufi:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (!ValidDict(msg)) {
        NSString* json=[ESPDataConversion jsonFromObject:@{@"progress":@"0",@"code":@0,@"message":@"参数有误"}];
        [self.delegate sendLocalMsg:@"onConfigureProgress" param:json];
        return;
    }
    NSDictionary* argsDic=[[NSMutableDictionary alloc]initWithDictionary:msg];
    NSDictionary *deviceInfo = ScanBLEDevices[argsDic[@"ble_addr"]];
    // 蓝牙连接
    [ESPAPPResources BleConnection:deviceInfo andSuccess:^(NSDictionary * _Nonnull dic) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:dic];
        [self.delegate sendLocalMsg:@"onConfigureProgress" param:json];
        int code = [[dic objectForKey:@"code"] intValue];
        if (code == NotificationSuccessful) {
            // 发送协商加密
            [[ESPMeshManager share] sendDevicesNegotiatesEncryption];
        }else if (code == NegotiateSecuritykeySuccessful) {
            // 通知设备进入加密模式
            [[ESPMeshManager share] notifyDevicesToEnterEncryptionMode];
            // 蓝牙配网
            [ESPAPPResources startBLEConfigure:argsDic andSuccess:^(NSDictionary * _Nonnull dic) {
                NSString *code = [dic objectForKey:@"code"];
                if ([code isEqualToString:@"-8010"]) {
                    NSDictionary *deviceBind = [dic objectForKey:@"deviceBind"];
                    NSString* json=[ESPDataConversion jsonConfigureFromObject:deviceBind];
                    [self.delegate sendLocalMsg:@"onAliDeviceBind" param:json];
                }else {
                    NSString* json=[ESPDataConversion jsonConfigureFromObject:dic];
                    [self.delegate sendLocalMsg:@"onConfigureProgress" param:json];
                }
            } andFailure:^(NSDictionary * _Nonnull dic) {
                NSString* json=[ESPDataConversion jsonFromObject:@{@"progress":@"69",@"code":@0,@"message":@"配网失败"}];
                [self.delegate sendLocalMsg:@"onConfigureProgress" param:json];
            }];
        }else if (code == CustomDataBlock) {
            NSLog(@"设备接收到自定义数据的回复：%@",[dic objectForKey:@"message"]);
        }
    } andFailure:^(NSDictionary * _Nonnull dic) {
        NSString* json=[ESPDataConversion jsonFromObject:@{@"progress":@"39",@"code":@0,@"message":@"蓝牙连接失败"}];
        [self.delegate sendLocalMsg:@"onConfigureProgress" param:json];
    }];
}
- (void)stopConfigureBlufi {
    [[ESPMeshManager share] cancleBLEPair];
}
//meshId表
- (void)saveMeshId:(NSString *)message {
    [ESPFBYDataBase saveMeshIdfby:message];
}
- (void)deleteMeshId:(NSString *)message {
    [ESPFBYDataBase deleteMeshIdfby:message];
}
- (void)loadLastMeshId {
    
    NSString *meshid = [ESPFBYDataBase loadLastMeshIdfby];
    [self.delegate sendLocalMsg:@"onLoadLastMeshId" param:meshid];
}
- (void)loadMeshIds {
    NSString* json=[ESPFBYDataBase loadMeshIdsfby];
    [self.delegate sendLocalMsg:@"onLoadMeshIds" param:json];
}
//设备升级
- (void)startOTA:(NSString *)message {
    [ESPAPPResources startOTA:message Success:^(NSDictionary * _Nonnull startOTADic) {
        int type = [[startOTADic objectForKey:@"type"] intValue];
        sessionTask = [startOTADic objectForKey:@"sessionTask"];
        NSArray *startOTAArr = [startOTADic objectForKey:@"jsonArr"];
        NSString* json=[ESPDataConversion jsonFromObject:startOTAArr];
        [self.delegate sendLocalMsg:@"onOTAProgressChanged" param:json];
        if (type == 0) {
            NSOperationQueue* op = [NSOperationQueue mainQueue];
            [op addOperationWithBlock:^{
                if (self.OTATimer) {
                    [self.OTATimer invalidate];
                    self.OTATimer = nil;
                }
                self.OTATimer = [NSTimer scheduledTimerWithTimeInterval:7 target:self selector:@selector(requestOTAProgress) userInfo:nil repeats:true];
                [[NSRunLoop mainRunLoop] addTimer:self.OTATimer forMode:NSDefaultRunLoopMode];
            }];
        }
    } andFailure:^(int fail) {
        NSString* json=[ESPDataConversion jsonFromObject:@[]];
        [self.delegate sendLocalMsg:@"onOTAResult" param:json];
    }];
}
- (void)requestOTAProgress {
    [ESPAPPResources networkRequestOTAProgress:^(NSDictionary * _Nonnull startOTADic) {
        int type = [[startOTADic objectForKey:@"type"] intValue];
        sessionTask = [startOTADic objectForKey:@"sessionTask"];
        NSArray *startOTAArr = [startOTADic objectForKey:@"jsonArr"];
        NSString* json=[ESPDataConversion jsonFromObject:startOTAArr];
        if (type == 0) {
            [self.delegate sendLocalMsg:@"onOTAProgressChanged" param:json];
        }else if (type == 1) {
            [self.delegate sendLocalMsg:@"onOTAResult" param:json];
            [self.OTATimer invalidate];
        }
    } andFailure:^(int fail) {
        if (fail == 8010) {
            NSString* json=[ESPDataConversion jsonFromObject:@[]];
            [self.delegate sendLocalMsg:@"onOTAResult" param:json];        }else if (fail == 8011) {
            NSString* json=[ESPDataConversion jsonFromObject:@[]];
            [self.delegate sendLocalMsg:@"onOTAResult" param:json];
        }
        [self.OTATimer invalidate];
    }];
    
}

//下载设备升级文件
- (void)downloadLatestRom {
    [ESPDataConversion downloadDeviceOTAFiles:^(NSString * _Nonnull successMsg) {
        NSString *paramjson=[ESPDataConversion jsonFromObject:@{@"download":@(true),@"file":successMsg}];
        [self.delegate sendLocalMsg:@"onDownloadLatestRom" param:paramjson];
    } andFailure:^(int fail) {
        NSString *paramjson=[ESPDataConversion jsonFromObject:@{@"download":@(false),@"file":@"下载失败"}];
        [self.delegate sendLocalMsg:@"onDownloadLatestRom" param:paramjson];
    }];
}
//获取本地升级文件
- (void)getUpgradeFiles {
    ESPDocumentsPath *espDocumentPath = [[ESPDocumentsPath alloc]init];
    NSArray *filePathArr = [espDocumentPath documentFileName];
    if (filePathArr == nil) {
        NSString *paramjson=[ESPDataConversion jsonFromObject:@[]];
        [self.delegate sendLocalMsg:@"onGetUpgradeFiles" param:paramjson];
    }else{
        NSString *paramjson=[ESPDataConversion jsonFromObject:filePathArr];
        [self.delegate sendLocalMsg:@"onGetUpgradeFiles" param:paramjson];
    }
}
//停止OTA升级
- (void)stopOTA:(NSString *)message {
    [ESPAPPResources stopOTA:message withSessionTask:sessionTask];
}
//重启设备命令
- (void)reboot:(NSString *)message {
    [ESPAPPResources reboot:message];
}
- (void)clearBleCache {
}
- (void)removeDevicesForMacs:(NSString *)message {
}
//文件 Key - Value 增删改查
- (void)saveValuesForKeysInFile:(NSString *)message {
    [ESPFBYDataBase saveValuesForKeysInFilefby:message];
}
- (void)removeValuesForKeysInFile:(NSString *)message {
    [ESPFBYDataBase removeValuesForKeysInFilefby:message];
}
- (void)loadValueForKeyInFile:(NSString *)message {
    NSString* json=[ESPFBYDataBase loadValueForKeyInFilefby:message];
    if (json == nil) {
        return;
    }
    [self.delegate sendLocalMsg:@"onLoadValueForKeyInFile" param:json];
}
- (void)loadAllValuesInFile:(NSString *)message {
    NSString* json=[ESPFBYDataBase loadAllValuesInFilefby:message];
    if (json == nil) {
        return;
    }
    id msg=[ESPDataConversion objectFromJsonString:message];
    NSString *callBack = [msg objectForKey:@"callback"];
    [self.delegate sendLocalMsg:callBack param:json];
}
//保存本地事件
- (void)saveDeviceEventsCoordinate:(NSString *)message {
    [ESPFBYDataBase saveDeviceEventsCoordinatefby:message];
}
- (void)loadDeviceEventsCoordinate:(NSString *)message {
    NSString* json=[ESPFBYDataBase loadDeviceEventsCoordinatefby:message];
    if (json == nil) {
        return;
    }
    id msg=[ESPDataConversion objectFromJsonString:message];
    NSString *callback=[msg objectForKey:@"callback"];
    [self.delegate sendLocalMsg:callback param:[json URLEncodedString]];
}
- (void)loadAllDeviceEventsCoordinate:(NSString *)message {
    NSString* json=[ESPFBYDataBase loadAllDeviceEventsCoordinatefby:message];
    if (json == nil) {
        return;
    }
    id msg=[ESPDataConversion objectFromJsonString:message];
    NSString *callback=[msg objectForKey:@"callback"];
    [self.delegate sendLocalMsg:callback param:json];
}
- (void)deleteDeviceEventsCoordinate:(NSString *)message {
    [ESPFBYDataBase deleteDeviceEventsCoordinatefby:message];
}
- (void)deleteAllDeviceEventsCoordinate {
    [ESPFBYDataBase deleteAllDeviceEventsCoordinatefby];
}
//table信息存储(ipad)
- (void)saveDeviceTable:(NSString *)message {
    [ESPFBYDataBase saveDeviceTablefby:message];
}
- (void)loadDeviceTable {
    NSString *itemStr = [ESPFBYDataBase loadDeviceTablefby];
    [self.delegate sendLocalMsg:@"onLoadDeviceTable" param:itemStr];
}

//table设备信息存储(ipad)
- (void)saveTableDevices:(NSString *)message {
    [ESPFBYDataBase saveTableDevicesfby:message];
}
- (void)loadTableDevices {
    NSString *json = [ESPFBYDataBase loadTableDevicesfby];
    [self.delegate sendLocalMsg:@"onLoadTableDevices" param:json];
}
- (void)removeTableDevices:(NSString *)message {
    [ESPFBYDataBase removeTableDevicesfby:message];
}
- (void)removeAllTableDevices {
    [ESPFBYDataBase removeAllTableDevicesfby];
}
//跳转系统设置页面
- (void)gotoSystemSettings:(NSString *)message {
    [[ESPCheckAppVersion sharedInstance] gotoSystemSetting];
}

//加载超链接
- (void)newWebView:(NSString *)message {
    ESPLoadHyperlinksViewController *loadHyperlinks = [[ESPLoadHyperlinksViewController alloc]init];
    loadHyperlinks.webURL = message;
    [self.localViewController presentViewController:loadHyperlinks animated:YES completion:nil];
}
//扫描二维码
- (void)scanQRCode {
    if ([QRCodeReader supportsMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]]) {
        static QRCodeReaderViewController *vc = nil;
        static dispatch_once_t onceToken;
        
        dispatch_once(&onceToken, ^{
            QRCodeReader *reader = [QRCodeReader readerWithMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
            vc                   = [QRCodeReaderViewController readerWithCancelButtonTitle:@"Cancel" codeReader:reader startScanningAtLoad:YES showSwitchCameraButton:YES showTorchButton:YES];
            vc.modalPresentationStyle = UIModalPresentationFormSheet;
        });
        vc.delegate = self;
        
        [vc setCompletionWithBlock:^(NSString *resultAsString) {
            NSLog(@"二维码结果: %@", resultAsString);
            [self.delegate sendLocalMsg:@"onQRCodeScanned" param:resultAsString];
        }];
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self.localViewController presentViewController:vc animated:YES completion:NULL];
        });
    }else {
        [self.delegate sendLocalMsg:@"onQRCodeScanned" param:@"当前设备不支持二维码扫描"];
    }
}
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result{
    [reader stopScanning];
    
    [self.localViewController dismissViewControllerAnimated:YES completion:^{
    }];
}
- (void)readerDidCancel:(QRCodeReaderViewController *)reader {
    [self.localViewController dismissViewControllerAnimated:YES completion:NULL];
}

//本地 (app) 和阿里云 (cloud) 页面加载
- (void)mainPageLoad:(NSString *)message {
    [ESPDataConversion fby_saveNSUserDefaults:message withKey:@"mainPageLoad"];
    [self.delegate webViewLoadMainPage:message];
}

//设置状态栏背景颜色和字体颜色
- (void)setStatusBar:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    [ESPDataConversion setSystemStatusBar:msg];
}

//设备状态变化上报
-(void)sendDeviceStatusChanged:(NSString*)mac{
    if (isUDPScan) {
        return;
    }
    isUDPScan=true;
    NSMutableDictionary *msgDic = [NSMutableDictionary dictionaryWithCapacity:0];
    msgDic[@"deviceMac"] = mac;
    msgDic[@"devicesOfScanUDP"] = DevicesOfScanUDP;
    
    [ESPDataConversion sendDevicesStatusChanged:msgDic withDeviceStatusSuccess:^(NSDictionary * _Nonnull statusResultDic) {
        DevicesOfScanUDP = statusResultDic[@"scanUDPDic"];
        NSString* json=[ESPDataConversion jsonFromObject:statusResultDic[@"resultDic"]];
        [self.delegate sendLocalMsg:@"onDeviceStatusChanged" param:json];
        isUDPScan=false;
    } andFailure:^(int fail) {
        isUDPScan=false;
    }];
}

//设备http变化上报
-(void)sendDeviceFoundOrLost:(NSString*)mac{
    
    if (isUDPScan) {
        return;
    }
    isUDPScan=true;
    NSMutableDictionary *msgDic = [NSMutableDictionary dictionaryWithCapacity:0];
    msgDic[@"deviceMac"] = mac;
    msgDic[@"devicesOfScanUDP"] = DevicesOfScanUDP;
    [ESPDataConversion sendDevicesFoundOrLost:msgDic withDeviceStatusSuccess:^(NSDictionary * _Nonnull statusResultDic) {
        NSString *code = [statusResultDic objectForKey:@"code"];
        if ([code intValue] == 8011) {
            NSString *json = [statusResultDic objectForKey:@"result"];
            NSLog(@"设备上线：%@", json);
            [self.delegate sendLocalMsg:@"onDeviceFound" param:json];
        }else if ([code intValue] == 8012) {
            NSString *json = [statusResultDic objectForKey:@"result"];
            NSLog(@"设备下线：%@",json);
            [self.delegate sendLocalMsg:@"onDeviceLost" param:json];
        }else if ([code intValue] == 8013) {
            NSMutableDictionary *newDevices = [NSMutableDictionary dictionaryWithDictionary:statusResultDic[@"result"]];
            self->DevicesOfScanUDP=newDevices;
        }
        isUDPScan=false;
    } andFailure:^(int fail) {
        isUDPScan=false;
    }];
}

//设备Sniffer变化上报
- (void)sendDeviceSnifferChanged:(NSString*)mac{
    [ESPDataConversion sendDeviceSnifferInfo:mac withSnifferSuccess:^(NSArray * _Nonnull snifferResultArr) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:snifferResultArr];
        [self.delegate sendLocalMsg:@"onSniffersDiscovered" param:json];
    } andFailure:^(int fail) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:@[]];
        [self.delegate sendLocalMsg:@"onSniffersDiscovered" param:json];
    }];
}
@end
