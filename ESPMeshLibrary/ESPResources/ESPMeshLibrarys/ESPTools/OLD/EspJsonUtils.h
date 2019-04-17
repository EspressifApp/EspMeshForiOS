//
//  EspJsonUtils.h
//  Esp32Mesh
//
//  Created by AE on 2018/3/14.
//  Copyright © 2018年 AE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EspHttpResponse.h"

@interface EspJsonUtils : NSObject

+ (NSData *)getDataWithDictionary:(NSDictionary *)dictionary;
+ (NSDictionary *)getDictionaryWithData:(NSData *)data ;
+ (NSString *)getStringWithDictionary:(NSDictionary *)dictionary;

+ (id)objectFromJsonString:(NSString *)jsonString;
+(NSString *)jsonFromObject:(id)objdata;

@end
