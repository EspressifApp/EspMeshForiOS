//
//  ESPUploadHandleTool.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/26.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "ESPUploadHandleTool.h"
#import "EspDeviceUtil.h"

@interface ESPUploadHandleTool()<NSURLSessionTaskDelegate>


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
    }
    return instacne;
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

- (NSURLSessionTask *)requestWithIpUrl:(NSString *)ipUrl withRequestHeader:(NSDictionary *)requestHeader withBodyContent:(NSDictionary *)bodyContent andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(int))failure {
    
    NSURL *url=[NSURL URLWithString:ipUrl];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
    //设置提交方式
    [request setHTTPMethod:@"post"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:requestHeader[@"meshNodeMac"] forHTTPHeaderField:@"Mesh-Node-Mac"];
    [request setValue:requestHeader[@"meshNodeNum"] forHTTPHeaderField:@"Mesh-Node-Num"];
    [request setValue:@"close" forHTTPHeaderField:@"Connection"];
    if (requestHeader[@"rootResponse"]) {
        [request setValue:requestHeader[@"rootResponse"] forHTTPHeaderField:@"Root-Response"];
    }
    [request setTimeoutInterval:300];
//    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
//    configuration.HTTPMaximumConnectionsPerHost = 20;
    //提交参数
//    NSData *binData=[[NSData alloc]initWithContentsOfFile:filePaths[i]];
    NSData *data = [NSJSONSerialization dataWithJSONObject:bodyContent options:0 error:nil];
    [request setHTTPBody:data];
    
//    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
//    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
//    config.URLCache = nil;
    //会话
//    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task=[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"localizedDescription1-->%@",error.localizedDescription);
            failure ? failure((int)error) : nil;
        }else {
            
//            NSLog(@">>>>>>expectedContentLength%@",[NSString stringWithFormat:@"%lld",response.expectedContentLength]);
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
//                NSLog(@"%@",jsonMutableDic);
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

- (NSURLSessionTask *)meshNodeMac:(NSString *)meshNodeMac andWithFirmwareUrl:(NSString *)firmwareUrl withIPUrl:(NSString *)ipUrl andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(int))failure {
    
    NSString *urlstr= [NSString stringWithFormat:@"http://%@:80/ota/url",ipUrl];
    NSURL *url=[NSURL URLWithString:urlstr];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
    //设置提交方式
    [request setHTTPMethod:@"post"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:meshNodeMac forHTTPHeaderField:@"Mesh-Node-Mac"];
    [request setValue:firmwareUrl forHTTPHeaderField:@"Firmware-Url"];
    [request setTimeoutInterval:300];
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

@end
