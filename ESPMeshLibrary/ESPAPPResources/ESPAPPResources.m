//
//  ESPAPPResources.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/2/28.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import "ESPAPPResources.h"
#import "YTKKeyValueStore.h"
#import "ESPDataConversion.h"
#import "EspActionDeviceInfo.h"
#import "EspDeviceUtil.h"

#import "ESPUploadHandleTool.h"
#import "ESPDocumentsPath.h"

#define ValidDict(f) (f!=nil && [f isKindOfClass:[NSDictionary class]])
#define ValidArray(f) (f!=nil && [f isKindOfClass:[NSArray class]] && [f count]>0)

@interface ESPAPPResources ()
{
    NSMutableDictionary *ScanBLEDevices;
    NSMutableDictionary *DevicesOfScanUDP;
    NSMutableDictionary *requestOTAProgressDic;
    YTKKeyValueStore *dbStore;
    ESPDocumentsPath *espDocumentPath;
    ESPUploadHandleTool *espUploadHandleTool;

    BOOL isUDPScan;
    NSDate* lastRequestDate;
    NSTimer *BLETimer;
    
    NSTimer *OTATimer;
    NSTimer *UPDTimer;
    NSOperationQueue* controlQueue;
    NSNumber* pairProgress;
    NSURLSessionTask *sessionTask;
    NSArray *stopRequestIpArr;
}

@end

@implementation ESPAPPResources
//开启蓝牙扫描
- (void)startBleScanSuccess:(BleScanSuccessBlock)success andFailure:(void (^)(int))failure{
    self.BleScanSuccess = success;
    [self sendBLEResult];
    ScanBLEDevices=[NSMutableDictionary dictionaryWithCapacity:0];
    if (BLETimer) {
        [BLETimer invalidate];
        BLETimer=nil;
    }
    BLETimer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendBLEResult) userInfo:nil repeats:true];
    [[NSRunLoop mainRunLoop] addTimer:BLETimer forMode:NSDefaultRunLoopMode];
    dispatch_async(dispatch_get_main_queue(), ^(){
        [[ESPMeshManager share] starScanBLE:^(EspDevice *device) {
            //        NSLog(@"device ouiMDF---->%@", device.ouiMDF);
            NSMutableDictionary *deviceDic = [NSMutableDictionary dictionaryWithCapacity:0];
            deviceDic[@"mac"] = device.bssid;
            deviceDic[@"name"] = device.name;
            deviceDic[@"rssi"] = [NSString stringWithFormat:@"%d",device.RSSI];
            deviceDic[@"device"] = device;
            deviceDic[@"version"] = device.version;
            deviceDic[@"bssid"] = device.bssid;
            deviceDic[@"tid"] = device.deviceTid;
            deviceDic[@"only_beacon"] = @(device.onlyBeacon);
            self->ScanBLEDevices[device.bssid] = deviceDic;
        } failblock:^(int code) {
            
        }];
    });
}

//关闭蓝牙扫描
- (void)stopBleScan {
    if (BLETimer) {
        [BLETimer invalidate];
        BLETimer=nil;
    }
    [[ESPMeshManager share] cancelScanBLE];
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
                [sendArr addObject:@{@"mac":tmpArr[i][@"mac"],@"name":tmpArr[i][@"name"],@"rssi":tmpArr[i][@"rssi"],@"version":tmpArr[i][@"version"],@"bssid":tmpArr[i][@"bssid"],@"tid":tmpArr[i][@"tid"],@"only_beacon":tmpArr[i][@"only_beacon"]}];
            }
        }
        self.BleScanSuccess(sendArr);
    }
}

//蓝牙配网
- (void)startConfigureBlufi:(NSDictionary *)messageDic andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(NSDictionary * _Nonnull))failure {
    
    NSMutableDictionary* argsDic=[messageDic copy];
    //保存记录
    [dbStore createTableWithName:@"ap_table"];
    NSString* ssid=argsDic[@"ssid"];
    NSString* password=argsDic[@"password"];
    NSDictionary* objItem=@{@"ssid":ssid,@"password":password};
    [dbStore putObject:objItem withId:ssid intoTable:@"ap_table"];
    //开始配网
    NSMutableDictionary* deviceInfo = self->ScanBLEDevices[argsDic[@"ble_addr"]];
    if (deviceInfo ==nil ) {
        NSDictionary *failDic = @{@"progress":@"0",@"code":@0,@"message":@"配网失败"};
        failure(failDic);
        return;
    }else{
        EspDevice* tmpDevice = deviceInfo[@"device"];
        
        pairProgress=[NSNumber numberWithInt:0];
        
        [[ESPMeshManager share] starBLEPair:tmpDevice pairInfo:argsDic timeOut:60 callBackBlock:^(NSString *msg) {
            NSLog(@"msg:::::::%@",msg);
            NSDictionary* logMsg;
            if (self->pairProgress.intValue>=90) {
                //                self->pairProgress=[NSNumber numberWithInt:self->pairProgress.intValue+1];
            }else{
                self->pairProgress=[NSNumber numberWithInt:self->pairProgress.intValue+10];
            }
            NSArray *messageArr = [msg componentsSeparatedByString:@":"];
            if ([messageArr[0] containsString:@"success"]) {
                logMsg=@{@"progress":@100,@"code":messageArr[2],@"message":messageArr[1]};
            }else if([messageArr[0] containsString:@"error"]){
                self->pairProgress=[NSNumber numberWithInt:99];
                logMsg=@{@"progress":self->pairProgress,@"code":messageArr[2],@"message":messageArr[1]};
            }else if([messageArr[0] containsString:@"code"]){
                self->pairProgress=[NSNumber numberWithInt:99];
                logMsg=@{@"progress":self->pairProgress,@"code":messageArr[2],@"message":messageArr[1]};
            }else{//msg:
                logMsg=@{@"progress":self->pairProgress,@"code":messageArr[2],@"message":messageArr[1]};
            }
            NSLog(@"pairProgress----->%@",pairProgress);
            success(logMsg);
            
        }];
    }
}

//停止配网
- (void)stopConfigureBlufi {
    [[ESPMeshManager share] cancleBLEPair];
}

//开启UDP扫描
- (void)scanDevicesAsyncSuccess:(DevicesAsyncSuccessBlock)success andFailure:(void (^)(int))failure {
    self.DevicesAsyncSuccess = success;
    isUDPScan=true;
    DevicesOfScanUDP=[NSMutableDictionary dictionaryWithCapacity:0];
    //DeviceDic=[NSMutableDictionary dictionaryWithCapacity:0];
    UPDTimer=[NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(sendUDPResult) userInfo:nil repeats:false];
    [[NSRunLoop mainRunLoop] addTimer:UPDTimer forMode:NSDefaultRunLoopMode];
    
    [[ESPMeshManager share] starScanRootmDNS:^(NSArray * _Nonnull devixe) {
        [self obtainDeviceDetails:devixe];
    } failblock:^(int code) {
        
    }];
    [[ESPMeshManager share] starScanRootUDP:^(NSArray *devixe) {
        [self obtainDeviceDetails:devixe];
    } failblock:^(int code) {
        
    }];
}
- (void)obtainDeviceDetails:(NSArray *)dev {
    NSOperationQueue * opq=[[NSOperationQueue alloc] init];
    opq.maxConcurrentOperationCount=1;
    [opq addOperationWithBlock:^{
        
        NSMutableArray* meshinfoArr = [NSMutableArray arrayWithCapacity:0];
        for (int i = 0; i < dev.count; i ++) {
            NSArray *macArr=[dev[i] componentsSeparatedByString:@":"];
            EspDevice* device=[[EspDevice alloc] init];
            device.mac=macArr[0];
            device.host=macArr[1];
            device.httpType=macArr[2];
            device.port=macArr[3];
            NSMutableArray *meshItermArr = [[ESPMeshManager share] getMeshInfoFromHost:device];
            for (int i = 0; i < meshItermArr.count; i ++) {
                [meshinfoArr addObject:meshItermArr[i]];
            }
            NSLog(@"meshinfoArr------> %lu",(unsigned long)meshinfoArr.count);
        }
        NSLog(@"meshinfoArr------> %lu",(unsigned long)meshinfoArr.count);
        NSString *httpResponse = [ESPDataConversion fby_getNSUserDefaults:@"httpResponse"];
        if ([httpResponse intValue] != 200) {
            [UPDTimer invalidate];
            [self sendUDPResult];
            self->isUDPScan=false;
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
        if (tempInfosArr.count>0) {
            self.DevicesAsyncSuccess(tempInfosArr);
            
        }else{
            [UPDTimer invalidate];
            [self sendUDPResult];
            self->isUDPScan=false;
            return ;
        }
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
                    NSMutableDictionary *mDic=[NSMutableDictionary dictionaryWithCapacity:0];
                    mDic[@"mac"]=newDevice.mac;
                    if (responDic[@"position"]) {
                        mDic[@"position"]=responDic[@"position"];
                    }else {
                        mDic[@"position"]=@"";
                    }
                    mDic[@"state"]=@"local";
                    mDic[@"meshLayerLevel"]=[NSString stringWithFormat:@"%d",newDevice.meshLayerLevel];
                    mDic[@"meshID"]=newDevice.meshID;
                    mDic[@"host"]=newDevice.host;
                    mDic[@"tid"]=responDic[@"tid"];
                    if (responDic[@"idf_version"]) {
                        mDic[@"idf_version"]=responDic[@"idf_version"];
                    }else {
                        mDic[@"idf_version"]=@"";
                    }
                    if (responDic[@"mdf_version"]) {
                        mDic[@"mdf_version"]=responDic[@"mdf_version"];
                    }else {
                        mDic[@"mdf_version"]=@"";
                    }
                    if (responDic[@"mlink_version"]) {
                        mDic[@"mlink_version"]=responDic[@"mlink_version"];
                    }else {
                        mDic[@"mlink_version"]=@"";
                    }
                    if (responDic[@"trigger"]) {
                        mDic[@"trigger"]=responDic[@"trigger"];
                    }else {
                        mDic[@"trigger"]=@"";
                    }
                    mDic[@"name"]=responDic[@"name"];
                    mDic[@"version"]=responDic[@"version"];
                    mDic[@"characteristics"]=[ESPDataConversion getJSCharacters:responDic[@"characteristics"]];
                    if (responDic[@"characteristics"] != nil) {
                        //self->ScanUDPDevices[newDevice.mac]=mDic;
                        newDevice.sendInfo=mDic;
                        self->DevicesOfScanUDP[newDevice.mac]=newDevice;
                    }
                }
            }
            
        }else {
        }
        
        [UPDTimer invalidate];
        [self sendUDPResult];
        self->isUDPScan=false;
    }];
}

//UDP Scan超时或者失败反馈
-(void)sendUDPResult{
    
    [[ESPMeshManager share] cancelScanRootUDP];
    [[ESPMeshManager share] cancelScanRootmDNS];
    if (DevicesOfScanUDP.count>0) {
        NSMutableArray* sendInfo=[NSMutableArray arrayWithCapacity:0];
        for (EspDevice* item in DevicesOfScanUDP.allValues) {
            [sendInfo addObject:item.sendInfo];
        }
        self.DevicesAsyncSuccess(sendInfo);
    }else{
        self.DevicesAsyncSuccess(@[]);
    }
    isUDPScan=false;
}

//发送多个设备命令
- (void)requestDevicesMulticastAsync:(NSDictionary *)messageDic andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(NSDictionary * _Nonnull))failure {
        
    NSMutableDictionary* argsDic=[messageDic copy];
    
    NSString *requestStr = [argsDic objectForKey:@"request"];
    NSString *callbackStr = [argsDic objectForKey:@"callback"];
    id tag = [argsDic objectForKey:@"tag"];
    
    if (lastRequestDate) {
        NSLog(@"两次请求时间间隔：%f",[[NSDate date] timeIntervalSinceDate:lastRequestDate]);
        if ([[NSDate date] timeIntervalSinceDate:lastRequestDate]<0.5) {
            return;//过滤频繁操作
        }
    }
    lastRequestDate=[NSDate date];
    NSDictionary *deviceIpWithMacDic = [ESPDataConversion deviceRequestIpWithMac:[argsDic objectForKey:@"mac"]];
    NSArray *deviceIpArr = [deviceIpWithMacDic allKeys];
    NSUInteger taskInt = deviceIpArr.count;
    
    NSMutableArray *resultAllArr = [NSMutableArray arrayWithCapacity:0];
    
    for (int i = 0; i < deviceIpArr.count; i ++) {
        
        NSArray* macs = [deviceIpWithMacDic objectForKey:deviceIpArr[i]];
        if (macs.count==0) {
            return;
        }
        NSString* macsStr=macs[0];
        if ([requestStr isEqualToString:@"reset"]) {//重置设备
            [self->DevicesOfScanUDP removeObjectForKey:macsStr];
        }
        for (int i=1; i<macs.count; i++) {
            macsStr=[NSString stringWithFormat:@"%@,%@",macsStr,macs[i]];
            
            if ([requestStr isEqualToString:@"reset"]) {//重置设备
                [self->DevicesOfScanUDP removeObjectForKey:macs[i]];
            }
        }
        
        NSString *port = @"80";
        NSString *urlStr = [NSString stringWithFormat:@"http://%@:%@/device_request",deviceIpArr[i],port];
        
        NSMutableDictionary* headers = [NSMutableDictionary dictionary];
        [headers setObject:[NSString stringWithFormat:@"%lu",(unsigned long)macs.count] forKey:@"meshNodeNum"];
        if ([argsDic objectForKey:@"root_response"]) {
            NSString* root_response = [NSString stringWithFormat:@"%@", [argsDic objectForKey:@"root_response"]];
            [headers setObject:root_response forKey:@"rootResponse"];
        }
        [headers setObject:macsStr forKey:@"meshNodeMac"];
        [headers setObject:[NSString stringWithFormat:@"%lu",(unsigned long)taskInt] forKey:@"taskStr"];
        
        if (callbackStr) {
            [argsDic removeObjectForKey:@"callback"];
        }
        if (tag) {
            [argsDic removeObjectForKey:@"tag"];
        }
        [argsDic removeObjectForKey:@"root_response"];
        [argsDic removeObjectForKey:@"mac"];
        [argsDic removeObjectForKey:@"host"];
        
        if (controlQueue==nil) {
            controlQueue = [[NSOperationQueue alloc] init];
            controlQueue.maxConcurrentOperationCount=20;//1串行，>2并发
        }
        [controlQueue addOperationWithBlock:^{
            espUploadHandleTool = [[ESPUploadHandleTool alloc]init];
            [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:headers withBodyContent:argsDic andSuccess:^(NSArray * _Nonnull resultArr) {
                if (ValidArray(resultArr)) {
                    if (callbackStr == nil) {
                        return;
                    }
                    if (taskInt > 1) {
                        [resultAllArr addObjectsFromArray:resultArr];
                    }else {
                        [resultAllArr addObjectsFromArray:resultArr];
                        NSMutableDictionary * jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                        jsonDic[@"result"] = resultAllArr;
                        if (tag) {
                            jsonDic[@"tag"] = tag;
                        }
                        success(jsonDic);
                    }
                }
            } andFailure:^(int fail) {
                failure(@{@"status_code":@"-100"});
            }];
        }];
    }
    
}

//发送单个设备命令
- (void)requestDeviceAsync:(NSDictionary *)messageDic andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(NSDictionary * _Nonnull))failure {
    
    NSMutableDictionary* argsDic=[messageDic copy];
    
    NSString *callbackStr = [argsDic objectForKey:@"callback"];
    id tag = [argsDic objectForKey:@"tag"];
    NSString *requestStr = [argsDic objectForKey:@"request"];
    
    NSString* macsStr=[argsDic objectForKey:@"mac"];
    if ([requestStr isEqualToString:@"reset"]) {//重置设备
        [self->DevicesOfScanUDP removeObjectForKey:macsStr];
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
    espUploadHandleTool = [[ESPUploadHandleTool alloc]init];
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
- (void)startOTA:(NSDictionary *)messageDic Success:(startOTASuccessBlock)success andFailure:(void (^)(int))failure {
    
    self.startOTASuccess = success;
    
    NSDictionary *deviceIpWithMacDic = [ESPDataConversion deviceRequestIpWithMac:[messageDic objectForKey:@"macs"]];
    NSArray *deviceIpArr = [deviceIpWithMacDic allKeys];
    stopRequestIpArr = deviceIpArr;
    for (int i = 0; i < deviceIpArr.count; i ++) {
        requestOTAProgressDic = [NSMutableDictionary dictionaryWithCapacity:0];
        NSArray *macs = [deviceIpWithMacDic objectForKey:deviceIpArr[i]];
        NSString *hostStr = deviceIpArr[i];
        espDocumentPath = [[ESPDocumentsPath alloc]init];
        if (macs.count==0) {
            return;
        }
        NSString* macsStr=macs[0];
        for (int i=1; i<macs.count; i++) {
            macsStr=[NSString stringWithFormat:@"%@,%@",macsStr,macs[i]];
        }
        requestOTAProgressDic[@"mac"] = macsStr;
        requestOTAProgressDic[@"macArr"] = macs;
        requestOTAProgressDic[@"host"] = hostStr;
        if ([messageDic[@"type"] intValue] == 3) {
            sessionTask = [espUploadHandleTool meshNodeMac:macsStr andWithFirmwareUrl:messageDic[@"bin"] withIPUrl:hostStr andSuccess:^(NSDictionary * _Nonnull dic) {
                NSLog(@"dic--->%@",dic);
                if (dic==nil) {
                    return ;
                }
                NSDictionary *resultDic = [dic objectForKey:@"result"];
                if ([[resultDic objectForKey:@"status_code"] intValue] == 0) {
                    NSMutableArray *jsonArr = [NSMutableArray arrayWithCapacity:0];
                    for (int i = 0; i < macs.count; i ++) {
                        NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                        macDic[@"mac"] = macs[i];
                        macDic[@"progress"] = @"50";
                        macDic[@"message"] = @"ota message";
                        [jsonArr addObject:macDic];
                    }
                    //文件下载进度
                    self.startOTASuccess(jsonArr);
                }else {
                    //文件下载失败
                }
                
                sleep(3);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (OTATimer) {
                        [OTATimer invalidate];
                        OTATimer=nil;
                    }
                    OTATimer=[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(requestOTAProgress) userInfo:nil repeats:true];
                    [[NSRunLoop mainRunLoop] addTimer:OTATimer forMode:NSDefaultRunLoopMode];
                });
            } andFailure:^(int fail) {
                NSLog(@"fail--->%d",fail);
                //文件下载失败
            }];
        }else if ([messageDic[@"type"] intValue] == 2) {
            NSString* binPath=[messageDic[@"bin"] componentsSeparatedByString:@"_"].lastObject;
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
                //文件上传进度
                self.startOTASuccess(jsonArr);
            } success:^(NSDictionary * _Nonnull success) {
                NSLog(@"%@",success);
                if (success==nil) {
                    return ;
                }
                NSDictionary *resultDic = [success objectForKey:@"result"];
                if ([[resultDic objectForKey:@"status_code"] intValue] == 0) {
                    NSMutableArray *jsonArr = [NSMutableArray arrayWithCapacity:0];
                    for (int i = 0; i < macs.count; i ++) {
                        NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                        macDic[@"mac"] = macs[i];
                        macDic[@"progress"] = @"50";
                        macDic[@"message"] = @"ota message";
                        [jsonArr addObject:macDic];
                    }
                    //文件上传成功
                    self.startOTASuccess(jsonArr);
                }else {
                    //文件上传失败
                }
                sleep(3);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (OTATimer) {
                        [OTATimer invalidate];
                        OTATimer=nil;
                    }
                    OTATimer=[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(requestOTAProgress) userInfo:nil repeats:true];
                    [[NSRunLoop mainRunLoop] addTimer:OTATimer forMode:NSDefaultRunLoopMode];
                });
            } andFailure:^(int fail) {
                NSLog(@"%d",fail);
                //文件上传失败
            }];
        }else {
            //就设备OTA升级
        }
    }
    
}

- (void)requestOTAProgress {
    NSString *ip = requestOTAProgressDic[@"host"];
    NSArray *macArr = requestOTAProgressDic[@"macArr"];
    NSString *port=@"80";
    NSString *urlStr=[NSString stringWithFormat:@"http://%@:%@/device_request",ip,port];
    sessionTask = [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:@{@"meshNodeMac":requestOTAProgressDic[@"mac"],@"meshNodeNum":[NSString stringWithFormat:@"%lu",(unsigned long)macArr.count]} withBodyContent:@{@"request":@"get_ota_progress"} andSuccess:^(NSArray * _Nonnull resultArr) {
        NSLog(@"resultArr-->%@",resultArr);
        if (!ValidArray(resultArr)) {
            return ;
        }
        if (macArr.count == 1) {
            NSDictionary *resultDic = resultArr[0];
            NSMutableArray *jsonArr = [NSMutableArray arrayWithCapacity:0];
            if ([[resultDic objectForKey:@"code"] isEqualToString:[NSString stringWithFormat:@"200"]]) {
                float totalSize = [[resultDic objectForKey:@"total_size"] floatValue];
                float writtenSize = [[resultDic objectForKey:@"total_size"] floatValue];
                int Progress = writtenSize/totalSize;
                NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                macDic[@"mac"] = macArr[0];
                macDic[@"progress"] = [NSString stringWithFormat:@"%d",Progress * 100];
                macDic[@"message"] = @"ota message";
                [jsonArr addObject:macDic];
                if (totalSize == writtenSize) {
                    //升级成功
                    self.startOTASuccess(macArr);
                }else {
                    //升级进行中
                    self.startOTASuccess(jsonArr);
                }
            }else {
                //升级失败
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
                    //升级失败
                }
            }
            if (resultArr.count == jsonMacArr.count) {
                //升级成功
                self.startOTASuccess(jsonMacArr);
            }else {
                //升级进行中
                self.startOTASuccess(jsonArr);
            }
        }
        [self->OTATimer invalidate];
    } andFailure:^(int fail) {
        NSLog(@"%d",fail);
        //升级失败
        [self->OTATimer invalidate];
    }];
    
}

//停止OTA升级
- (void)stopOTA:(NSDictionary *)messageDic {
        
    [sessionTask cancel];
    if (stopRequestIpArr) {
        for (int i = 0; i < stopRequestIpArr.count; i ++) {
            [espUploadHandleTool stopOTA:stopRequestIpArr[i] andSuccess:^(NSDictionary * _Nonnull dic) {
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
- (void)reboot:(NSDictionary *)messageDic {
        
    NSDictionary *deviceIpWithMacDic = [ESPDataConversion deviceRequestIpWithMac:[messageDic objectForKey:@"macs"]];
    NSArray *deviceIpArr = [deviceIpWithMacDic allKeys];
    for (int i = 0; i < deviceIpArr.count; i ++) {
        NSArray* macs = [deviceIpWithMacDic objectForKey:deviceIpArr[i]];
        if (macs.count==0) {
            return;
        }
        NSString* macsStr=macs[0];
        for (int i=1; i<macs.count; i++) {
            macsStr=[NSString stringWithFormat:@"%@,%@",macsStr,macs[i]];
        }
        NSString *ip = deviceIpArr[i];
        NSString *port=@"80";
        NSString *urlStr=[NSString stringWithFormat:@"http://%@:%@/device_request",ip,port];
        [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:@{@"meshNodeMac":macsStr,@"meshNodeNum":[NSString stringWithFormat:@"%lu",(unsigned long)macs.count]} withBodyContent:@{@"request":@"reboot"} andSuccess:^(NSArray * _Nonnull resultArr) {
            NSLog(@"%@",resultArr);
        } andFailure:^(int fail) {
            NSLog(@"%d",fail);
        }];
    }
    
}

@end
