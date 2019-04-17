//
//  ESPHomeService.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/21.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "ESPHomeService.h"


@implementation ESPHomeService

- (void)searchMeshNodeMac:(NSString *)meshNodeMac andWithFirmwareUrl:(NSString *)firmwareUrl andWithDic:(NSDictionary *)Alldic andUrl:(NSString *)url andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(int))failure{
    
//    NSString *urlstr= [NSString stringWithFormat:@"%@%@",DBAllURL,url];
    //1.创建ADHTTPSESSIONMANGER对象
    AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
    
    //2.设置该对象返回类型
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"Mesh-Node-Mac" forHTTPHeaderField:meshNodeMac];
    [manager.requestSerializer setValue:@"Firmware-Url" forHTTPHeaderField:@"https://raw.githubusercontent.com/XuXiangJun/test/master/light.bin"];
    
    [manager POST:url parameters:Alldic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *dic = responseObject;
        
        success(dic);
        
    }failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"----返回错误");
        NSLog(@"%@",error);
        
    }];
    
}

+ (NSURLSessionTask *)meshNodeMac:(NSString *)meshNodeMac andWithFirmwareUrl:(NSString *)firmwareUrl withIPUrl:(NSString *)ipUrl andSuccess:(void (^)(NSDictionary * _Nonnull))success andFailure:(void (^)(int))failure {
    
    NSString *urlstr= [NSString stringWithFormat:@"http://%@:80/ota/url",ipUrl];
    //1.创建ADHTTPSESSIONMANGER对象
    AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
    
    // 设置超时时间
    [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    manager.requestSerializer.timeoutInterval = 580;
    [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    //2.设置该对象返回类型
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:meshNodeMac forHTTPHeaderField:@"Mesh-Node-Mac"];
    [manager.requestSerializer setValue:firmwareUrl forHTTPHeaderField:@"Firmware-Url"];
    
    NSURLSessionTask *sessionTask = [manager POST:urlstr parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        NSDictionary *allHeaders = response.allHeaderFields;
        NSLog(@"allHeaders--->%@",allHeaders);
        NSLog(@"responseObject--->%@",responseObject);
        NSDictionary *dic = responseObject;
        
        success(dic);
        
    }failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error--->%@",error);
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        NSDictionary *allHeaders = response.allHeaderFields;
        NSLog(@"allHeaders--->%@",allHeaders);
//        success(dic);
    }];
    return sessionTask;
}

+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL fileDir:(NSString *)fileDir progress:(void (^)(NSProgress * _Nonnull))progress success:(void (^)(NSString * _Nonnull))success andFailure:(void (^)(int))failure {
    
    /* 下载地址 */
    NSURL *url = [NSURL URLWithString:URL];
    /* 下载路径 */
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/iOSUpgradeFiles"];
    NSString *filePath = [path stringByAppendingPathComponent:url.lastPathComponent];
    fileDir = filePath;
    /* 创建网络下载对象 */
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    __block NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:fileDir];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if(failure && error) {failure((int)error) ; return ;};
        success ? success(filePath.absoluteString /** NSURL->NSString*/) : nil;
    }];
    [downloadTask resume];
    
    return downloadTask;
}

+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)URL parameters:(id)parameters names:(NSArray<NSString *> *)names filePaths:(NSArray<NSString *> *)filePaths progress:(void (^)(NSProgress * _Nonnull))progress success:(void (^)(NSString * _Nonnull))success andFailure:(void (^)(int))failure {
    
    NSString *urlstr= [NSString stringWithFormat:@"http://%@:80/ota/firmware",URL];
    /* 创建网络下载对象 */
    AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"multipart/form-data", @"application/json", @"text/html", @"image/jpeg", @"image/png", @"application/octet-stream", @"text/json", @"text/xml", nil];
    manager.requestSerializer.timeoutInterval = 60.0;
    [manager.requestSerializer setValue:parameters[@"meshNodeMac"] forHTTPHeaderField:@"Mesh-Node-Mac"];
    [manager.requestSerializer setValue:parameters[@"firmwareName"] forHTTPHeaderField:@"Firmware-Name"];
    
    NSURLSessionTask *sessionTask = [manager POST:urlstr parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (NSUInteger i = 0; i < filePaths.count; i++) {
            NSString *name = names[i];
            NSString *filePath = filePaths[i];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
            
            [formData appendPartWithFileData:data name:@"light.bin" fileName:name mimeType:@"application/octet-stream"];
            
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success ? success(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure ? failure((int)error) : nil;
    }];
    return sessionTask;
}

@end
