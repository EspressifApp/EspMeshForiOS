//
//  EspRomQueryResult.h
//  Esp32Mesh
//
//  Created by AE on 2018/4/24.
//  Copyright © 2018年 AE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EspRomQueryResult : NSObject

@property(nonatomic, strong) NSString *version;
@property(nonatomic, strong, readonly) NSMutableArray *fileNames;

- (void)addFileName:(NSString *)name;
- (void)removeFileName:(NSString *)name;

@end
