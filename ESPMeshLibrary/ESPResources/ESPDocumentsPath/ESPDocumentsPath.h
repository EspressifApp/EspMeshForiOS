//
//  ESPDocumentsPath.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/24.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESPDocumentsPath : NSObject

// 获取Documents路径
- (NSString *)getDocumentsPath;

// 创建文件夹
- (void)createDirectory:(NSString *)nameStr;

// 创建文件
- (void)createFile;

// 写入文件
- (void)writeFile;

// 读取文件
- (void)readFileContent;

// 判断文件是否存在
- (BOOL)isSxistAtPath:(NSString *)filePath;

// 计算文件大小
- (unsigned long long)fileSizeAtPath:(NSString *)filePath;

// 计算整个文件夹中所有文件大小
- (unsigned long long)folderSizeAtPath:(NSString*)folderPath;

// 删除文件
- (void)deleteFile;

// 移动文件
- (void)moveFileName;

// 重命名
- (void)renameFileName;

- (NSArray *)documentFileName;

// 读取指定文件夹
- (NSArray *)readFile:(NSString *)typeStr;

@end

NS_ASSUME_NONNULL_END
