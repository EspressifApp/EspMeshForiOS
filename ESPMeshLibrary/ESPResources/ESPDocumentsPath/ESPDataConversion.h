//
//  ESPDataConversion.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/1/4.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESPDataConversion : NSObject

//JSON字符串转化为对象
+ (id)objectFromJsonString:(NSString *)jsonString;
//字典转json字符串方法
+ (NSString *)jsonFromObject:(id)objdata;
//字典转json字符串方法jsonConfigureFromObject
+ (NSString *)jsonConfigureFromObject:(id)objdata;
//18位随机字符串
+ (NSString *)getRandomStringWithLength;
//16位随机字符串
+ (NSString *)getRandomAESKey;
//characters格式转换
+ (NSMutableArray*)getJSCharacters:(NSMutableArray*)oldCharas;
/**
 *  keychain存
 *
 *  @param key   要存的对象的key值
 *  @param value 要保存的value值
 *  @return 保存结果
 */
+ (BOOL)fby_saveNSUserDefaults:(id)value withKey:(NSString *)key;
/**
 *  keychain取
 *
 *  @param key 对象的key值
 *
 *  @return 获取的对象
 */

+ (id)fby_getNSUserDefaults:(NSString *)key;

//多个mac地址分类获取对应本地存储的IP地址
+ (NSDictionary *)deviceRequestIpWithMac:(NSArray *)macArr;
//单个mac地址分类获取对应本地存储的IP地址
+ (NSString *)deviceRequestIp:(NSString *)macStr;

@end

NS_ASSUME_NONNULL_END
