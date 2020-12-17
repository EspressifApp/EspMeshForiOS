//
//  ESPAPPResources.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/2/28.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import "ESPAPPResources.h"
#import "ESPDataConversion.h"
#import "EspActionDeviceInfo.h"
#import "EspDeviceUtil.h"

#import "ESPUploadHandleTool.h"
#import "ESPDocumentsPath.h"
#import "ESPFBYDataBase.h"
#import "ESPAliyunSDKUse.h"

#define ValidDict(f) (f!=nil && [f isKindOfClass:[NSDictionary class]])
#define ValidArray(f) (f!=nil && [f isKindOfClass:[NSArray class]] && [f count]>0)

@interface ESPAPPResources ()

@end

@implementation ESPAPPResources
//开启蓝牙扫描
+ (void)startBleScanSuccess:(BleScanSuccessBlock)success andFailure:(void (^)(int))failure{
    dispatch_queue_t queue = dispatch_queue_create("my.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        [[ESPMeshManager share] starScanBLE:^(EspDevice *device) {
            //        NSLog(@"device ouiMDF---->%@", device.ouiMDF);
            NSMutableDictionary *deviceDic = [NSMutableDictionary dictionaryWithCapacity:0];
            deviceDic[@"mac"] = device.bssid;
            deviceDic[@"name"] = device.name;
            deviceDic[@"rssi"] = [NSString stringWithFormat:@"%d",device.RSSI];
            deviceDic[@"device"] = device;
            deviceDic[@"version"] = device.version;
            deviceDic[@"bssid"] = device.bssid;
            deviceDic[@"beacon"] = device.ouiMDF;
            deviceDic[@"tid"] = device.deviceTid;
            deviceDic[@"only_beacon"] = @(device.onlyBeacon);
            success(deviceDic);
        } failblock:^(int code) {
            NSLog(@"蓝牙未打开");
        }];
    });
}

//关闭蓝牙扫描
+ (void)stopBleScan {
    [[ESPMeshManager share] cancelScanBLE];
}

+ (void)BleConnection:(NSDictionary *)deviceInfo andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(NSDictionary * _Nonnull))failure {
    
    if (deviceInfo ==nil ) {
        NSDictionary *failDic = @{@"progress":@"0",@"code":@0,@"message":@"蓝牙连接失败"};
        failure(failDic);
        return;
    }else{
        EspDevice* tmpDevice = deviceInfo[@"device"];
        static int pairProgress = 5;
        
        [[ESPMeshManager share] starBLEPair:tmpDevice withIsBleConnect:YES callBackBlock:^(NSString *msg) {
            NSLog(@"msg:::::::%@",msg);
            NSDictionary* logMsg;
            if (pairProgress >= 70) {
                //                self->pairProgress=[NSNumber numberWithInt:self->pairProgress.intValue+1];
            }else{
                pairProgress = pairProgress + 5;
            }
            NSArray *messageArr = [msg componentsSeparatedByString:@":"];
            if ([messageArr[0] containsString:@"blesuccess"]) {
                
            }else if([messageArr[0] containsString:@"bleerror"]){
                pairProgress = 69;
                logMsg=@{@"progress":[NSNumber numberWithInt:pairProgress],@"code":messageArr[2],@"message":messageArr[1]};
                success(logMsg);
            }else if([messageArr[0] containsString:@"blecode"]){
                pairProgress = 69;
                logMsg=@{@"progress":[NSNumber numberWithInt:pairProgress],@"code":messageArr[2],@"message":messageArr[1]};
                success(logMsg);
            }else{//msg:
                logMsg=@{@"progress":[NSNumber numberWithInt:pairProgress],@"code":messageArr[2],@"message":messageArr[1]};
                success(logMsg);
            }
            NSLog(@"pairProgress----->%d",pairProgress);
        }];
    }
}

//蓝牙配网
+ (void)startBLEConfigure:(NSDictionary *)messageDic andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(NSDictionary * _Nonnull))failure {
    
    NSMutableDictionary *argsDic = [[NSMutableDictionary alloc]initWithDictionary:messageDic];
    NSArray *whiteListArr = argsDic[@"white_list"];
    int count = [[NSString stringWithFormat:@"%lu", (unsigned long)whiteListArr.count] intValue];
    //保存记录
    NSString* ssid=argsDic[@"ssid"];
    BOOL beacon=[argsDic[@"beacon"] boolValue];
    NSString* password=argsDic[@"password"];
    NSDictionary* objItem=@{@"ssid":ssid,@"password":password};
    [ESPFBYDataBase saveObject:objItem withNameTable:@"ap_table" withId:ssid];

//    static int pairProgress = 60;
    [[ESPMeshManager share] sendDistributionNetworkDataToDevices:argsDic timeOut:60 callBackBlock:^(NSString *msg) {
        NSLog(@"msg:::::::%@",msg);
        NSDictionary* logMsg;
        NSArray *messageArr = [msg componentsSeparatedByString:@":"];
        if ([messageArr[0] containsString:@"success"]) {
            if (beacon) {
                [[ESPAliyunSDKUse sharedClient] aliStartDiscoveryDeviceCount:count withBlock:^(NSArray * _Nonnull devices) {
                    NSLog(@"devices ---> %@",devices);
                    if (ValidArray(devices)) {
                        for (int i = 0; i < devices.count; i ++) {
                            [[ESPAliyunSDKUse sharedClient] aliDeviceBinding:devices[i] andSuccess:^(NSDictionary * _Nonnull resultIotid) {
                                NSMutableDictionary *yunDevice = [NSMutableDictionary dictionaryWithCapacity:0];
                                yunDevice[@"code"] = @"-8010";
                                yunDevice[@"deviceBind"] = resultIotid;
                                success(yunDevice);
                                NSDictionary *message = @{@"progress":@100,@"code":messageArr[2],@"message":messageArr[1]};
                                success(message);
                            } andFailure:^(NSDictionary * _Nonnull errorMsg) {
                                NSMutableDictionary *yunDevice = [NSMutableDictionary dictionaryWithCapacity:0];
                                yunDevice[@"code"] = @"-8010";
                                yunDevice[@"deviceBind"] = errorMsg;
                                success(yunDevice);
                                NSDictionary *message = @{@"progress":@100,@"code":messageArr[2],@"message":messageArr[1]};
                                success(message);
                            }];
                        }
                    }else {
                        NSDictionary *message = @{@"progress":@100,@"code":messageArr[2],@"message":messageArr[1]};
                        success(message);
                    }
                }];
            }else {
                logMsg=@{@"progress":@100,@"code":messageArr[2],@"message":messageArr[1]};
                success(logMsg);
            }
            
        }else{//msg:
            logMsg=@{@"progress":@70,@"code":messageArr[2],@"message":messageArr[1]};
            success(logMsg);
        }
    }];
}

//停止配网
+ (void)stopConfigureBlufi {
    [[ESPMeshManager share] cancleBLEPair];
}

//开启UDP扫描
+ (void)scanDevicesAsyncSuccess:(DevicesAsyncSuccessBlock)success andFailure:(void (^)(int))failure {
    NSMutableArray *scanUDPArr = [NSMutableArray arrayWithCapacity:0];
    dispatch_queue_t queueT = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t grpupT = dispatch_group_create();//一个线程组
    
    dispatch_group_async(grpupT, queueT, ^{
        dispatch_group_enter(grpupT);
        [[ESPMeshManager share] starScanRootUDP:^(NSArray *devixe) {
            [scanUDPArr addObjectsFromArray:devixe];
            dispatch_group_leave(grpupT);
        } failblock:^(int code) {
            dispatch_group_leave(grpupT);
        }];
    });
    
    dispatch_group_async(grpupT, queueT, ^{
        dispatch_group_enter(grpupT);
        [[ESPMeshManager share] starScanRootmDNS:^(NSArray * _Nonnull devixe) {
            [scanUDPArr addObjectsFromArray:devixe];
            dispatch_group_leave(grpupT);
        } failblock:^(int code) {
            dispatch_group_leave(grpupT);
        }];
    });
    dispatch_group_notify(grpupT, queueT, ^{
        NSSet *set = [NSSet setWithArray:scanUDPArr];
        NSArray *allArray = [set allObjects];
        
        NSMutableDictionary *DevicesOfScanUDP = [NSMutableDictionary dictionaryWithCapacity:0];
        NSOperationQueue * opq=[[NSOperationQueue alloc] init];
        opq.maxConcurrentOperationCount=1;
        [opq addOperationWithBlock:^{
            NSMutableArray* meshinfoArr = [NSMutableArray arrayWithCapacity:0];
            if (!ValidArray(allArray)) {
                failure(8010);
                return ;
            }
            for (int i = 0; i < allArray.count; i ++) {
                NSArray *macArr=[allArray[i] componentsSeparatedByString:@":"];
                EspDevice* device=[[EspDevice alloc] init];
                device.mac=macArr[0];
                device.host=macArr[1];
                device.httpType=macArr[2];
                device.port=macArr[3];
                NSMutableArray *meshItermArr = [[ESPMeshManager share] getMeshInfoFromHost:device];
                for (int i = 0; i < meshItermArr.count; i ++) {
                    [meshinfoArr addObject:meshItermArr[i]];
                }
            }
            NSString *httpResponse = [ESPDataConversion fby_getNSUserDefaults:@"httpResponse"];
            if ([httpResponse intValue] != 200) {
                failure(8010);
                return ;
            }
            NSMutableArray* tempInfosArr=[NSMutableArray arrayWithCapacity:0];
            for (int i=0; i<meshinfoArr.count; i++) {
                EspDevice* newDevice=[meshinfoArr objectAtIndex:i];
                [tempInfosArr addObject:@{@"mac":newDevice.mac,
                                          @"layer":[NSString stringWithFormat:@"%d",newDevice.meshLayerLevel],
                                          @"host":newDevice.host
                                          }];
            }
            if (ValidArray(tempInfosArr)) {
                NSArray *deviceDetailsArr = [ESPDataConversion DeviceOfScanningUDPData:tempInfosArr];
                NSSet *set = [NSSet setWithArray:deviceDetailsArr];
                NSArray *allArray = [set allObjects];
                NSMutableDictionary *deviceScanning = [NSMutableDictionary dictionaryWithCapacity:0];
                deviceScanning[@"onDeviceScanningResult"] = allArray;
                NSLog(@"基本信息获取");
                success(deviceScanning);
            }else{
                failure(8010);
                return ;
            }
            NSMutableArray *DevicesOfScanUDPKeyArr = [NSMutableArray arrayWithCapacity:0];
            NSMutableArray *DevicesOfScanUDPHostArr = [NSMutableArray arrayWithCapacity:0];
            NSMutableArray *DevicesOfScanUDPValueArr = [NSMutableArray arrayWithCapacity:0];
            NSMutableArray *DevicesOfScanUDPGroupArr = [NSMutableArray arrayWithCapacity:0];
            EspActionDeviceInfo* deviceinfoAction = [[EspActionDeviceInfo alloc] init];
            NSMutableDictionary* resps = [deviceinfoAction doActionGetDevicesInfoLocal:meshinfoArr];
            if (resps.count>0) {
                
                for (int i=0; i<meshinfoArr.count; i++) {
                    EspDevice* newDevice=[meshinfoArr objectAtIndex:i];
                    NSString *url = [EspDeviceUtil getLocalUrlForProtocol:newDevice.httpType host:newDevice.host port:newDevice.port.intValue file:@""];
                    [[NSUserDefaults standardUserDefaults] setValue:url forKey:newDevice.mac];
                    //获取详细信息
                    EspHttpResponse *response = resps[newDevice.mac];
                    if (response != nil) {
                        NSDictionary* responDic=response.getContentJSON;
                        //                    NSLog(@"responDic====%@",responDic);
                        NSMutableDictionary *mDic = [ESPDataConversion deviceDetailData:responDic withEspDevice:newDevice];
                        [DevicesOfScanUDPGroupArr addObject:mDic[@"group"]];
                        if (responDic[@"characteristics"] != nil) {
                            //self->ScanUDPDevices[newDevice.mac]=mDic;
                            [DevicesOfScanUDPHostArr addObject:newDevice.host];
                            [DevicesOfScanUDPKeyArr addObject:newDevice.mac];
                            [DevicesOfScanUDPValueArr addObject:mDic];
                            
                            newDevice.sendInfo=mDic;
                            DevicesOfScanUDP[newDevice.mac]=newDevice;
                        }
                    }
                }
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setValue:DevicesOfScanUDPHostArr forKey:@"DevicesOfScanUDPHostArr"];
                [defaults setValue:DevicesOfScanUDPKeyArr forKey:@"DevicesOfScanUDPKeyArr"];
                [defaults setValue:DevicesOfScanUDPValueArr forKey:@"DevicesOfScanUDPValueArr"];
                [defaults setValue:DevicesOfScanUDPGroupArr forKey:@"DevicesOfScanUDPGroupArr"];
                [defaults synchronize];
                
                success(DevicesOfScanUDP);
                NSLog(@"详细信息回调");
                
            }else {
                failure(8011);
            }
        }];
    });
}
//发送多个设备命令
+ (void)requestDevicesMulticastAsync:(NSDictionary *)messageDic andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(NSDictionary * _Nonnull))failure {
    NSMutableDictionary *msg=[[NSMutableDictionary alloc]initWithDictionary:messageDic];
    NSString *requestStr = [msg objectForKey:@"request"];
    NSString *callbackStr = [msg objectForKey:@"callback"];
    NSArray *groupArr = [msg objectForKey:@"group"];
    NSString *callbackMacStr = nil;
    if ([requestStr isEqualToString:@"get_event"]) {
        callbackMacStr = [msg objectForKey:@"mac"];
    }
    // 区别请求是异步还是队列
    BOOL isSendQueue = [[msg objectForKey:@"isSendQueue"] boolValue];
    // 区别请求是多设备(NO)还是单设备(YES)
    BOOL isDeviceNumber = NO;
    id tag = [msg objectForKey:@"tag"];
    id macArr = [msg objectForKey:@"mac"];
    if (!ValidArray(macArr)) {
        macArr = @[[msg objectForKey:@"mac"]];
        isDeviceNumber = YES;
    }

    NSDictionary *deviceIpWithDic;
    BOOL isGroupBool = [[msg objectForKey:@"isGroup"] boolValue];
    NSString *isGroup;
    NSArray *deviceIpArr;
    if (isGroupBool) {
        isGroup = @"1";
    }else {
        isGroup = @"0";
    }
    deviceIpWithDic = [ESPDataConversion deviceRequestIpWithMac:macArr];
    deviceIpArr = [deviceIpWithDic allKeys];
    if (!ValidArray(deviceIpArr)) {
        if (callbackStr != nil) {
            NSDictionary *resultDic = @{@"code":@"8010",@"callbackStr":callbackStr};
            failure(resultDic);
        }
        return;
    }
    __block NSUInteger taskInt = deviceIpArr.count;
    NSUInteger requestInt = deviceIpArr.count;

    NSMutableArray *resultAllArr = [NSMutableArray arrayWithCapacity:0];

    for (int i = 0; i < deviceIpArr.count; i ++) {

        NSArray *macs;
        //        NSArray *groups;
        NSMutableDictionary* headers = [NSMutableDictionary dictionary];
        if ([isGroup integerValue] == 1) {
            NSString* groupsStr=groupArr[0];

            for (int j=1; j<groupArr.count; j++) {
                groupsStr=[NSString stringWithFormat:@"%@,%@",groupsStr,groupArr[j]];
            }
            [headers setObject:groupsStr forKey:@"meshNodeGroup"];
        }
        macs = [deviceIpWithDic objectForKey:deviceIpArr[i]];
        if (!ValidArray(macs)) {
            if (callbackStr != nil) {
                NSDictionary *resultDic = @{@"code":@"8010",@"callbackStr":callbackStr};
                failure(resultDic);
            }
            return;
        }
        NSString* macsStr=macs[0];
        if ([requestStr isEqualToString:@"reset"]) {//重置设备
//            [ESPDataConversion fby_saveNSUserDefaults:macsStr withKey:@"resetMacsStr"];
            NSDictionary *resultDic = @{@"code":@"8011",@"resetMacsStr":macsStr};
            failure(resultDic);
        }
        for (int m=1; m<macs.count; m++) {
            macsStr=[NSString stringWithFormat:@"%@,%@",macsStr,macs[m]];

            if ([requestStr isEqualToString:@"reset"]) {//重置设备
//                [ESPDataConversion fby_saveNSUserDefaults:macsStr withKey:@"resetMacsStr"];
                NSDictionary *resultDic = @{@"code":@"8011",@"resetMacsStr":macs[m]};
                failure(resultDic);
            }
        }

        NSString *port = @"80";
        NSString *urlStr = [NSString stringWithFormat:@"http://%@:%@/device_request",deviceIpArr[i],port];

        [headers setObject:[NSString stringWithFormat:@"%lu",(unsigned long)macs.count] forKey:@"meshNodeNum"];
        if ([msg objectForKey:@"root_response"]) {
            NSString* root_response = [NSString stringWithFormat:@"%@", [msg objectForKey:@"root_response"]];
            [headers setObject:root_response forKey:@"rootResponse"];
        }
        [headers setObject:macsStr forKey:@"meshNodeMac"];
        [headers setObject:isGroup forKey:@"isGroup"];
        [headers setObject:[NSString stringWithFormat:@"%lu",(unsigned long)requestInt] forKey:@"taskStr"];

        if (callbackStr) {
            [msg removeObjectForKey:@"callback"];
        }
        if (tag) {
            [msg removeObjectForKey:@"tag"];
        }
        if ([isGroup integerValue] == 1) {
            [msg removeObjectForKey:@"group"];
        }
        [msg removeObjectForKey:@"root_response"];
        [msg removeObjectForKey:@"mac"];
        [msg removeObjectForKey:@"host"];

        ESPUploadHandleTool *espUploadHandleTool = [ESPUploadHandleTool shareInstance];
        if (isSendQueue) {
            dispatch_queue_t queue = dispatch_queue_create("my.concurrentQueue", DISPATCH_QUEUE_SERIAL);
            dispatch_sync(queue, ^{
                //                NSLog(@"%@----------%d",[NSThread currentThread], i);
                [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:headers withBodyContent:msg andSuccess:^(NSArray * _Nonnull resultArr) {
                    if (ValidArray(resultArr)) {
                        if (callbackStr == nil) {
                            return;
                        }
                        if (isDeviceNumber) {
                            NSMutableDictionary * jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                            jsonDic[@"result"] = resultArr[0];
                            jsonDic[@"callbackStr"] = callbackStr;
                            if (tag) {
                                jsonDic[@"tag"] = tag;
                            }
                            if (callbackMacStr != nil) {
                                jsonDic[@"mac"] = callbackMacStr;
                            }
                            success(jsonDic);
                        }else {
                            if (taskInt > 1) {
                                [resultAllArr addObjectsFromArray:resultArr];
                            }else {
                                [resultAllArr addObjectsFromArray:resultArr];
                                NSSet *set = [NSSet setWithArray:resultAllArr];
                                NSArray *allArray = [set allObjects];
                                NSMutableDictionary * jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                                jsonDic[@"result"] = allArray;
                                jsonDic[@"callbackStr"] = callbackStr;
                                if (tag) {
                                    jsonDic[@"tag"] = tag;
                                }
                                if (callbackMacStr != nil) {
                                    jsonDic[@"mac"] = callbackMacStr;
                                }
                                success(jsonDic);
                            }
                            taskInt --;
                        }
                    }
                } andFailure:^(int fail) {
                    NSLog(@"%d",fail);
                    if (callbackStr != nil) {
                        NSDictionary *resultDic = @{@"code":@"8010",@"callbackStr":callbackStr};
                        failure(resultDic);
                    }
                }];
            });
        }else {
            dispatch_queue_t queueT = dispatch_queue_create("my.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);//一个并发队列
            dispatch_async(queueT, ^{
                //                NSLog(@"%@----------%d",[NSThread currentThread], i);
                [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:headers withBodyContent:msg andSuccess:^(NSArray * _Nonnull resultArr) {
                    if (ValidArray(resultArr)) {
                        if (callbackStr == nil) {
                            return;
                        }
                        if (isDeviceNumber) {
                            NSMutableDictionary * jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                            jsonDic[@"result"] = resultArr[0];
                            jsonDic[@"callbackStr"] = callbackStr;
                            if (tag) {
                                jsonDic[@"tag"] = tag;
                            }
                            if (callbackMacStr != nil) {
                                jsonDic[@"mac"] = callbackMacStr;
                            }
                            success(jsonDic);
                        }else {
                            if (taskInt > 1) {
                                [resultAllArr addObjectsFromArray:resultArr];
                            }else {
                                [resultAllArr addObjectsFromArray:resultArr];
                                NSSet *set = [NSSet setWithArray:resultAllArr];
                                NSArray *allArray = [set allObjects];
                                NSMutableDictionary * jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                                jsonDic[@"result"] = allArray;
                                jsonDic[@"callbackStr"] = callbackStr;
                                if (tag) {
                                    jsonDic[@"tag"] = tag;
                                }
                                if (callbackMacStr != nil) {
                                    jsonDic[@"mac"] = callbackMacStr;
                                }
                                success(jsonDic);
                            }
                            taskInt --;
                        }
                    }
                } andFailure:^(int fail) {
                    NSLog(@"%d",fail);
                    if (callbackStr != nil) {
                        NSDictionary *resultDic = @{@"code":@"8010",@"callbackStr":callbackStr};
                        failure(resultDic);
                    }
                }];
            });
        }

    }
    
}

//发送单个设备命令(弃用)
- (void)requestDeviceAsync:(NSDictionary *)messageDic andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(NSDictionary * _Nonnull))failure {
    
    NSMutableDictionary* argsDic=[messageDic copy];
    
    NSString *callbackStr = [argsDic objectForKey:@"callback"];
    id tag = [argsDic objectForKey:@"tag"];
    NSString *requestStr = [argsDic objectForKey:@"request"];
    
    NSString* macsStr=[argsDic objectForKey:@"mac"];
    if ([requestStr isEqualToString:@"reset"]) {//重置设备
//        [self->DevicesOfScanUDP removeObjectForKey:macsStr];
    }
    NSMutableDictionary* headers = [NSMutableDictionary dictionary];
    [headers setObject:@"1" forKey:@"meshNodeNum"];
    if ([argsDic objectForKey:@"root_response"]) {
        NSString* root_response = [NSString stringWithFormat:@"%@", [argsDic objectForKey:@"root_response"]];
        [headers setObject:root_response forKey:@"rootResponse"];
    }
    [headers setObject:macsStr forKey:@"meshNodeMac"];
    
    NSString *port = @"80";
    NSString *hostStr = [ESPDataConversion deviceRequestIp:macsStr];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@:%@/device_request",hostStr,port];
    if (callbackStr) {
        [argsDic removeObjectForKey:@"callback"];
    }
    if (tag) {
        [argsDic removeObjectForKey:@"tag"];
    }
    [argsDic removeObjectForKey:@"root_response"];
    [argsDic removeObjectForKey:@"mac"];
    [argsDic removeObjectForKey:@"host"];
    NSMutableArray *resultAllArr = [NSMutableArray arrayWithCapacity:0];
    ESPUploadHandleTool *espUploadHandleTool = [ESPUploadHandleTool shareInstance];
    [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:headers withBodyContent:argsDic andSuccess:^(NSArray * _Nonnull resultArr) {
        if ([[resultArr[0] objectForKey:@"status_code"] intValue] == 0) {
            if (callbackStr == nil) {
                return;
            }
            [resultAllArr addObjectsFromArray:resultArr];
            NSMutableDictionary * jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
            jsonDic[@"result"] = resultAllArr;
            if (tag) {
                jsonDic[@"tag"] = tag;
            }
            success(jsonDic);
        }
    } andFailure:^(int fail) {
        failure(@{@"status_code":@"-100"});
    }];
    
}

//设备升级
+ (void)startOTA:(NSString *)message Success:(startOTASuccessBlock)successOTA andFailure:(void (^)(int))failure {
    
    id msg=[ESPDataConversion objectFromJsonString:message];
    NSDictionary *deviceIpWithMacDic = [ESPDataConversion deviceRequestIpWithMac:[msg objectForKey:@"macs"]];
    NSArray *deviceIpArr = [deviceIpWithMacDic allKeys];
    if (!ValidArray(deviceIpArr)) {
        failure(8010);
        return;
    }
    [ESPDataConversion fby_saveNSUserDefaults:deviceIpArr withKey:@"stopRequestIpArr"];
    for (int i = 0; i < deviceIpArr.count; i ++) {
        NSMutableDictionary *requestOTAProgressDic = [NSMutableDictionary dictionaryWithCapacity:0];
        NSArray* macs = [deviceIpWithMacDic objectForKey:deviceIpArr[i]];
        NSString *hostStr = deviceIpArr[i];
        NSString* macsStr=macs[0];
        for (int i=1; i<macs.count; i++) {
            macsStr=[NSString stringWithFormat:@"%@,%@",macsStr,macs[i]];
        }
        requestOTAProgressDic[@"mac"] = macsStr;
        requestOTAProgressDic[@"macArr"] = macs;
        requestOTAProgressDic[@"host"] = hostStr;
        [ESPDataConversion fby_saveNSUserDefaults:requestOTAProgressDic withKey:@"requestOTAProgressDic"];
        ESPUploadHandleTool *espUploadHandleTool = [ESPUploadHandleTool shareInstance];
        __block NSURLSessionTask *sessionTask;
        if ([msg[@"type"] intValue] == 3) {
            sessionTask = [espUploadHandleTool meshNodeMac:macsStr andWithFirmwareUrl:msg[@"bin"] withIPUrl:hostStr andSuccess:^(NSDictionary * _Nonnull dic) {
                NSLog(@"dic--->%@",dic);
                if (dic==nil) {
                    failure(8010);
                    return ;
                }
                NSMutableArray *jsonArr = [NSMutableArray arrayWithCapacity:0];
                if (macs.count == 1) {
                    NSDictionary *resultDic = [dic objectForKey:@"result"];
                    if ([[resultDic objectForKey:@"status_code"] intValue] == 0) {
                        NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                        macDic[@"mac"] = macs[0];
                        macDic[@"progress"] = @"50";
                        macDic[@"message"] = @"ota message";
                        [jsonArr addObject:macDic];
                    }
                }else {
                    NSArray *resultArr = [dic objectForKey:@"result"];
                    for (int i = 0; i < resultArr.count; i ++) {
                        NSDictionary *resultDic = resultArr[i];
                        if ([[resultDic objectForKey:@"code"] intValue] == 0) {
                            NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                            macDic[@"mac"] = [resultDic objectForKey:@"mac"];
                            macDic[@"progress"] = @"50";
                            macDic[@"message"] = [resultDic objectForKey:@"message"];
                            [jsonArr addObject:macDic];
                            
                        }
                    }
                }
                
                if (ValidArray(jsonArr)) {
                    NSMutableDictionary *jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                    jsonDic[@"jsonArr"] = jsonArr;
                    jsonDic[@"type"] = @"0";
                    jsonDic[@"sessionTask"] = sessionTask;
                    successOTA(jsonDic);
                }else {
                    failure(8010);
                }
                
            } andFailure:^(int fail) {
                NSLog(@"fail--->%d",fail);
                failure(8010);
            }];
        }else if ([msg[@"type"] intValue] == 2) {
            NSString* binPath=[msg[@"bin"] componentsSeparatedByString:@"_"].lastObject;
            ESPDocumentsPath *espDocumentPath = [[ESPDocumentsPath alloc]init];
            NSString *path = [espDocumentPath getDocumentsPath];
            NSString  *documentPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"iOSUpgradeFiles/%@",binPath]];
            NSLog(@"%@",documentPath);
            NSString *port=@"80";
            //    升级文件上传
            NSString *urlStr=[NSString stringWithFormat:@"http://%@:%@/ota/firmware",hostStr,port];
            sessionTask = [espUploadHandleTool uploadFileWithURL:urlStr parameters:@{@"meshNodeMac":macsStr,@"firmwareName":@"light.bin"} names:@[@"light"] filePaths:@[documentPath] progress:^(float Progress) {
                NSLog(@"进度 %f",Progress);
                NSMutableArray *jsonArr = [NSMutableArray arrayWithCapacity:0];
                for (int i = 0; i < macs.count; i ++) {
                    NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                    macDic[@"mac"] = macs[i];
                    macDic[@"progress"] = [NSString stringWithFormat:@"%f",Progress];
                    macDic[@"message"] = @"ota message";
                    [jsonArr addObject:macDic];
                }
                NSMutableDictionary *jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                jsonDic[@"jsonArr"] = jsonArr;
                jsonDic[@"type"] = @"1";
                jsonDic[@"sessionTask"] = sessionTask;
                successOTA(jsonDic);
            } success:^(NSDictionary * _Nonnull success) {
                NSLog(@"%@",success);
                if (success==nil) {
                    failure(8010);
                    return ;
                }
                
                NSMutableArray *jsonArr = [NSMutableArray arrayWithCapacity:0];
                if (macs.count == 1) {
                    NSDictionary *resultDic = [success objectForKey:@"result"];
                    if ([[resultDic objectForKey:@"status_code"] intValue] == 0) {
                        NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                        macDic[@"mac"] = macs[0];
                        macDic[@"progress"] = @"50";
                        macDic[@"message"] = @"ota message";
                        [jsonArr addObject:macDic];
                    }
                }else {
                    NSArray *resultArr = [success objectForKey:@"result"];
                    for (int i = 0; i < resultArr.count; i ++) {
                        NSDictionary *resultDic = resultArr[i];
                        if ([[resultDic objectForKey:@"code"] intValue] == 0) {
                            NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                            macDic[@"mac"] = [resultDic objectForKey:@"mac"];
                            macDic[@"progress"] = @"50";
                            macDic[@"message"] = [resultDic objectForKey:@"message"];
                            [jsonArr addObject:macDic];
                            
                        }
                    }
                }
                if (ValidArray(jsonArr)) {
                    NSMutableDictionary *jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                    jsonDic[@"jsonArr"] = jsonArr;
                    jsonDic[@"type"] = @"0";
                    jsonDic[@"sessionTask"] = sessionTask;
                    successOTA(jsonDic);
                }else {
                    failure(8010);
                }
            } andFailure:^(int fail) {
                NSLog(@"%d",fail);
                failure(8010);
            }];
        }else {
            failure(8010);
        }
    }
    
}

+ (void)networkRequestOTAProgress:(startOTAProgressBlock)successOTA andFailure:(void (^)(int))failure {
    NSDictionary *requestOTAProgressDic = [ESPDataConversion fby_getNSUserDefaults:@"requestOTAProgressDic"];
    NSString *ip = requestOTAProgressDic[@"host"];
    NSArray *macArr = requestOTAProgressDic[@"macArr"];
    NSString *port=@"80";
    NSString *urlStr=[NSString stringWithFormat:@"http://%@:%@/device_request",ip,port];
    ESPUploadHandleTool *espUploadHandleTool = [ESPUploadHandleTool shareInstance];
    __block NSURLSessionTask *sessionTask;
    sessionTask = [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:@{@"meshNodeMac":requestOTAProgressDic[@"mac"],@"meshNodeNum":[NSString stringWithFormat:@"%lu",(unsigned long)macArr.count]} withBodyContent:@{@"request":@"get_ota_progress"} andSuccess:^(NSArray * _Nonnull resultArr) {
        NSLog(@"resultArr-->%@",resultArr);
        if (!ValidArray(resultArr)) {
            return ;
        }
        if (macArr.count == 1) {
            NSDictionary *resultDic = resultArr[0];
            if ([[resultDic objectForKey:@"status_msg"] isEqualToString:[NSString stringWithFormat:@"MDF_OK"]]) {
                float totalSize = [[resultDic objectForKey:@"total_size"] floatValue];
                float writtenSize = [[resultDic objectForKey:@"total_size"] floatValue];
                int Progress = writtenSize/totalSize;
                NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                macDic[@"mac"] = macArr[0];
                macDic[@"progress"] = [NSString stringWithFormat:@"%d",Progress * 100];
                macDic[@"message"] = @"ota message";
                if (totalSize == writtenSize) {
                    NSMutableDictionary *jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                    jsonDic[@"jsonArr"] = macArr;
                    jsonDic[@"type"] = @"1";
                    jsonDic[@"sessionTask"] = sessionTask;
                    successOTA(jsonDic);
                }else {
                    NSMutableDictionary *jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                    jsonDic[@"jsonArr"] = @[macDic];
                    jsonDic[@"type"] = @"0";
                    jsonDic[@"sessionTask"] = sessionTask;
                    successOTA(jsonDic);
                }
            }else {
                failure(8010);
            }
            
        }else {
            NSMutableArray *jsonArr = [NSMutableArray arrayWithCapacity:0];
            NSMutableArray *jsonMacArr = [NSMutableArray arrayWithCapacity:0];
            for (int i = 0; i < resultArr.count; i ++) {
                if ([[resultArr[i] objectForKey:@"code"] isEqualToString:[NSString stringWithFormat:@"200"]]) {
                    float totalSize = [[resultArr[i] objectForKey:@"total_size"] floatValue];
                    float writtenSize = [[resultArr[i] objectForKey:@"total_size"] floatValue];
                    int Progress = writtenSize/totalSize;
                    NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                    macDic[@"mac"] = [resultArr[i] objectForKey:@"mac"];
                    macDic[@"progress"] = [NSString stringWithFormat:@"%d",Progress * 100];
                    macDic[@"message"] = @"ota message";
                    [jsonArr addObject:macDic];
                    if (totalSize == writtenSize) {
                        [jsonMacArr addObject:[resultArr[i] objectForKey:@"mac"]];
                    }
                }else {
                    failure(8010);
                }
            }
            if (resultArr.count == jsonMacArr.count) {
                NSMutableDictionary *jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                jsonDic[@"jsonArr"] = jsonMacArr;
                jsonDic[@"type"] = @"1";
                jsonDic[@"sessionTask"] = sessionTask;
                successOTA(jsonDic);
            }else {
                NSMutableDictionary *jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                jsonDic[@"jsonArr"] = jsonArr;
                jsonDic[@"type"] = @"0";
                jsonDic[@"sessionTask"] = sessionTask;
                successOTA(jsonDic);
            }
        }
    } andFailure:^(int fail) {
        NSLog(@"%d",fail);
        failure(8011);
    }];
    
}

//停止OTA升级
+ (void)stopOTA:(NSString *)message withSessionTask:(NSURLSessionTask *)sessionTask {
    id msg=[ESPDataConversion objectFromJsonString:message];
    NSArray *stopRequestIpArr = [ESPDataConversion fby_getNSUserDefaults:@"stopRequestIpArr"];
    if (msg==nil) {
        return;
    }
    NSMutableArray *stopOTAIpArr = [NSMutableArray arrayWithArray:stopRequestIpArr];
    [sessionTask cancel];
    if (ValidArray(stopOTAIpArr)) {
        for (int i = 0; i < stopOTAIpArr.count; i ++) {
            [[ESPUploadHandleTool shareInstance] stopOTA:stopOTAIpArr[i] andSuccess:^(NSDictionary * _Nonnull dic) {
                NSLog(@"%@",dic);
            } andFailure:^(int fail) {
                NSLog(@"%d",fail);
            }];
        }
    }else {
        return;
    }
}

//重启设备命令
+ (void)reboot:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    NSDictionary *deviceIpWithMacDic = [ESPDataConversion deviceRequestIpWithMac:[msg objectForKey:@"macs"]];
    NSArray *deviceIpArr = [deviceIpWithMacDic allKeys];
    if (!ValidArray(deviceIpArr)) {
        return;
    }
    for (int i = 0; i < deviceIpArr.count; i ++) {
        NSArray* macs = [deviceIpWithMacDic objectForKey:deviceIpArr[i]];
        NSString* macsStr=macs[0];
        for (int i=1; i<macs.count; i++) {
            macsStr=[NSString stringWithFormat:@"%@,%@",macsStr,macs[i]];
        }
        NSString *ip = deviceIpArr[i];
        NSString *port=@"80";
        NSString *urlStr=[NSString stringWithFormat:@"http://%@:%@/device_request",ip,port];
        [[ESPUploadHandleTool shareInstance] requestWithIpUrl:urlStr withRequestHeader:@{@"meshNodeMac":macsStr,@"meshNodeNum":[NSString stringWithFormat:@"%lu",(unsigned long)macs.count]} withBodyContent:@{@"request":@"reboot"} andSuccess:^(NSArray * _Nonnull resultArr) {
            NSLog(@"%@",resultArr);
        } andFailure:^(int fail) {
            NSLog(@"%d",fail);
        }];
    }
    
}

@end

