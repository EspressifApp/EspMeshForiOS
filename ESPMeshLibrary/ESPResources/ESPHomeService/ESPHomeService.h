//
//  ESPHomeService.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/21.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

NS_ASSUME_NONNULL_BEGIN

@interface ESPHomeService : NSObject

- (void)searchMeshNodeMac:(NSString *)meshNodeMac andWithFirmwareUrl:(NSString *)firmwareUrl andWithDic:(NSDictionary *)Alldic andUrl:(NSString *)url andSuccess:(void(^)(NSDictionary *dic))success andFailure:(void(^)(int fail))failure;
/**
 *
 *  @param meshNodeMac      mac地址
 *  @param firmwareUrl  升级文件下载地址
 *  @param ipUrl 网络请求ip地址
 *  @param success  下载成功的回调(回调参数filePath:文件的路径)
 *  @param failure  下载失败的回调
 *
 */
+ (NSURLSessionTask *)meshNodeMac:(NSString *)meshNodeMac
               andWithFirmwareUrl:(NSString *)firmwareUrl
                        withIPUrl:(NSString *)ipUrl
                       andSuccess:(void(^)(NSDictionary *dic))success
                       andFailure:(void(^)(int fail))failure;
/**
 *
 *  @param URL      请求地址
 *  @param fileDir  文件存储目录(默认存储目录为Download)
 *  @param progress 文件下载的进度信息
 *  @param success  下载成功的回调(回调参数filePath:文件的路径)
 *  @param failure  下载失败的回调
 *
 */
+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL
                              fileDir:(NSString *)fileDir
                             progress:(void(^)(NSProgress *downloadProgress))progress
                              success:(void(^)(NSString *success))success
                           andFailure:(void(^)(int fail))failure;

/**
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param names       文件对应服务器上的字段
 *  @param filePaths   文件本地的沙盒路径
 *  @param progress   上传进度信息
 *  @param success    请求成功的回调
 *  @param failure    请求失败的回调
 *
 */
+ (__kindof NSURLSessionTask *)uploadFileWithURL:(NSString *)URL
                                      parameters:(id)parameters
                                           names:(NSArray<NSString *> *)names
                                       filePaths:(NSArray<NSString *> *)filePaths
                                        progress:(void(^)(NSProgress *uploadProgress))progress
                                         success:(void(^)(NSString *success))success
                                      andFailure:(void(^)(int fail))failure;

@end

NS_ASSUME_NONNULL_END
