//
//  EspHttpParams.h
//  Esp32Mesh
//
//  Created by AE on 2018/2/27.
//  Copyright © 2018年 AE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EspHttpParams : NSObject

@property(nonatomic, assign) double timeout;
@property(nonatomic, assign) int tryCount;
@property(nonatomic, assign) BOOL requireResponse;

@end
