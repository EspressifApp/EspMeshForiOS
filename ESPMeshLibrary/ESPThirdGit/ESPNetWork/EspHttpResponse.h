//
//  EspHttpResponse.h
//  Esp32Mesh
//
//  Created by AE on 2018/2/27.
//  Copyright © 2018年 AE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EspHttpResponse : NSObject {
    @private
    NSMutableDictionary *headers;
}

@property(nonatomic, assign) int code;
@property(nonatomic, strong) NSString *message;
@property(nonatomic, copy) NSData *content;

- (NSString *)getContentString;
- (id)getContentJSON;
- (void)setHeader:(NSString *)value forKey:(NSString *)key;
- (NSString *)getHeaderValueForKey:(NSString *)key;

@end
