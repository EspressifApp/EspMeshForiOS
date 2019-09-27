//
//  ESPUploadHandleTool.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/26.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "ESPUploadHandleTool.h"
#import "EspDeviceUtil.h"

#import "ESPSniffer.h"

#define TYPE_RSSI               1
#define TYPE_BSSID              2
#define TYPE_TIME               3
#define TYPE_NAME               4
#define TYPE_CHANNEL            5
#define TYPE_MANUFACTURER       6

@interface ESPUploadHandleTool()<NSURLSessionTaskDelegate>

@property (nonatomic, strong)NSMutableArray *taskArray;

@property (nonatomic, strong)NSURLSession *sendSession;

@property (nonatomic, strong)NSString *meshNodeMac;

@property (nonatomic, strong)NSMutableArray *resultArr;

@end
@implementation ESPUploadHandleTool
#pragma mark init
/**
 单例
 
 @return 单例
 */
+ (instancetype)shareInstance
{
    static ESPUploadHandleTool *instacne = nil;
    if (instacne==nil) {
        instacne=[[ESPUploadHandleTool alloc]init];
        //初始化
        [instacne sendSessionInit];
    }
    return instacne;
}

- (void)sendSessionInit {
    self.sendSession = [NSURLSession sharedSession];
}


- (NSMutableArray *)taskArray{
    if (!_taskArray) {
        _taskArray = [NSMutableArray arrayWithCapacity:3];
    }
    return _taskArray;
}

- (NSURLSessionTask *)uploadFileWithURL:(NSString *)URL parameters:(id)parameters names:(NSArray<NSString *> *)names filePaths:(NSArray<NSString *> *)filePaths progress:(ProgressBackBlock)progress success:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(int))failure {
    
    _Progress = progress;
    NSURL *url=[NSURL URLWithString:URL];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
    //设置提交方式
    [request setHTTPMethod:@"post"];
    [request setValue:parameters[@"meshNodeMac"] forHTTPHeaderField:@"Mesh-Node-Mac"];
    [request setValue:parameters[@"firmwareName"] forHTTPHeaderField:@"Firmware-Name"];
    
    NSURLSessionDataTask *task;
    //提交参数
    for (int i = 0; i < filePaths.count; i ++) {
        NSData *binData=[[NSData alloc]initWithContentsOfFile:filePaths[i]];
        [request setHTTPBody:binData];
        //会话
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        task=[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            //        {"status_code":0,"status_msg":"MDF_OK"}
            if (error) {
                failure ? failure((int)error) : nil;
            }else {
                NSLog(@"++++++expectedContentLength%@",[NSString stringWithFormat:@"%lld",response.expectedContentLength]);
                NSMutableDictionary *jsonMutableDic = [NSMutableDictionary dictionaryWithCapacity:0];
                NSString *dataStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"%@",dataStr);
                if ([@"-1" isEqualToString:[NSString stringWithFormat:@"%lld",response.expectedContentLength]]) {
                    NSMutableArray *allJsonArr = [NSMutableArray arrayWithCapacity:0];
                    
                    NSArray *dataArr = [EspDeviceUtil getChunkedResponseListForData:data];
                    for (int i = 0; i < dataArr.count; i ++) {
                        EspHttpResponse *espHttpResponse = dataArr[i];
                        NSData *content = espHttpResponse.content;
                        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:content options:NSJSONReadingMutableLeaves error:nil];
                        NSMutableDictionary * mutDic2 = [[NSMutableDictionary alloc]initWithDictionary:jsonDict];
                        NSString *messageStr = espHttpResponse.message;
                        NSString *code = [NSString stringWithFormat:@"%d",espHttpResponse.code];
                        NSString *meshNodeMac = [espHttpResponse getHeaderValueForKey:@"Mesh-Node-Mac"];
                        mutDic2[@"message"] = messageStr;
                        mutDic2[@"code"] = code;
                        mutDic2[@"mac"] = meshNodeMac;
                        [allJsonArr addObject:mutDic2];
                    }
                    jsonMutableDic[@"result"] = allJsonArr;
                    NSLog(@"%@",jsonMutableDic);
                    success ? success(jsonMutableDic) : nil;
                }else {
                    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                    jsonMutableDic[@"result"] = jsonDict;
                    success ? success(jsonMutableDic) : nil;
                }
//                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
//                success ? success(jsonDict) : nil;
            }
        }];
        //启动任务
        [task resume];
        
    }
    return task;
}

//使用NSURLSessionTaskDelegate代理监听上传进度
#pragma mark --NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    // 计算进度
    float progress = (float)totalBytesSent / totalBytesExpectedToSend;
    //    NSLog(@"进度 %f",progress * 100);
    _Progress(progress * 50);
}

- (NSURLSessionTask *)requestWithIpUrl:(NSString *)ipUrl withRequestHeader:(NSDictionary *)requestHeader withBodyContent:(NSDictionary *)bodyContent andSuccess:(void (^)(NSArray * _Nonnull))success andFailure:(void (^)(int))failure {
    
    NSURL *url=[NSURL URLWithString:ipUrl];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
    //设置提交方式
    [request setHTTPMethod:@"post"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:requestHeader[@"meshNodeNum"] forHTTPHeaderField:@"Mesh-Node-Num"];
    [request setValue:@"close" forHTTPHeaderField:@"Connection"];
    if (requestHeader[@"rootResponse"]) {
        [request setValue:requestHeader[@"rootResponse"] forHTTPHeaderField:@"Root-Response"];
    }
    if ([requestHeader[@"isGroup"] integerValue] == 1) {
        [request setValue:requestHeader[@"meshNodeGroup"] forHTTPHeaderField:@"Mesh-Node-Group"];
        [request setValue:requestHeader[@"meshNodeMac"] forHTTPHeaderField:@"Mesh-Node-Mac"];
    }else {
        [request setValue:requestHeader[@"meshNodeMac"] forHTTPHeaderField:@"Mesh-Node-Mac"];
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:bodyContent options:0 error:nil];
    [request setHTTPBody:data];
    
    if ([requestHeader[@"taskStr"] intValue] == 1) {
        //首先遍历存放task的数组，并且取消之前的http请求
        [self.taskArray enumerateObjectsUsingBlock:^(NSURLSessionDataTask *task, NSUInteger idx, BOOL * _Nonnull stop) {
            //        NSLog(@"这个任务取消之前的状态是：：：：：%ld",task.state);
            [task cancel];//取消http请求
            //        NSLog(@"这个任务取消之后的状态是：：：：：%ld",task.state);
        }];
        //移除self.taskArray中所有的任务
        [self.taskArray removeAllObjects];
    }
    
    NSURLSessionDataTask *tasks = [self.sendSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
//            NSLog(@"localizedDescription1-->%@",error.localizedDescription);
            failure ? failure((int)error) : nil;
        }else {
            
//            NSLog(@">>>>>>expectedContentLength%@",[NSString stringWithFormat:@"%lld",response.expectedContentLength]);
//            NSMutableDictionary *jsonMutableDic = [NSMutableDictionary dictionaryWithCapacity:0];
            if ([@"-1" isEqualToString:[NSString stringWithFormat:@"%lld",response.expectedContentLength]]) {
                NSMutableArray *allJsonArr = [NSMutableArray arrayWithCapacity:0];
                
                NSArray *dataArr = [EspDeviceUtil getChunkedResponseListForData:data];
                for (int i = 0; i < dataArr.count; i ++) {
                    EspHttpResponse *espHttpResponse = dataArr[i];
                    NSData *content = espHttpResponse.content;
                    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:content options:NSJSONReadingMutableLeaves error:nil];
                    NSMutableDictionary * mutDic2 = [[NSMutableDictionary alloc]initWithDictionary:jsonDict];
                    NSString *messageStr = espHttpResponse.message;
                    NSString *code = [NSString stringWithFormat:@"%d",espHttpResponse.code];
                    NSString *meshNodeMac = [espHttpResponse getHeaderValueForKey:@"Mesh-Node-Mac"];
                    mutDic2[@"message"] = messageStr;
                    mutDic2[@"code"] = code;
                    mutDic2[@"mac"] = meshNodeMac;
                    [allJsonArr addObject:mutDic2];
                }
//                jsonMutableDic[@"result"] = allJsonArr;
//                NSLog(@"%@",jsonMutableDic);
                success ? success(allJsonArr) : nil;
            }else {
                NSMutableArray *allJsonArr = [NSMutableArray arrayWithCapacity:0];
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                [allJsonArr addObject:jsonDict];
//                jsonMutableDic[@"result"] = allJsonArr;
                success ? success(allJsonArr) : nil;
            }
        }
    }];
    //启动任务
    [tasks resume];
    [self.taskArray addObject:tasks];
    
    return tasks;
}

- (NSURLSessionTask *)meshNodeMac:(NSString *)meshNodeMac andWithFirmwareUrl:(NSString *)firmwareUrl withIPUrl:(NSString *)ipUrl andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(int))failure {
    
    NSString *urlstr= [NSString stringWithFormat:@"http://%@:80/ota/url",ipUrl];
    NSURL *url=[NSURL URLWithString:urlstr];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
    //设置提交方式
    [request setHTTPMethod:@"post"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:meshNodeMac forHTTPHeaderField:@"Mesh-Node-Mac"];
    [request setValue:firmwareUrl forHTTPHeaderField:@"Firmware-Url"];
    [request setTimeoutInterval:30];
    //会话
    NSURLSession *session=[NSURLSession sharedSession];
    NSURLSessionDataTask *task=[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"localizedDescription2-->%@",error.localizedDescription);
            failure ? failure((int)error) : nil;
        }else {
            
            NSLog(@"----expectedContentLength%@",[NSString stringWithFormat:@"%lld",response.expectedContentLength]);
            NSMutableDictionary *jsonMutableDic = [NSMutableDictionary dictionaryWithCapacity:0];
            if ([@"-1" isEqualToString:[NSString stringWithFormat:@"%lld",response.expectedContentLength]]) {
                NSMutableArray *allJsonArr = [NSMutableArray arrayWithCapacity:0];
                
                NSArray *dataArr = [EspDeviceUtil getChunkedResponseListForData:data];
                for (int i = 0; i < dataArr.count; i ++) {
                    EspHttpResponse *espHttpResponse = dataArr[i];
                    NSData *content = espHttpResponse.content;
                    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:content options:NSJSONReadingMutableLeaves error:nil];
                    NSMutableDictionary * mutDic2 = [[NSMutableDictionary alloc]initWithDictionary:jsonDict];
                    NSString *messageStr = espHttpResponse.message;
                    NSString *code = [NSString stringWithFormat:@"%d",espHttpResponse.code];
                    NSString *meshNodeMac = [espHttpResponse getHeaderValueForKey:@"Mesh-Node-Mac"];
                    mutDic2[@"message"] = messageStr;
                    mutDic2[@"code"] = code;
                    mutDic2[@"mac"] = meshNodeMac;
                    [allJsonArr addObject:mutDic2];
                }
                jsonMutableDic[@"result"] = allJsonArr;
                NSLog(@"-----%@",jsonMutableDic);
                success ? success(jsonMutableDic) : nil;
            }else {
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                jsonMutableDic[@"result"] = jsonDict;
                success ? success(jsonMutableDic) : nil;
            }
        }
    }];
    //启动任务
    [task resume];
    
    return task;
}

- (NSURLSessionTask *)stopOTA:(NSString *)ipUrl andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(int))failure {
    NSString *urlstr= [NSString stringWithFormat:@"http://%@:80/ota/stop",ipUrl];
    NSURL *url=[NSURL URLWithString:urlstr];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
    //设置提交方式
    [request setHTTPMethod:@"post"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    //会话
    NSURLSession *session=[NSURLSession sharedSession];
    NSURLSessionDataTask *task=[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"localizedDescription3-->%@",error.localizedDescription);
            failure ? failure((int)error) : nil;
        }else {
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            success ? success(jsonDict) : nil;
        }
    }];
    //启动任务
    [task resume];
    
    return task;
}

- (NSURLSessionTask *)getSnifferInfo:(NSString *)ipUrl withDeviceMacs:(NSString *)deviceMacs andSuccess:(void (^)(NSArray * _Nonnull))success andFailure:(void (^)(int))failure {
    NSString *urlstr= [NSString stringWithFormat:@"http://%@:80/device_request",ipUrl];
    NSURL *url=[NSURL URLWithString:urlstr];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
    //设置提交方式
    [request setHTTPMethod:@"post"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:deviceMacs forHTTPHeaderField:@"Mesh-Node-Mac"];
    
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"request":@"get_sniffer_info"} options:0 error:nil];
    [request setHTTPBody:data];
    //会话
    NSURLSession *session=[NSURLSession sharedSession];
    NSURLSessionDataTask *task=[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"localizedDescription3-->%@",error.localizedDescription);
            failure ? failure((int)error) : nil;
        }else {
            //响应头信息
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            NSDictionary *headerDic = res.allHeaderFields;
//            NSLog(@"allHeaderFields ===> %@ Mesh-Node-Mac ===> %@",headerDic,[headerDic objectForKey:@"Mesh-Node-Mac"]);
            self.meshNodeMac = [headerDic objectForKey:@"Mesh-Node-Mac"];
            
            NSArray *result = [self testByte:data];
//            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            success ? success(result) : nil;
        }
    }];
    //启动任务
    [task resume];
    return task;
}

- (NSArray *)testByte:(NSData *)data {
    Byte *testByte = (Byte *)[data bytes];
    NSString *hexStr=@"";
    for (int i = 0; i < [data length]; i++) {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",testByte[i]&0xff]; ///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
//    NSLog(@"bytes 的16进制数为:%@",hexStr);
    
    BOOL readSnifferLen = YES;
    int snifferLen = -1;
    BOOL readSnifferType = NO;
    int snifferType = -1;
    
    NSMutableData *snifferBytes = [[NSMutableData alloc]init];
    uint8_t type[1];
    
    NSMutableArray *resultArr = [NSMutableArray arrayWithCapacity:0];
    
    for (int j = 0; j < [data length]; j++) {
        if (readSnifferLen) {
            snifferLen = testByte[j] & 0xff;
            readSnifferLen = NO;
            readSnifferType = YES;
            continue;
        }
        
        if (readSnifferType) {
            snifferType = testByte[j] & 0xff;
            readSnifferType = false;
            continue;
        }
        type[0] = testByte[j];
        [snifferBytes appendData:[[NSData alloc]initWithBytes:type length:sizeof(type)]];
        
        if (snifferBytes.length < snifferLen - 1 ) {
            continue;
        }
//        NSLog(@"%lu,%@,%lu",sizeof(snifferBytes),snifferBytes,(unsigned long)snifferBytes.length);
        ESPSniffer *espSniffer = [self getSnifferWithData:snifferBytes];
        
        NSDate *dateNow = [NSDate date];
        long datalong = [dateNow timeIntervalSince1970];
        if (espSniffer != nil) {
            espSniffer.snifferType = snifferType;
            long pkgTime = datalong - espSniffer.time;
            espSniffer.time = pkgTime;
            espSniffer.meshMac = self.meshNodeMac;
            
            [resultArr addObject:espSniffer];
        }
        
        [snifferBytes replaceBytesInRange:NSMakeRange(0, [snifferBytes length]) withBytes:NULL length:0];
        readSnifferLen = YES;
        
    }
    
    return resultArr;
}

- (ESPSniffer *)getSnifferWithData:(NSData *)SnifferData {
    ESPSniffer *espsniffer = [[ESPSniffer alloc]init];
    
    Byte *testByte = (Byte *)[SnifferData bytes];
    NSString *contentStr=@"";
    for (int i = 0; i < [SnifferData length]; i++) {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",testByte[i]&0xff]; ///16进制数
        if([newHexStr length]==1)
            contentStr = [NSString stringWithFormat:@"%@0%@",contentStr,newHexStr];
        else
            contentStr = [NSString stringWithFormat:@"%@%@",contentStr,newHexStr];
    }
//    NSLog(@"SnifferData 的16进制数为:%@",contentStr);
    
    int contentLength = -1;
    int contentType = -1;
    
    NSMutableData *snifferContentData = [[NSMutableData alloc]init];
    uint8_t typeContent[1];
    
    for (int j = 0; j < [SnifferData length]; j++) {
        if (contentLength < 0) {
            contentLength = testByte[j] & 0xff;
            continue;
        }
        
        if (contentType < 0) {
            contentType = testByte[j] & 0xff;
            continue;
        }
        
        typeContent[0] = testByte[j];
        [snifferContentData appendData:[[NSData alloc]initWithBytes:typeContent length:sizeof(typeContent)]];
    
        if (snifferContentData.length < contentLength - 1 ) {
            continue;
        }
//        NSLog(@"%lu,%@,%lu",sizeof(snifferContentData),snifferContentData,(unsigned long)snifferContentData.length);
        
        Byte *espByte = (Byte *)[snifferContentData bytes];
        int rssiCount;
        NSString *bssidStr;
        NSString *timeStr;
        NSString *nameStr;
        int channelCount;
        NSString *manufacturerIdStr;
        switch (contentType) {
            case TYPE_RSSI:
                rssiCount = espByte[0];
                espsniffer.rssi = rssiCount;
                break;
                
            case TYPE_BSSID:
                bssidStr = [NSString stringWithFormat:@"%x%x%x%x%x%x",espByte[0],espByte[1],espByte[2],espByte[3],espByte[4],espByte[5]];
                espsniffer.bssid = bssidStr;
                break;
                
            case TYPE_TIME:
                timeStr = [NSString stringWithFormat:@"%x%x%x%x",espByte[3],espByte[2],espByte[1],espByte[0]];
                long timeLong = strtoul(timeStr.UTF8String, 0, 16);
                espsniffer.time = timeLong;
                break;
                
            case TYPE_NAME:
                nameStr = [[NSString alloc]initWithData:snifferContentData encoding:NSUTF8StringEncoding];
                espsniffer.name = nameStr;
                break;
                
            case TYPE_CHANNEL:
                channelCount = espByte[0];
                espsniffer.channel = channelCount;
                break;
                
            case TYPE_MANUFACTURER:
                manufacturerIdStr = [NSString stringWithFormat:@"%x%x",espByte[1],espByte[0]];
                espsniffer.manufacturerId = manufacturerIdStr;
                break;
                
            default:
                break;
        }
        contentLength = -1;
        contentType = -1;
        [snifferContentData replaceBytesInRange:NSMakeRange(0, [snifferContentData length]) withBytes:NULL length:0];
        
    }
    
    
    return espsniffer;
}

@end
