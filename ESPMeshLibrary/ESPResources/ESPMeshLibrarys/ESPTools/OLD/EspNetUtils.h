//
//  EspNetUtils.h
//  Esp32Mesh
//
//  Created by AE on 2018/4/19.
//  Copyright © 2018年 AE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EspNetUtils : NSObject

+ (nullable NSString *)getCurrentWiFiSsid;

+ (NSString *)getIPAddress:(BOOL)preferIPv4;

+ (NSDictionary *)getIPAddresses;
@end
