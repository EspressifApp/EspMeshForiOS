//
//  ESPNetWorking.m
//  ESPMeshLibrary
//
//  Created by zhaobing on 2018/6/21.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "ESPNetWorking.h"
#import "AFNetworking.h"

#import "EspHttpParams.h"
#import "EspHttpResponse.h"
#import "EspHttpUtils.h"
#import "EspCommonUtils.h"
#import "EspJsonUtils.h"

@interface ESPNetWorking()
@end

@implementation ESPNetWorking

+ (void) httpRequest:(NSString *)urlStr method:(NSString *)method body:(NSDictionary *)body headers:(NSDictionary *)headers timeOut:(NSTimeInterval)timeOut callback:(nullable void (^)(NSString *msg, NSDictionary *data))callback {
    // Create request
    NSLog(@"Http request url = %@", urlStr);
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
   
    [request setTimeoutInterval:timeOut];
    [request setHTTPMethod:method];
    [request setValue:@"close" forHTTPHeaderField:@"Connection"];
    if (headers.count>0) {
        [request setAllHTTPHeaderFields:headers];
    }
    
    if (body) {
        [request setHTTPBody:[EspJsonUtils getDataWithDictionary:body]];
        NSLog(@"Http request header:%@", body);
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"Http request header response:%@", data);
            callback(@"success",[EspJsonUtils getDictionaryWithData:data]);
        } else {
            NSLog(@"http error: %@", error);
        }
    }];
    [task resume];
    
    
}
+ (NSMutableArray*)getMeshInfoFromHost:(EspDevice *)device {
    NSString *url = [ESPNetWorking getLocalUrlForProtocol:device.httpType host:device.host port:device.port file:@"/mesh_info"];
    EspHttpParams *params = [[EspHttpParams alloc] init];
    params.tryCount = 3;
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:0];
    
    while (YES) {
        EspHttpResponse *response = [EspHttpUtils getForUrl:url params:params headers:nil];
        if ([EspCommonUtils isNull:response]) {
            break;
        }
        
        if (response.code != 200) {
            break;
        }
        
        NSString *meshID;
        int nodeCount;
        NSArray<NSString *> *nodeMacs;
        @try {
            meshID = [response getHeaderValueForKey:@"Mesh-Id"];
            nodeCount = [[response getHeaderValueForKey:@"Mesh-Node-Num"] intValue];
            nodeMacs = [[response getHeaderValueForKey:@"Mesh-Node-Mac"] componentsSeparatedByString:@","];
        } @catch (NSException *e) {
            NSLog(@"e---> %@", e);
            break;
        }
        
        for(NSString *mac in nodeMacs) {
            EspDevice *node = [[EspDevice alloc] init];
            node.mac = mac;
            node.meshID = meshID;
            node.host = device.host;
            node.httpType = device.httpType;
            node.port = device.port;
            //[node addState:EspDeviceStateLocal];
            [result addObject:node];
        }
        
        if (nodeCount == [nodeMacs count]) {
            break;
        }
    }
    
    return result;
}
+ (NSString *)getLocalUrlForProtocol:(NSString *)protocol host:(NSString *)host port:(NSString *)port file:(NSString *)file {
    NSString *urlStr = [NSString stringWithFormat:@"%@://%@:%@%@", protocol, host, port, file];
    urlStr = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return urlStr;
}

+(void)requestOTAStatus:(NSArray<EspDevice *> *)devices binPath:(NSString *)binPath callback:(NetWorkCallBack)callback{
    if (devices.count==0) {
        callback(@"error:设备数为0",@{});
        return;
    }
    EspDevice* device=devices[0];
    NSString*macs=device.mac;
    for (int i=1; i<devices.count; i++) {
        macs=[NSString stringWithFormat:@"%@,%@",macs,devices[i].mac];
    }
    NSString* url=[self getLocalUrlForProtocol:device.httpType host:device.host port:device.port file:@"/device_request"];
   
    
    NSDictionary*headers=@{
                           @"Mesh-Node-Num":[NSString stringWithFormat:@"%lu", (unsigned long)[devices count]],
                           @"Mesh-Node-Mac":macs,
                           @"Content-Type":@"application/json"
                           };
    NSData *binData = [NSData dataWithContentsOfFile:binPath];
    NSString *binVersion = [binPath componentsSeparatedByString:@"/"].lastObject;
    binVersion=[binVersion substringWithRange:NSMakeRange(0,binVersion.length-4)];
    NSDictionary*body=@{
                        @"request":@"ota_status",
                        @"ota_bin_version":binVersion,
                        @"ota_bin_len":[NSNumber numberWithUnsignedLong:binData.length],
                        @"package_length":@1440
                        };

    [self httpRequest:url method:@"POST" body:body headers:headers timeOut:5 callback:callback];
    
    
}
@end
