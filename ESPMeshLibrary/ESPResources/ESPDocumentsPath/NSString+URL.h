//
//  NSString+URL.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/3/18.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (URL)
/**
 *  URLEncode
 */
- (NSString *)URLEncodedString;

/**
 *  URLDecode
 */
-(NSString *)URLDecodedString;
@end

NS_ASSUME_NONNULL_END
