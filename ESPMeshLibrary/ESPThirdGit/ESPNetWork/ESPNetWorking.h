//
//  ESPNetWorking.h
//  ESPMeshLibrary
//
//  Created by zhaobing on 2018/6/21.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EspDevice.h"
@interface ESPNetWorking : NSObject
typedef void (^NetWorkCallBack)(NSString* msg,NSDictionary*data);
+ (void) httpRequest:(NSString *)urlStr method:(NSString *)method body:(NSDictionary *)body headers:(NSDictionary *)headers timeOut:(NSTimeInterval)timeOut callback:(nullable void (^)(NSString *msg, NSDictionary *data))callback;
+ (NSMutableArray*)getMeshInfoFromHost:(EspDevice *)device;
+ (NSString *)getLocalUrlForProtocol:(NSString *)protocol host:(NSString *)host port:(NSString *)port file:(NSString *)file;
+(void)requestOTAStatus:(NSArray<EspDevice *> *)devices binPath:(NSString *)binPath callback:(NetWorkCallBack)callback;
@end
