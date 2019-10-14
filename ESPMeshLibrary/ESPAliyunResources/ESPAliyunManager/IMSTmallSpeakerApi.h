//
//  IMSTmallSpeakerApi.h
//  ESPAliyunDemo
//
//  Created by fanbaoying on 2019/9/27.
//  Copyright © 2019 fby. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMSTmallSpeakerApi : NSObject

// 用户绑定淘宝Id 此处para = @{@"authCode":@"xxxx"}，其中xxxx为网页回调的code，具体查看登录成功后的回调处理步骤。
+ (void)bindTaobaoIdWithParams:(NSDictionary *)para
                    completion:(void (^)(NSError *error, NSDictionary *info))completion;

// 用户解绑淘宝Id 此处para = @{@"accountType":@"TAOBAO"}
+ (void)unbindTaobaoIdWithParams:(NSDictionary *)para
                      completion:(void (^)(NSError *error, NSDictionary *info))completion;

// 查询用户绑定的淘宝Id 此处para = @{@"accountType":@"TAOBAO"}
+ (void)getTaobaoIdWithParams:(NSDictionary *)para
                   completion:(void (^)(NSError *error, NSDictionary *info))completion;

@end

NS_ASSUME_NONNULL_END
