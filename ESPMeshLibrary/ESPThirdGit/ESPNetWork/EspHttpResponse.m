//
//  EspHttpResponse.m
//  Esp32Mesh
//
//  Created by AE on 2018/2/27.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspHttpResponse.h"
#import "EspCommonUtils.h"

@implementation EspHttpResponse

- (instancetype)init
{
    self = [super init];
    if (self) {
        headers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)getContentString {
    if ([EspCommonUtils isNull:self.content]) {
        return nil;
    } else {
        return [[NSString alloc] initWithData:self.content encoding:NSUTF8StringEncoding];
    }
}

- (id)getContentJSON {
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:self.content options:NSJSONReadingMutableContainers error:&error];
    if (!json || error) {
        return nil;
    } else {
        return json;
    }
}

- (void)setHeader:(NSString *)value forKey:(NSString *)key {
    [headers setObject:value forKey:key];
}

- (NSString *)getHeaderValueForKey:(NSString *)key {
    return [headers objectForKey:key];
}

@end
