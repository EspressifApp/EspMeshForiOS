//
//  EspActionDevice.h
//  Esp32Mesh
//
//  Created by AE on 2018/2/28.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspAction.h"

static NSString * const EspKeyMac = @"mac";
static NSString * const EspKeyRequest = @"request";
static NSString * const EspKeyStatusCode = @"status_code";
static NSString * const EspKeyRequireResp = @"require_resp";
static NSString * const EspKeyDelay = @"delay";

static const int EspStatusCodeSuc = 0;

static NSString * const EspHeaderMeshLayer = @"Mesh-Layer";
static NSString * const EspHeaderNodeNum = @"Mesh-Node-Num";
static NSString * const EspHeaderNodeMac = @"Mesh-Node-Mac";
static NSString * const EspHeaderParentMac = @"Mesh-Parent-Mac";
static NSString * const EspHeaderMeshId = @"Mesh-Id";

@interface EspActionDevice : EspAction

@end
