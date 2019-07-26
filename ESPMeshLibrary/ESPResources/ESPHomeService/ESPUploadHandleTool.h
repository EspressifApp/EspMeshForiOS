//
//  ESPUploadHandleTool.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/26.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESPUploadHandleTool : NSObject
typedef void(^ProgressBackBlock)(float Progress);
/**
 上传进度
 */
@property(assign,nonatomic)ProgressBackBlock Progress;

- (void)sendSessionInit;
/**
 单例
 @return 单例
 */
+ (instancetype)shareInstance;

/*
*  @param URL        请求地址
*  @param parameters 请求参数
*  @param names       文件对应服务器上的字段
*  @param filePaths   文件本地的沙盒路径
*  @param progress   上传进度信息
*  @param success    请求成功的回调
*  @param failure    请求失败的回调
*
*/
- (__kindof NSURLSessionTask *)uploadFileWithURL:(NSString *)URL
                                      parameters:(id)parameters
                                           names:(NSArray<NSString *> *)names
                                       filePaths:(NSArray<NSString *> *)filePaths
                                        progress:(ProgressBackBlock)progress
                                         success:(void(^)(NSDictionary *success))success
                                      andFailure:(void(^)(int fail))failure;

/**
 *
 *  @param ipUrl  网络请求ip地址
 *  @param requestHeader  请求头
 *  @param bodyContent  请求内容
 *  @param success  成功的回调
 *  @param failure  失败的回调
 *
 */
- (NSURLSessionTask *)requestWithIpUrl:(NSString *)ipUrl
                       withRequestHeader:(NSDictionary *)requestHeader
                       withBodyContent:(NSDictionary *)bodyContent
                            andSuccess:(void(^)(NSArray *resultArr))success
                            andFailure:(void(^)(int fail))failure;

/**
 *
 *  @param meshNodeMac      mac地址
 *  @param firmwareUrl  升级文件下载地址
 *  @param ipUrl 网络请求ip地址
 *  @param success  成功的回调
 *  @param failure  失败的回调
 *
 */
- (NSURLSessionTask *)meshNodeMac:(NSString *)meshNodeMac
               andWithFirmwareUrl:(NSString *)firmwareUrl
                        withIPUrl:(NSString *)ipUrl
                       andSuccess:(void(^)(NSDictionary *dic))success
                       andFailure:(void(^)(int fail))failure;

/**
 *
 *  @param ipUrl 网络请求ip地址
 *  @param success  成功的回调
 *  @param failure  失败的回调
 *
 */
- (NSURLSessionTask *)stopOTA:(NSString *)ipUrl
                   andSuccess:(void(^)(NSDictionary *dic))success
                   andFailure:(void(^)(int fail))failure;

/**
 *
 *  @param ipUrl 网络请求ip地址
 *  @param deviceMacs 请求header参数
 *  @param success  下载成功的回调
 *  @param failure  下载失败的回调
 *
 */
- (NSURLSessionTask *)getSnifferInfo:(NSString *)ipUrl
                    withDeviceMacs:(NSString *)deviceMacs
                   andSuccess:(void(^)(NSArray *dic))success
                   andFailure:(void(^)(int fail))failure;

@end

NS_ASSUME_NONNULL_END
