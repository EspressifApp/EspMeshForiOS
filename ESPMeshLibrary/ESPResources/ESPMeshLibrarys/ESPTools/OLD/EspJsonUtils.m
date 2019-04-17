//
//  EspJsonUtils.m
//  Esp32Mesh
//
//  Created by AE on 2018/3/14.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspJsonUtils.h"
#import "EspCommonUtils.h"

@implementation EspJsonUtils

+ (NSData *)getDataWithDictionary:(NSDictionary *)dictionary {
    
    NSString* jsonStr=[self jsonFromObject:dictionary];
    NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    return data;
    
    //    NSError *error;
    //    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    //    if (error) {
    //        NSLog(@"%@", error);
    //        return nil;
    //    } else {
    //        return data;
    //    }
}
+ (NSDictionary *)getDictionaryWithData:(NSData *)data {
    //NSError *error;
    NSString * str  =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    return [self objectFromJsonString:str];
//    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
//
//
//    if (error) {
//        NSLog(@"%@", error);
//        return nil;
//    } else {
//        return dic;
//    }
}

+ (NSString *)getStringWithDictionary:(NSDictionary *)dictionary {
    NSData *data = [EspJsonUtils getDataWithDictionary:dictionary];
    if (!data) {
        return nil;
    } else {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
}

// 字典转json字符串方法
+ (id)objectFromJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

//JSON字符串转化为字典或数组
+(NSString *)jsonFromObject:(id)objdata
{
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:objdata options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString;
    
    if (!jsonData) {
        
        NSLog(@"jsonFromObject:%@",error);
        
    }else{
        
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    
    NSRange range = {0,jsonString.length};
    
    //去掉字符串中的空格
    
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    
    NSRange range2 = {0,mutStr.length};
    
    //去掉字符串中的换行符
    
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
    
}

@end
