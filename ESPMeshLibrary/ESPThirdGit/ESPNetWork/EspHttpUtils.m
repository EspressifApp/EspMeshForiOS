//
//  EspHttpUtils.m
//  Esp32Mesh
//
//  Created by AE on 2018/2/28.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspHttpUtils.h"
#import "EspCommonUtils.h"
#import "EspTextUtil.h"
#import "EspBlockingQueue.h"
#import "ESPDataConversion.h"

static const NSTimeInterval TIMEOUT = 5;

@implementation EspHttpUtils

+ (EspHttpResponse *)getForUrl:(NSString *)url params:(EspHttpParams *)params headers:(NSDictionary *)headers {
    return [EspHttpUtils executForUrl:url method:EspHttpMethodGet content:nil params:params headers:headers];
}

+ (EspHttpResponse *)postForUrl:(NSString *)url content:(NSData *)content params:(EspHttpParams *)params headers:(NSDictionary *)headers {
    return [EspHttpUtils executForUrl:url method:EspHttpMethodPost content:content params:params headers:headers];
}

+ (EspHttpResponse *) executForUrl:(NSString *)urlStr method:(NSString *)method content:(NSData *)content params:(EspHttpParams *)params headers:(NSDictionary *)headers {
    __block EspBlockingQueue *queue = [[EspBlockingQueue alloc] init];
    __block EspHttpResponse *nilResp = [[EspHttpResponse alloc] init];
    
    // Create request
    NSLog(@"EspHttpUtil request url = %@", urlStr);
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSTimeInterval timeout = TIMEOUT;
    if (![EspCommonUtils isNull:params]) {
        if (params.timeout > 0) {
            timeout = params.timeout;
        }
    }
    [request setTimeoutInterval:timeout];
    [request setHTTPMethod:method];
    [request setValue:@"close" forHTTPHeaderField:@"Connection"];
    if (![EspCommonUtils isNull:headers]) {
        [request setAllHTTPHeaderFields:headers];
    }

    if (![EspCommonUtils isNull:content]) {
        [request setHTTPBody:content];
        
        NSString *contentStr = [[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding];
        NSLog(@"contentStr--->%@", contentStr);
    }
    
    // Execute task
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        EspHttpResponse *result = nil;
        if (!error) {
            result = [[EspHttpResponse alloc] init];
            
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            result.code = (int)httpResp.statusCode;
            NSLog(@"http response = %ld", (long)httpResp.statusCode);
            
            [ESPDataConversion fby_saveNSUserDefaults:@"200" withKey:@"httpResponse"];
            NSDictionary *headers = [httpResp allHeaderFields];
            for(NSString *key in headers) {
                NSString *val = headers[key];
                [result setHeader:val forKey:key];
                //NSLog(@"%@: %@", key, val);
            }
            
            result.content = data;
//            NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else {
            [ESPDataConversion fby_saveNSUserDefaults:@"400" withKey:@"httpResponse"];
            NSLog(@"http response error msg::::::::: %@", error);
        }
        [queue enqueue:result == nil ? nilResp : result];
    }];
    [task resume];
    EspHttpResponse *response = queue.dequeue;
    return response == nilResp ? nil : response;
}

+ (EspHttpResponse *)getResponseWithFixedLengthData:(NSData *)data {
    if ([EspCommonUtils isNull:data] || [data length] == 0) {
        return nil;
    }
    
    EspHttpResponse *result = [[EspHttpResponse alloc] init];
    
    Byte *bytes = (Byte *)[data bytes];
    NSMutableData *headerData = [NSMutableData data];
    NSMutableData *contentData = [NSMutableData data];
    BOOL readContent = NO;
    
    for (long index = 0; index < [data length]; index++) {
        Byte bArray[1] = { bytes[index] };
        if (!readContent) {
            [headerData appendBytes:bArray length:1];
            if ([EspHttpUtils headEnd:headerData]) {
                readContent = YES;
            }
        } else {
            [contentData appendBytes:bArray length:1];
        }
    }
    
    NSString *headStr = [[NSString alloc] initWithData:headerData encoding:NSUTF8StringEncoding];
    NSArray *headers = [headStr componentsSeparatedByString:@"\r\n"];
    if ([headers count] <= 0) {
        NSLog(@"No status header");
        return nil;
    }
    
    NSString *statusHeader = headers[0];
    NSArray *statusValues = [statusHeader componentsSeparatedByString:@" "];
    if ([statusValues count] < 3) {
        NSLog(@"invalid status header: %@", statusHeader);
        return nil;
    } else if (![[statusValues[0] uppercaseString] hasPrefix:@"HTTP"]) {
        NSLog(@"invalid status protocol: %@", statusHeader);
        return nil;
    } else {
        int statusCode = [statusValues[1] intValue];
        NSMutableString *statusMessage = [NSMutableString string];
        for (long statusIndex = 2; statusIndex < [statusValues count]; statusIndex++) {
            [statusMessage appendString:statusValues[statusIndex]];
            if (statusIndex < [statusValues count] - 1) {
                [statusMessage appendString:@" "];
            }
        }
        
        result.code = statusCode;
        result.message = statusMessage;
    }
    
    for (long i = 1; i < [headers count]; i++) {
        NSString *headerStr = headers[i];
        if ([EspTextUtil isEmpty:headerStr]) {
            continue;
        }
        NSRange range = [headerStr rangeOfString:@": "];
        if (range.location == NSNotFound) {
            NSLog(@"invalid header: %@", headerStr);
            return nil;
        }
        
        NSString *name = [headerStr substringToIndex:range.location];
        NSString *value = [headerStr substringFromIndex:(range.location + 2)];
        [result setHeader:value forKey:name];
    }
    
    if ([contentData length] > 0) {
        result.content = contentData;
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

@end
