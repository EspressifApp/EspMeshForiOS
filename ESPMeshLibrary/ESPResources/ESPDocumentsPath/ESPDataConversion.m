//
//  ESPDataConversion.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/1/4.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import "ESPDataConversion.h"
#import "EspActionDeviceInfo.h"
#import "EspHttpResponse.h"
#import "EspDeviceUtil.h"

#define ValidDict(f) (f!=nil && [f isKindOfClass:[NSDictionary class]])
#define ValidArray(f) (f!=nil && [f isKindOfClass:[NSArray class]] && [f count]>0)
#define ValidStr(f) (f!=nil && [f isKindOfClass:[NSString class]] && ![f isEqualToString:@""])

@implementation ESPDataConversion

+ (BOOL)isNull:(NSObject *)object {
    if (object == nil ||
        [object isEqual:[NSNull null]] ||
        [object isEqual:@""] ||
        [object isEqual:@" "] ||
        [object isEqual:@"null"] ||
        [object isEqual:@"<null>"] ||
        [object isEqual:@"(null)"] ){
        
        return YES;
    } else {
        return NO;
    }
}

//JSON字符串转化为对象
+ (id)objectFromJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

//字典转json字符串方法
+ (NSString *)jsonFromObject:(id)objdata
{
    
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:objdata options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString;
    
    if (!jsonData) {
        
        NSLog(@"jsonFromObject:%@",error);
        
    }else{
        
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    
    NSRange range = {0,jsonString.length};

    //去掉字符串中的空格

    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    
    NSRange range2 = {0,mutStr.length};
    
    //去掉字符串中的换行符
    
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
}
//字典转json字符串方法
+ (NSString *)jsonConfigureFromObject:(id)objdata
{
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:objdata options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString;
    
    if (!jsonData) {
        
        NSLog(@"jsonFromObject:%@",error);
        
    }else{
        
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    
    NSRange range2 = {0,mutStr.length};
    
    //去掉字符串中的换行符
    
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
}
//18位随机字符串
+ (NSString *)getRandomStringWithLength {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: 18];
    
    for (NSInteger i = 0; i < 18; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    }
    return randomString;
}
//16位随机字符串
+ (NSString *)getRandomAESKey {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: 16];
    
    for (NSInteger i = 0; i < 16; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    }
    return randomString;
}
//characters格式转换
+ (NSMutableArray*)getJSCharacters:(NSMutableArray*)oldCharas{
    NSMutableArray* newCharas=[NSMutableArray arrayWithCapacity:0];
    for (int i=0; i<oldCharas.count; i++) {
        id oldArr=oldCharas[i];
        if ([oldArr isKindOfClass:[NSArray class]]) {
            NSDictionary* newDic=@{@"cid":oldArr[0],@"name":oldArr[1],@"format":oldArr[2],@"perms":oldArr[3],@"value":oldArr[4],@"min":oldArr[5],@"max":oldArr[6],@"step":oldArr[7]};
            [newCharas addObject:newDic];
        }else{
            [newCharas addObject:oldArr];
        }
    }
    return newCharas;
}

/**
 *  Defaults保存
 *
 *  @param value   要保存的数据
 *  @param key   关键字
 *  @return 保存结果
 */
+ (BOOL)fby_saveNSUserDefaults:(id)value withKey:(NSString *)key
{
    if((!value)||(!key)||key.length==0){
        NSLog(@"参数不能为空");
        return NO;
    }
    if(!([value isKindOfClass:[NSString class]]||[value isKindOfClass:[NSNumber class]]||[value isKindOfClass:[NSArray class]]||[value isKindOfClass:[NSDictionary class]])){
        NSLog(@"参数格式不对");
        return NO;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:value forKey:key];
    [defaults synchronize];
    return YES;
}

/**
 *  Defaults取出
 *
 *  @param key     关键字
 *  return  返回已保存的数据
 */
+ (id)fby_getNSUserDefaults:(NSString *)key{
    if(key==nil||key.length==0){
        NSLog(@"参数不能为空");
        return nil;
    }
    NSUserDefaults *version = [NSUserDefaults standardUserDefaults];
    id fbyVersion = [version objectForKey:key];
    [version synchronize];
    
    return fbyVersion;
}

+ (NSDictionary *)deviceRequestIpWithGroup:(NSArray *)groupArr {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *keyData = [defaults objectForKey:@"DevicesOfScanUDPGroupArr"];
    NSArray *hostData = [defaults objectForKey:@"DevicesOfScanUDPHostArr"];
    
    NSMutableDictionary *deviceIpDic = [NSMutableDictionary dictionaryWithCapacity:0];
    
    
    if (keyData.count != hostData.count) {
        return @{};
    }
    
    for (int i = 0; i < groupArr.count; i ++) {
        for (int j = 0; j < keyData.count; j ++) {
            if ([groupArr[i] isEqual:keyData[j]]) {
                NSMutableArray *deviceGroupArr = [NSMutableArray arrayWithCapacity:0];
                if (deviceIpDic[hostData[j]] == nil) {
                    [deviceGroupArr addObject:keyData[j]];
                    deviceIpDic[hostData[j]] = deviceGroupArr;
                }else {
                    NSArray *valueArr = deviceIpDic[hostData[j]];
                    [deviceGroupArr addObject:keyData[j]];
                    [deviceGroupArr addObjectsFromArray:valueArr];
                    deviceIpDic[hostData[j]] = deviceGroupArr;
                }
                
            }
        }
    }
    return deviceIpDic;
}

+ (NSDictionary *)deviceRequestIpWithMac:(NSArray *)macArr {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *keyData = [defaults objectForKey:@"DevicesOfScanUDPKeyArr"];
    NSArray *hostData = [defaults objectForKey:@"DevicesOfScanUDPHostArr"];
    
    NSMutableDictionary *deviceIpDic = [NSMutableDictionary dictionaryWithCapacity:0];
    
    
    if (keyData.count != hostData.count) {
        return @{};
    }
    
    for (int i = 0; i < macArr.count; i ++) {
        for (int j = 0; j < keyData.count; j ++) {
            if ([macArr[i] isEqual:keyData[j]]) {
                NSMutableArray *deviceMacArr = [NSMutableArray arrayWithCapacity:0];
                if (deviceIpDic[hostData[j]] == nil) {
                    [deviceMacArr addObject:keyData[j]];
                    deviceIpDic[hostData[j]] = deviceMacArr;
                }else {
                    NSArray *valueArr = deviceIpDic[hostData[j]];
                    [deviceMacArr addObject:keyData[j]];
                    [deviceMacArr addObjectsFromArray:valueArr];
                    deviceIpDic[hostData[j]] = deviceMacArr;
                }
                
            }
        }
    }
    return deviceIpDic;
}

+ (NSString *)deviceRequestIp:(NSString *)macStr {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *keyData = [defaults objectForKey:@"DevicesOfScanUDPKeyArr"];
    NSArray *hostData = [defaults objectForKey:@"DevicesOfScanUDPHostArr"];
    if (keyData.count != hostData.count) {
        return @"";
    }
    NSString *ipStr;
    for (int j = 0; j < keyData.count; j ++) {
        if ([macStr isEqual:keyData[j]]) {
            ipStr = hostData[j];
        }
    }
    return ipStr;
}


+ (NSArray *)DeviceOfScanningUDPData:(NSMutableArray *)macArr {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *keyData = [[defaults objectForKey:@"DevicesOfScanUDPKeyArr"] copy];
    NSArray *valueData = [[defaults objectForKey:@"DevicesOfScanUDPValueArr"] copy];
    
    NSMutableArray *deviceMacArr = [NSMutableArray arrayWithCapacity:0];
    
    if (keyData.count != valueData.count) {
        return @[];
    }
    
    for (int i = 0; i < macArr.count; i ++) {
        for (int j = 0; j < keyData.count; j ++) {
            NSString *macStr = [macArr[i] objectForKey:@"mac"];
            if ([macStr isEqual:keyData[j]]) {
                [deviceMacArr addObject:valueData[j]];
            }
        }
    }
    
    return deviceMacArr;
}

+ (void)updateGroupInformation:(id)msg {
    NSDictionary *msgDic = msg;
    NSArray *msgAllRoom = [msgDic allKeys];
    NSArray *msgAllMac = [msgDic allValues];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *keyData = [defaults objectForKey:@"DevicesOfScanUDPKeyArr"];
    NSArray *valueData = [defaults objectForKey:@"DevicesOfScanUDPValueArr"];
    NSMutableArray *valueDataArr = [NSMutableArray arrayWithArray:valueData];
    
    for (int i = 0; i < msgAllMac.count; i ++) {
        NSArray *msgMacArr = msgAllMac[i];
        NSString *roomStr = msgAllRoom[i];
        for (int j = 0; j < msgMacArr.count; j ++) {
            for (int m = 0; m < keyData.count; m ++) {
                if ([msgMacArr[j] isEqual:keyData[m]]) {
                    NSMutableDictionary *deviceDetailDic = [NSMutableDictionary dictionaryWithDictionary:valueData[m]];
                    NSArray *roomArr = @[roomStr];
                    [deviceDetailDic setObject:roomArr forKey:@"group"];
                    [valueDataArr replaceObjectAtIndex:m withObject:deviceDetailDic];
                }
            }
        }
    }
    [defaults setValue:valueDataArr forKey:@"DevicesOfScanUDPValueArr"];
}

+ (NSMutableDictionary *)deviceDetailData:(NSDictionary *)responDic withEspDevice:(EspDevice *)newDevice {
    NSMutableDictionary *mDic=[NSMutableDictionary dictionaryWithCapacity:0];
    mDic[@"mac"]=newDevice.mac;
    // 设备位置
    if (responDic[@"position"]) {
        mDic[@"position"]=responDic[@"position"];
    }else {
        mDic[@"position"]=@"";
    }
    // 设备请求头层级（兼容老版本）
    mDic[@"meshLayerLevel"]=[NSString stringWithFormat:@"%d",newDevice.meshLayerLevel];
    // 层级
    if (responDic[@"layer"]) {
        mDic[@"layer"]=responDic[@"layer"];
    }else {
        mDic[@"layer"]=@"";
    }
    mDic[@"meshID"]=newDevice.meshID;
    mDic[@"host"]=newDevice.host;
    // 设备类型
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
    // 协议版本
    if (responDic[@"mlink_version"]) {
        mDic[@"mlink_version"]=responDic[@"mlink_version"];
    }else {
        mDic[@"mlink_version"]=@"";
    }
    // 设备关联
    if (responDic[@"mlink_trigger"]) {
        mDic[@"mlink_trigger"]=responDic[@"mlink_trigger"];
    }else {
        mDic[@"mlink_trigger"]=@"";
    }
    if (responDic[@"mesh_id"]) {
        mDic[@"mesh_id"]=responDic[@"mesh_id"];
    }else {
        mDic[@"mesh_id"]=@"";
    }
    //                    ,@"cloud"
    mDic[@"state"]=@[@"local"];
    
    if (responDic[@"rssi"]) {
        mDic[@"rssi"]=responDic[@"rssi"];
    }else {
        mDic[@"rssi"]=@"";
    }
    // tsf时间
    if (responDic[@"tsf_time"]) {
        mDic[@"tsf_time"]=responDic[@"tsf_time"];
    }else {
        mDic[@"tsf_time"]= @0;
    }
    if (responDic[@"group"]) {
        mDic[@"group"] = responDic[@"group"];
    }else {
        mDic[@"group"] = @[];
    }
    mDic[@"name"]=responDic[@"name"];
    mDic[@"version"]=responDic[@"version"];
    mDic[@"characteristics"]=[ESPDataConversion getJSCharacters:responDic[@"characteristics"]];
    
    return mDic;
}

+ (void)scanDeviceTopo:(scanDeviceTopoBlock)scanTopoArr andFailure:(void (^)(int))failure {
    [[ESPMeshManager share] starScanRootUDP:^(NSArray *devixe) {
        NSOperationQueue* opera=[[NSOperationQueue alloc] init];
        [opera addOperationWithBlock:^{
            NSMutableArray* tmpDeviceArr = [NSMutableArray arrayWithCapacity:0];
            for (int i = 0; i < devixe.count; i ++) {
                NSArray *macArr=[devixe[i] componentsSeparatedByString:@":"];
                EspDevice* device=[[EspDevice alloc] init];
                device.mac=macArr[0];
                device.host=macArr[1];
                device.httpType=macArr[2];
                device.port=macArr[3];
                NSMutableArray *meshItermArr = [[ESPMeshManager share] getMeshInfoFromHost:device];
                for (int i = 0; i < meshItermArr.count; i ++) {
                    [tmpDeviceArr addObject:meshItermArr[i]];
                }
            }
            
            NSMutableArray* macsArr=[NSMutableArray arrayWithCapacity:0];
            for (int i=0; i< tmpDeviceArr.count; i++) {
                [macsArr addObject:((EspDevice*)tmpDeviceArr[i]).mac];
            }
            scanTopoArr(macsArr);
        }];
    } failblock:^(int code) {
        failure(code);
    }];
}

+ (void)downloadDeviceOTAFiles:(void (^)(NSString * _Nonnull))downloadSuccess andFailure:(void (^)(int))failure {
    NSString *pahtStr = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/iOSUpgradeFiles"];
    ESPDocumentsPath *espDocumentPath = [[ESPDocumentsPath alloc]init];
    BOOL pathBool = [espDocumentPath isSxistAtPath:pahtStr];
    if (!pathBool) {
        [espDocumentPath createDirectory:@"iOSUpgradeFiles"];
    }
    [ESPHomeService downloadWithURL:@"https://raw.githubusercontent.com/XuXiangJun/test/master/light.bin" fileDir:@"" progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"进度= %f",downloadProgress.fractionCompleted * 100);
        //        NSString *downloadProgressStr = [NSString stringWithFormat:@"%f",downloadProgress.fractionCompleted * 100];
        //        NSString *paramjson=[ESPDataConversion jsonFromObject:@{@"status":@"0",@"message":@"下载进度",@"downloadProgress":downloadProgressStr}];
        //        [self sendMsg:@"onDownloadLatestRom" param:paramjson];
    } success:^(NSString * _Nonnull success) {
        NSLog(@"success download fild path--->%@",success);
        downloadSuccess(success);
    } andFailure:^(int fail) {
        NSLog(@"%d",fail);
    }];
}

+ (void)sendDeviceSnifferInfo:(NSString *)mac withSnifferSuccess:(sendDeviceSnifferBlock)snifferSuccess andFailure:(void (^)(int))failure {
    NSDate *lastRequestDate;
    if (lastRequestDate) {
        //        NSLog(@"sendDeviceStatus两次请求时间间隔：%f",[[NSDate date] timeIntervalSinceDate:lastRequestDate]);
        if ([[NSDate date] timeIntervalSinceDate:lastRequestDate]<0.5) {
            return;//过滤频繁操作
        }
    }
    lastRequestDate= [NSDate date];
    
    ESPDocumentsPath *espDocumentPath = [[ESPDocumentsPath alloc]init];
    NSArray *macArr=[mac componentsSeparatedByString:@","];
    NSDictionary *deviceIpWithDic = [ESPDataConversion deviceRequestIpWithMac:macArr];
    NSArray *deviceIpArr = [deviceIpWithDic allKeys];
    if (!ValidArray(deviceIpArr)) {
        return;
    }
//    NSLog(@"%@,%lu",deviceIpArr[0],(unsigned long)deviceIpArr.count);
    for (int i = 0; i < deviceIpArr.count; i ++) {
        [[ESPUploadHandleTool shareInstance] getSnifferInfo:deviceIpArr[i] withDeviceMacs:mac andSuccess:^(NSArray * _Nonnull dic) {
//            NSLog(@"Sniffer dic ---> %@",dic);
            NSString *nameStr;
            NSMutableArray *resultArr = [NSMutableArray arrayWithCapacity:0];
            for (int i = 0; i < dic.count; i ++) {
                ESPSniffer *espsniffer = [dic objectAtIndex:i];
                NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:0];
                if (ValidStr(espsniffer.manufacturerId)) {
                    NSArray *fileArr = [espDocumentPath readFile:@"wifi"];
                    for (int j = 0; j < fileArr.count; j ++) {
                        if ([fileArr[j] containsString:espsniffer.manufacturerId]) {
                            NSArray *contentArr = [fileArr[j] componentsSeparatedByString:@":"];
                            nameStr = contentArr[1];
                        }
                    }
                }else {
                    NSArray *fileArr = [espDocumentPath readFile:@"ble"];
                    for (int j = 0; j < fileArr.count; j ++) {
                        if (espsniffer.meshMac != nil) {
                            NSString *macStr = [espsniffer.meshMac substringToIndex:5];
                            if ([fileArr[j] containsString:macStr]) {
                                NSArray *contentArr = [fileArr[j] componentsSeparatedByString:@":"];
                                nameStr = contentArr[1];
                            }
                        }
                    }
                }
                resultDic[@"type"] = [NSString stringWithFormat:@"%d",espsniffer.snifferType];
                resultDic[@"mac"] = espsniffer.meshMac;
                resultDic[@"channel"] = [NSString stringWithFormat:@"%d",espsniffer.channel];
                resultDic[@"time"] = [NSString stringWithFormat:@"%lu",espsniffer.time];
                resultDic[@"rssi"] = [NSString stringWithFormat:@"%d",espsniffer.rssi];
                resultDic[@"mac"] = espsniffer.name;
                resultDic[@"org"] = nameStr;
                
                [resultArr addObject:resultDic];
            }
            snifferSuccess(resultArr);
        } andFailure:^(int fail) {
            failure(fail);
        }];
    }
}

+ (void)sendDevicesStatusChanged:(NSDictionary *)msgDic withDeviceStatusSuccess:(sendDeviceStatusBlock)statusSuccess andFailure:(void (^)(int))failure {
    
    NSString *mac = [msgDic objectForKey:@"deviceMac"];
    NSMutableDictionary *DevicesOfScanUDP = [NSMutableDictionary dictionaryWithDictionary:[msgDic objectForKey:@"devicesOfScanUDP"]];
    
    NSDate *lastRequestDate;
    if (lastRequestDate) {
        NSLog(@"sendDeviceStatus两次请求时间间隔：%f",[[NSDate date] timeIntervalSinceDate:lastRequestDate]);
        if ([[NSDate date] timeIntervalSinceDate:lastRequestDate]<0.5) {
            return;//过滤频繁操作
        }
    }
    lastRequestDate= [NSDate date];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *ScanUDPKeyArr = [defaults objectForKey:@"DevicesOfScanUDPKeyArr"];
    NSMutableArray *DevicesOfScanUDPKeyArr = [NSMutableArray arrayWithArray:ScanUDPKeyArr];
    NSArray *ScanUDPHostArr = [defaults objectForKey:@"DevicesOfScanUDPHostArr"];
    NSMutableArray *DevicesOfScanUDPHostArr = [NSMutableArray arrayWithArray:ScanUDPHostArr];
    NSArray *ScanUDPValueArr = [defaults objectForKey:@"DevicesOfScanUDPValueArr"];
    NSMutableArray *DevicesOfScanUDPValueArr = [NSMutableArray arrayWithArray:ScanUDPValueArr];
    NSArray *ScanUDPGroupArr = [defaults objectForKey:@"DevicesOfScanUDPGroupArr"];
    NSMutableArray *DevicesOfScanUDPGroupArr = [NSMutableArray arrayWithArray:ScanUDPGroupArr];
    
    NSArray *macsArray = [mac componentsSeparatedByString:@","];
    NSSet *set = [NSSet setWithArray:macsArray];
    NSArray * macArray = [set allObjects];
    //    NSLog(@"macArray个数：%@,ee%@",macsArray,macArray);
    NSMutableArray *DevicesArr = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0; i < macArray.count; i ++) {
        EspDevice *newDevice = DevicesOfScanUDP[macArray[i]];
        if (newDevice==nil) {
            continue;
        }
        [DevicesArr addObject:newDevice];
    }
    NSOperationQueue* opqueue=[[NSOperationQueue alloc] init];
    opqueue.maxConcurrentOperationCount=1;
    [opqueue addOperationWithBlock:^{
        EspActionDeviceInfo *deviceinfoAction = [[EspActionDeviceInfo alloc] init];
        NSMutableDictionary* resps = [deviceinfoAction doActionGetDevicesInfoLocal:DevicesArr];
        if (resps.count > 0) {
            for (int j = 0; j < DevicesArr.count; j ++) {
                EspDevice* device=[DevicesArr objectAtIndex:j];
                //获取详细信息
                EspHttpResponse *response = resps[device.mac];
                if (response != nil) {
                    NSDictionary* responDic=response.getContentJSON;
                    NSMutableDictionary *mDic = [ESPDataConversion deviceDetailData:responDic withEspDevice:device];
                    [DevicesOfScanUDPGroupArr addObject:mDic[@"group"]];
                    if (responDic[@"characteristics"] != nil) {
                        [DevicesOfScanUDPHostArr addObject:device.host];
                        [DevicesOfScanUDPKeyArr addObject:device.mac];
                        [DevicesOfScanUDPValueArr addObject:mDic];
                        device.sendInfo = mDic;
                        DevicesOfScanUDP[device.mac]=device;
                    }
                    NSMutableDictionary *statusResultDic = [NSMutableDictionary dictionaryWithCapacity:0];
                    statusResultDic[@"resultDic"] = mDic;
                    statusResultDic[@"scanUDPDic"] = DevicesOfScanUDP;
                    statusSuccess(statusResultDic);
                }else {
                    failure(8010);
                }
            }
            
            [defaults setValue:DevicesOfScanUDPHostArr forKey:@"DevicesOfScanUDPHostArr"];
            [defaults setValue:DevicesOfScanUDPKeyArr forKey:@"DevicesOfScanUDPKeyArr"];
            [defaults setValue:DevicesOfScanUDPValueArr forKey:@"DevicesOfScanUDPValueArr"];
            [defaults setValue:DevicesOfScanUDPGroupArr forKey:@"DevicesOfScanUDPGroupArr"];
            [defaults synchronize];
            
        }else {
            failure(8010);
        }
    }];
}

+ (void)sendDevicesFoundOrLost:(NSDictionary *)msgDic withDeviceStatusSuccess:(sendDeviceStatusBlock)statusSuccess andFailure:(void (^)(int))failure {
    
    NSString *mac = [msgDic objectForKey:@"deviceMac"];
    NSLog(@"上线下线设备Mac：%@",mac);
    NSMutableDictionary *DevicesOfScanUDP = [NSMutableDictionary dictionaryWithDictionary:[msgDic objectForKey:@"devicesOfScanUDP"]];
    
    NSDate *lastRequestDate;
    if (lastRequestDate) {
        NSLog(@"sendDeviceStatus两次请求时间间隔：%f",[[NSDate date] timeIntervalSinceDate:lastRequestDate]);
        if ([[NSDate date] timeIntervalSinceDate:lastRequestDate]<0.5) {
            return;//过滤频繁操作
        }
    }
    lastRequestDate= [NSDate date];
    
    NSMutableArray *scanUDPArr = [NSMutableArray arrayWithCapacity:0];
    dispatch_queue_t queueT = dispatch_queue_create("my.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);//一个并发队列
    dispatch_group_t grpupT = dispatch_group_create();//一个线程组
    dispatch_group_enter(grpupT);
    dispatch_group_async(grpupT, queueT, ^{
        [[ESPMeshManager share] starScanRootUDP:^(NSArray *devixe) {
            [scanUDPArr addObjectsFromArray:devixe];
        } failblock:^(int code) {
            
        }];
    });
    dispatch_group_async(grpupT, queueT, ^{
        [[ESPMeshManager share] starScanRootmDNS:^(NSArray * _Nonnull devixe) {
            [scanUDPArr addObjectsFromArray:devixe];
        } failblock:^(int code) {
            
        }];
    });
    dispatch_group_async(grpupT, queueT, ^{
        sleep(2);
        //        [[ESPMeshManager share] cancelScanRootUDP];
        [[ESPMeshManager share] cancelScanRootmDNS];
    });
    dispatch_group_notify(grpupT, queueT, ^{
        NSSet *set = [NSSet setWithArray:scanUDPArr];
        NSArray *allArray = [set allObjects];

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
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSArray *ScanUDPKeyArr = [defaults objectForKey:@"DevicesOfScanUDPKeyArr"];
            NSMutableArray *DevicesOfScanUDPKeyArr = [NSMutableArray arrayWithArray:ScanUDPKeyArr];
            NSArray *ScanUDPHostArr = [defaults objectForKey:@"DevicesOfScanUDPHostArr"];
            NSMutableArray *DevicesOfScanUDPHostArr = [NSMutableArray arrayWithArray:ScanUDPHostArr];
            NSArray *ScanUDPValueArr = [defaults objectForKey:@"DevicesOfScanUDPValueArr"];
            NSMutableArray *DevicesOfScanUDPValueArr = [NSMutableArray arrayWithArray:ScanUDPValueArr];
            NSArray *ScanUDPGroupArr = [defaults objectForKey:@"DevicesOfScanUDPGroupArr"];
            NSMutableArray *DevicesOfScanUDPGroupArr = [NSMutableArray arrayWithArray:ScanUDPGroupArr];
            
            EspActionDeviceInfo* deviceinfoAction = [[EspActionDeviceInfo alloc] init];
            NSMutableDictionary* resps = [deviceinfoAction doActionGetDevicesInfoLocal:meshinfoArr];
            
            NSMutableDictionary* newDevices=[NSMutableDictionary dictionaryWithCapacity:0];
            if (resps.count>0) {
                for (int i=0; i<meshinfoArr.count; i++) {
                    EspDevice* newDevice=[meshinfoArr objectAtIndex:i];
                    NSString *url = [EspDeviceUtil getLocalUrlForProtocol:newDevice.httpType host:newDevice.host port:newDevice.port.intValue file:@""];
                    [[NSUserDefaults standardUserDefaults] setValue:url forKey:newDevice.mac];
                    //获取详细信息
                    EspHttpResponse *response = resps[newDevice.mac];
                    if (response != nil) {
                        NSDictionary* responDic=response.getContentJSON;
                        NSMutableDictionary *mDic = [ESPDataConversion deviceDetailData:responDic withEspDevice:newDevice];
                        [DevicesOfScanUDPGroupArr addObject:mDic[@"group"]];
                        if (responDic[@"characteristics"] != nil) {
                            [DevicesOfScanUDPHostArr addObject:newDevice.host];
                            [DevicesOfScanUDPKeyArr addObject:newDevice.mac];
                            [DevicesOfScanUDPValueArr addObject:mDic];
                            newDevice.sendInfo=mDic;
                            newDevices[newDevice.mac]=newDevice;
                        }
                    }
                }
                [defaults setValue:DevicesOfScanUDPHostArr forKey:@"DevicesOfScanUDPHostArr"];
                [defaults setValue:DevicesOfScanUDPKeyArr forKey:@"DevicesOfScanUDPKeyArr"];
                [defaults setValue:DevicesOfScanUDPValueArr forKey:@"DevicesOfScanUDPValueArr"];
                [defaults setValue:DevicesOfScanUDPGroupArr forKey:@"DevicesOfScanUDPGroupArr"];
                [defaults synchronize];
                
                NSArray* oldMacs = DevicesOfScanUDP.allKeys;
                NSArray* newMacs = newDevices.allKeys;
                for (int i=0; i<newMacs.count; i++) {
                    if (![oldMacs containsObject:newMacs[i]]) {
                        //上线
                        EspDevice* tmpDevice=(EspDevice*)newDevices[newMacs[i]];
                        NSString *json=[ESPDataConversion jsonFromObject:tmpDevice.sendInfo];
                        NSMutableDictionary *statusResultDic = [NSMutableDictionary dictionaryWithCapacity:0];
                        statusResultDic[@"result"] = json;
                        statusResultDic[@"code"] = @"8011";
                        statusSuccess(statusResultDic);
                    }
                }
                for (int i=0; i<oldMacs.count; i++) {
                    if (![newMacs containsObject:oldMacs[i]]) {
                        //下线
                        NSString* json=oldMacs[i];
                        NSMutableDictionary *statusResultDic = [NSMutableDictionary dictionaryWithCapacity:0];
                        statusResultDic[@"result"] = json;
                        statusResultDic[@"code"] = @"8012";
                        statusSuccess(statusResultDic);
                        
                    }
                }
                if (newDevices.count>0) {
                    NSMutableDictionary *statusResultDic = [NSMutableDictionary dictionaryWithCapacity:0];
                    statusResultDic[@"result"] = newDevices;
                    statusResultDic[@"code"] = @"8013";
                    statusSuccess(statusResultDic);
                }
            }else {
                failure(8010);
            }
        }];
    });
    dispatch_group_leave(grpupT);
}

+ (void)sendAPPWifiStatus:(void (^)(NSString * _Nonnull))wifiSuccess {
    sleep(1);
    NSString* ssid = ESPMeshManager.share.getCurrentWiFiSsid;
    NSString* bssid = ESPMeshManager.share.getCurrentBSSID;
    bool isConnect = ssid ? true:false;
    if (ssid==nil) {
        ssid=@"";
    }
    if (bssid==nil) {
        bssid=@"";
    }
    NSString* lastSSID=[[NSUserDefaults standardUserDefaults] valueForKey:@"lastSSID"];
    NSString* lastBSSID=[[NSUserDefaults standardUserDefaults] valueForKey:@"lastBSSID"];
    if (lastSSID==nil) {
        lastSSID=@"";
    }
    if (lastBSSID==nil) {
        lastBSSID=@"";
    }
    if (![ssid isEqualToString:lastSSID]) {
        lastSSID=ssid;
        NSDictionary *wifidate = @{@"connected":@(isConnect),@"ssid":ssid,@"bssid":bssid,@"frequency":@""};
        NSString* paramjson=[ESPDataConversion jsonFromObject:wifidate];
        wifiSuccess(paramjson);
//        [self sendMsg:@"onWifiStateChanged" param:paramjson];
        //清楚缓存的设备
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:@"DevicesOfScanUDPHostArr"];
        [defaults removeObjectForKey:@"DevicesOfScanUDPKeyArr"];
        [defaults removeObjectForKey:@"DevicesOfScanUDPValueArr"];
        [defaults removeObjectForKey:@"DevicesOfScanUDPGroupArr"];
        [defaults synchronize];
        [[NSUserDefaults standardUserDefaults] setObject:ssid forKey:@"lastSSID"];
        [[NSUserDefaults standardUserDefaults] setObject:bssid forKey:@"lastBSSID"];
    }else {
        NSDictionary *wifidate = @{@"connected":@(isConnect),@"ssid":lastSSID,@"bssid":lastBSSID,@"frequency":@""};
        NSString* paramjson=[ESPDataConversion jsonFromObject:wifidate];
        wifiSuccess(paramjson);
//        [self sendMsg:@"onWifiStateChanged" param:paramjson];
    }
}

//设置状态栏背景颜色和字体颜色
+ (void)setSystemStatusBar:(id)message {
    if (!ValidDict(message)) {
        return;
    }
    if ([message objectForKey:@"defaultStyle"]) {
        [UIApplication sharedApplication].statusBarStyle =  UIStatusBarStyleLightContent;
    }else {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    }
    NSArray *bgArr = [message objectForKey:@"background"];
    CGFloat r = [bgArr[0] floatValue] / 255.0;
    CGFloat g = [bgArr[1] integerValue] / 255.0;
    CGFloat b = [bgArr[2] integerValue] / 255.0;
    CGFloat a = [bgArr[3] integerValue] / 255.0;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"statusBarBackgroundColor" object:[UIColor colorWithRed:r green:g blue:b alpha:a]];
}

@end
