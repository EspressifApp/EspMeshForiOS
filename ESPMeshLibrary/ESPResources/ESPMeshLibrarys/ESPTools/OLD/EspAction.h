//
//  EspAction.h
//  Esp32Mesh
//
//  Created by AE on 2018/2/28.
//  Copyright © 2018年 AE. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const EspKeyStatus = @"status";
static NSString * const EspKeyID = @"id";
static NSString * const EspKeyToken = @"token";
static NSString * const EspKeyKey = @"key";
static NSString * const EspKeyAuth = @"Authorization";
static NSString * const EspKeyVersion = @"version";
static NSString * const EspKeyProtocolVersion = @"protocol_version";
static NSString * const EspKeyIdfVersion = @"idf_version";
static NSString * const EspKeyMdfVersion = @"mdf_version";
static NSString * const EspKeyMlinkVersion = @"mlink_version";

@interface EspAction : NSObject

@end
