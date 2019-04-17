//
//  DeviceUtil.m
//  Esp32Mesh
//
//  Created by AE on 2018/2/23.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspDeviceUtil.h"
#import "EspCommonUtils.h"
#import "EspConstants.h"
#import "EspHttpUtils.h"
#import "EspActionDevice.h"
#import "EspBlockingQueue.h"

static NSString * const EspFileRequest = @"/device_request";

@interface EspDeviceRequestParams : NSObject

@property(nonatomic, strong) NSString *protocol;
@property(nonatomic, assign) int port;
@property(nonatomic, strong) NSMutableArray *macs;

@end

@implementation EspDeviceRequestParams

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.macs = [NSMutableArray array];
    }
    return self;
}

@end

@implementation EspDeviceUtil

+ (EspHttpResponse *)httpPostForUrl:(NSString *)url content:(NSData *)content params:(EspHttpParams *)params headers:(NSMutableDictionary *)headers {
    return [EspHttpUtils postForUrl:url content:content params:params headers:headers];
}

+ (NSString *)getLocalUrlForProtocol:(NSString *)protocol host:(NSString *)host port:(int)port file:(NSString *)file {
    NSString *urlStr = [NSString stringWithFormat:@"%@://%@:%d%@", protocol, host, port, file];
    urlStr = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return urlStr;
}

+ (EspHttpResponse *)httpLocalRequestForDevice:(EspDevice *)device content:(NSData *)content params:(EspHttpParams *)params headers:(NSMutableDictionary *)headers {
    return [EspDeviceUtil httpLocalRequestForProtocol:[device httpType] host:[device host] port:[[device port] intValue] deviceMac:device.mac content:content params:params headers:headers];
}

+ (EspHttpResponse *)httpLocalRequestForProtocol:(NSString *)protocol host:(NSString *)host port:(int)port deviceMac:(NSString *)mac content:(NSData *)content params:(EspHttpParams *)params headers:(NSMutableDictionary *)headers {
    NSString *url = [EspDeviceUtil getLocalUrlForProtocol:protocol host:host port:port file:EspFileRequest];
    if ([EspCommonUtils isNull:headers]) {
        headers = [NSMutableDictionary dictionary];
    }
    [headers setObject:@"1" forKey:EspHeaderNodeNum];
    [headers setObject:mac forKey:EspHeaderNodeMac];
    [headers setObject:EspHttpHeaderValueContentTypeJSON forKey:EspHttpHeaderConentType];
    
    return [EspDeviceUtil httpPostForUrl:url content:content params:params headers:headers];
}

+ (NSArray<EspHttpResponse *> *)httpLocalMulticastRequestForDevices:(NSArray<EspDevice *> *)devices content:(NSData *)content params:(EspHttpParams *)httpParams headers:(NSMutableDictionary *)headers multithread:(BOOL)multithread {
    NSMutableArray * const result = [NSMutableArray array];
    
    NSMutableDictionary *paramsDict = [NSMutableDictionary dictionary];
    for (EspDevice *device in devices) {
        NSString *hostAddress = device.host;
        EspDeviceRequestParams *params = [paramsDict objectForKey:hostAddress];
        if ([EspCommonUtils isNull:params]) {
            params = [[EspDeviceRequestParams alloc] init];
            params.protocol = device.httpType;
            params.port = device.port.intValue;
            [paramsDict setObject:params forKey:hostAddress];
        }
        [params.macs addObject:device.mac];
    }
    
    EspBlockingQueue *blockingQueue = [[EspBlockingQueue alloc] init];
    NSMutableArray *countArray = [NSMutableArray array];
    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];
    for (NSString *key in paramsDict) {
        NSString *host = key;
        EspDeviceRequestParams *params = paramsDict[key];
        
        [countArray addObject:[NSObject new]];
        
        [opQueue addOperationWithBlock:^{
            NSArray *respArray = [EspDeviceUtil httpLocalMulticastRequestForProtocol:params.protocol host:host port:params.port deviceMacs:params.macs content:content params:httpParams headers:headers multithread:multithread];
            if (respArray) {
                [blockingQueue enqueue:respArray];
            } else {
                [blockingQueue enqueue:[NSArray array]];
            }
        }];
    }
    
    NSUInteger count = [countArray count];
    for (int i = 0; i < count; i++) {
        NSArray *respArray = blockingQueue.dequeue;
        [result addObjectsFromArray:respArray];
    }
    
    return result;
}

+ (NSArray<EspHttpResponse *> *)httpLocalMulticastRequestForProtocol:(NSString *)protocol host:(NSString *)host port:(int)port deviceMacs:(NSArray<NSString *> *)macs content:(NSData *)content params:(EspHttpParams *)params headers:(NSMutableDictionary *)headers multithread:(BOOL)multithread {
    NSMutableArray * const result = [NSMutableArray array];
    
    const long macChunkLimit = multithread ? 30 : NSIntegerMax;
    
    NSString *url = [EspDeviceUtil getLocalUrlForProtocol:protocol host:host port:port file:EspFileRequest];
    
    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];
    opQueue.maxConcurrentOperationCount = 5;
    
    EspBlockingQueue *blockingQueue = [[EspBlockingQueue alloc] init];
    NSMutableArray *countArray = [NSMutableArray array];
    
    NSMutableArray *macArray = [NSMutableArray array];
    for (long i = 0; i < [macs count]; i++) {
        NSString *mac = macs[i];
        
        [macArray addObject:mac];
        if ([macArray count] == macChunkLimit || i == [macs count] - 1) {
            NSArray *opMacArray = [NSArray arrayWithArray:macArray];
            [macArray removeAllObjects];
            [countArray addObject:[NSObject new]];
            [opQueue addOperationWithBlock:^{
                NSArray *respArray = [EspDeviceUtil multicastForUrl:url macs:opMacArray content:content httpParams:params headers:headers];
                if (respArray) {
                    [blockingQueue enqueue:respArray];
                } else {
                    [blockingQueue enqueue:[NSArray array]];
                }
            }];
        }
    }
    
    NSUInteger count = [countArray count];
    for (int i = 0; i < count; i++) {
        NSArray *respArray = [blockingQueue dequeue];
        [result addObjectsFromArray:respArray];
    }
    
    return result;
}

+ (NSArray<EspHttpResponse *> *)multicastForUrl:(NSString *)url macs:(NSArray<NSString *> *)macs content:(NSData *)content httpParams:(EspHttpParams *)params headers:(NSMutableDictionary *)headers {
    NSMutableString *macValue = [NSMutableString string];
    for (NSString *mac in macs) {
        [macValue appendString:mac];
        [macValue appendString:@","];
    }
    NSRange delRange = { [macValue length] - 1, 1 };
    [macValue deleteCharactersInRange:delRange];
    
    if ([EspCommonUtils isNull:headers]) {
        headers = [NSMutableDictionary dictionary];
    }
    [headers setObject:[NSString stringWithFormat:@"%lu", (unsigned long)[macs count]] forKey:EspHeaderNodeNum];
    [headers setObject:macValue forKey:EspHeaderNodeMac];
    [headers setObject:EspHttpHeaderValueContentTypeJSON forKey:EspHttpHeaderConentType];
    
    EspHttpResponse *response = [EspDeviceUtil httpPostForUrl:url content:content params:params headers:headers];
    if (!response) {
        return nil;
    }
    
    NSMutableArray *result = [NSMutableArray array];
    BOOL chunkedResp = [macs count] > 1;
    if (chunkedResp) {
        NSArray *chunkedRespArray = [EspDeviceUtil getChunkedResponseListForData:response.content];
        if (chunkedRespArray != nil) {
            [result addObjectsFromArray:chunkedRespArray];
        }
    } else {
        [result addObject:response];
    }
    return result;
}

+ (NSArray<EspHttpResponse *> *)getChunkedResponseListForData:(NSData *)data {
    // TODO
    if ([EspCommonUtils isNull:data]) {
        return nil;
    }
    
    NSMutableArray *result = [NSMutableArray array];
    
    Byte *bytes = (Byte *)[data bytes];
    NSMutableData *temp = [NSMutableData data];
    long totalLen = data.length;
    for (long index = 0; index < totalLen; index++) {
        // Get header data
        Byte headerBytes[1] = { bytes[index] };
        [temp appendBytes:headerBytes length:1];
        if (![EspDeviceUtil headEnd:temp]) {
            continue;
        }
        
        // Get content length
        NSString *headStr = [[NSString alloc] initWithData:temp encoding:NSUTF8StringEncoding];
        NSArray *headArray = [headStr componentsSeparatedByString:@"\r\n"];
        long contentLength = -1;
        for (NSString *s in headArray) {
            NSArray *kv = [s componentsSeparatedByString:@": "];
            @try {
                NSString *headerName = [kv[0] uppercaseString];
                if ([headerName isEqualToString:[EspHttpHeaderContentLength uppercaseString]]) {
                    contentLength = [kv[1] intValue];
                    break;
                }
            }
            @catch (NSException *e) {
                NSLog(@"%@", e.name);
            }
        }
        
        // Get content data
        for (long contentCount = 0; contentCount < contentLength; contentCount++) {
            index++;
            if (index >= totalLen) {
                break;
            }
            
            Byte contentBytes[1] = {bytes[index]};
            [temp appendBytes:contentBytes length:1];
        }
        
        // Get EspHttpResponse
        EspHttpResponse *response = [EspHttpUtils getResponseWithFixedLengthData:temp];
        if (response != nil) {
            [result addObject:response];
        }
        
        // Clear temp data
        [temp replaceBytesInRange:NSMakeRange(0, [temp length]) withBytes:NULL length:0];
    }
    
    return result;
}

+ (BOOL)headEnd:(NSData *)data {
    if (data.length < 4) {
        return NO;
    }
    
    Byte endBytes[4] = {0};
    NSRange range = {data.length - 4, 4};
    [data getBytes:endBytes range:range];
    if (endBytes[0] != '\r') {
        return NO;
    }
    if (endBytes[1] != '\n') {
        return NO;
    }
    if (endBytes[2] != '\r') {
        return NO;
    }
    if (endBytes[3] != '\n') {
        return NO;
    }
    
    return YES;
}

+ (NSDictionary<NSString *,EspHttpResponse *> *)getDictionaryWithDeviceResponses:(NSArray<EspHttpResponse *> *)responses {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (EspHttpResponse *response in responses) {
        NSString *mac = [response getHeaderValueForKey:EspHeaderNodeMac];
        if (mac != nil) {
            [dict setObject:response forKey:mac];
        }
    }
    
    return dict;
}

@end
