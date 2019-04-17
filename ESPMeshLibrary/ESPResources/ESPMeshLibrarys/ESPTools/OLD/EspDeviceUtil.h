//
//  DeviceUtil.h
//  Esp32Mesh
//
//  Created by AE on 2018/2/23.
//  Copyright © 2018年 AE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EspConstants.h"
#import "EspDevice.h"
#import "EspHttpParams.h"
#import "EspHttpResponse.h"

static NSString * const EspHeaderNoResponse = @"root-response";

@interface EspDeviceUtil : NSObject

+ (NSString *)getLocalUrlForProtocol:(NSString*)protocol host:(NSString *)host port:(int)port file:(NSString *)file;

+ (EspHttpResponse *)httpLocalRequestForDevice:(EspDevice *)device content:(NSData *)content params:(EspHttpParams *)params headers:(NSMutableDictionary *)headers;
+ (EspHttpResponse *)httpLocalRequestForProtocol:(NSString *)protocol host:(NSString *)host port:(int)port deviceMac:(NSString *)mac content:(NSData *)content params:(EspHttpParams *)params headers:(NSMutableDictionary *)headers;

+ (NSArray<EspHttpResponse *> *)httpLocalMulticastRequestForDevices:(NSArray<EspDevice *> *)devices content:(NSData *)content params:(EspHttpParams *)params headers:(NSMutableDictionary *)headers multithread:(BOOL)multithread;
+ (NSArray<EspHttpResponse *> *)httpLocalMulticastRequestForProtocol:(NSString *)protocol host:(NSString *)host port:(int)port deviceMacs:(NSArray<NSString *> *)macs content:(NSData *)content params:(EspHttpParams *)params headers:(NSMutableDictionary *)headers multithread:(BOOL)multithread;

+ (NSDictionary<NSString *, EspHttpResponse *> *)getDictionaryWithDeviceResponses:(NSArray<EspHttpResponse *> *)responses;

+ (NSArray<EspHttpResponse *> *)getChunkedResponseListForData:(NSData *)data;
@end
