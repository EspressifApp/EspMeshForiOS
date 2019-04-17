//
//  EspHttpUtils.h
//  Esp32Mesh
//
//  Created by AE on 2018/2/28.
//  Copyright © 2018年 AE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EspHttpResponse.h"
#import "EspHttpParams.h"

static NSString * const EspHttpHeaderContentLength = @"Content-Length";
static NSString * const EspHttpHeaderConentType = @"Content-Type";

static NSString * const EspHttpHeaderValueContentTypeJSON = @"application/json";

static NSString * const EspHttpMethodGet = @"GET";
static NSString * const EspHttpMethodPost = @"POST";

static const int EspHttpCodeOK = 200;
static const int EspHttpCodeBadRequest = 400;
static const int EspHttpCodeForbidden = 403;
static const int EspHttpCodeNotFound = 404;
static const int EspHttpCodeConflict = 409;

typedef void (^EspHtttpCallback)(EspHttpResponse *);

@interface EspHttpUtils : NSObject

//public static EspHttpResponse Get(String url, EspHttpParams params, EspHttpHeader... headers)
+ (EspHttpResponse *)getForUrl:(NSString *)url params:(EspHttpParams *)params headers:(NSDictionary *)headers;
+ (EspHttpResponse *)postForUrl:(NSString *)url content:(NSData *)content params:(EspHttpParams *)params headers:(NSDictionary *)headers;

+ (EspHttpResponse *)getResponseWithFixedLengthData:(NSData *)data;

@end
