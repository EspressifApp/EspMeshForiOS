//
//  ESPDataConversion.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/1/4.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import "ESPDataConversion.h"

@implementation ESPDataConversion
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
    if (responDic[@"layer"]) {
        mDic[@"layer"]=responDic[@"layer"];
    }else {
        mDic[@"layer"]=@"";
    }
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

@end
