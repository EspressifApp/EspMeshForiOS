//
//  ESPDocumentsPath.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/24.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "ESPDocumentsPath.h"

@implementation ESPDocumentsPath

// 获取Documents路径
- (NSString *)getDocumentsPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    return path;
}

// 创建文件夹@"iOSUpgradeFiles"
- (void)createDirectory:(NSString *)nameStr {
    NSString *documentsPath =[self getDocumentsPath];
    NSString *iOSDirectory = [documentsPath stringByAppendingPathComponent:nameStr];
    NSLog(@"%@",iOSDirectory);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:iOSDirectory isDirectory:&isDir];
    if (!(isDirExist && isDir)) {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:iOSDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        if (!bCreateDir) {
            NSLog(@"创建文件夹失败！");
        }
        NSLog(@"创建文件夹成功，文件路径%@",iOSDirectory);
    }
}

// 创建文件
- (void)createFile {
    NSString *documentsPath =[self getDocumentsPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *iOSPath = [documentsPath stringByAppendingPathComponent:@"iOS.txt"];
    BOOL isSuccess = [fileManager createFileAtPath:iOSPath contents:nil attributes:nil];
    if (isSuccess) {
        NSLog(@"success");
    } else {
        NSLog(@"fail");
    }
}

// 写入文件
- (void)writeFile {
    NSString *documentsPath =[self getDocumentsPath];
    NSString *iOSPath = [documentsPath stringByAppendingPathComponent:@"iOS.txt"];
    NSString *content = @"我要写数据啦";
    BOOL isSuccess = [content writeToFile:iOSPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    if (isSuccess) {
        NSLog(@"write success");
    } else {
        NSLog(@"write fail");
    }
}

// 读取文件
- (void)readFileContent {
    NSString *documentsPath =[self getDocumentsPath];
    NSString *lightbin = [documentsPath stringByAppendingPathComponent:@"iOSUpgradeFiles/light.bin"];
    NSString *content = [NSString stringWithContentsOfFile:lightbin encoding:NSUTF8StringEncoding error:nil];
//    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:lightbin]];
    NSLog(@"read success: %@",content);
}

// 判断文件是否存在
- (BOOL)isSxistAtPath:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:filePath];
    return isExist;
}

// 计算文件大小
- (unsigned long long)fileSizeAtPath:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:filePath];
    if (isExist) {
        unsigned long long fileSize = [[fileManager attributesOfItemAtPath:filePath error:nil] fileSize];
        return fileSize;
    } else {
        NSLog(@"file is not exist");
        return 0;
    }
}

// 计算整个文件夹中所有文件大小
- (unsigned long long)folderSizeAtPath:(NSString*)folderPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:folderPath];
    if (isExist) {
        NSEnumerator *childFileEnumerator = [[fileManager subpathsAtPath:folderPath] objectEnumerator];
        unsigned long long folderSize = 0;
        NSString *fileName = @"";
        while ((fileName = [childFileEnumerator nextObject]) != nil){
            NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
            folderSize += [self fileSizeAtPath:fileAbsolutePath];
        }
        return folderSize / (1024.0 * 1024.0);
    } else {
        NSLog(@"file is not exist");
        return 0;
    }
}

// 删除文件
- (void)deleteFile {
    NSString *documentsPath =[self getDocumentsPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *iOSPath = [documentsPath stringByAppendingPathComponent:@"iOS.txt"];
    BOOL isSuccess = [fileManager removeItemAtPath:iOSPath error:nil];
    if (isSuccess) {
        NSLog(@"delete success");
    }else{
        NSLog(@"delete fail");
    }
}

// 移动文件
- (void)moveFileName {
    NSString *documentsPath =[self getDocumentsPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"iOS.txt"];
    NSString *moveToPath = [documentsPath stringByAppendingPathComponent:@"iOS.txt"];
    BOOL isSuccess = [fileManager moveItemAtPath:filePath toPath:moveToPath error:nil];
    if (isSuccess) {
        NSLog(@"rename success");
    }else{
        NSLog(@"rename fail");
    }
}

// 重命名
- (void)renameFileName {
    //通过移动该文件对文件重命名
    NSString *documentsPath =[self getDocumentsPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"iOS.txt"];
    NSString *moveToPath = [documentsPath stringByAppendingPathComponent:@"rename.txt"];
    BOOL isSuccess = [fileManager moveItemAtPath:filePath toPath:moveToPath error:nil];
    if (isSuccess) {
        NSLog(@"rename success");
    }else{
        NSLog(@"rename fail");
    }
}

- (NSArray *)documentFileName {
    
    NSString *path = [self getDocumentsPath];
    NSString  *bundlePath = [path stringByAppendingPathComponent:@"iOSUpgradeFiles"];
    NSFileManager * fm = [NSFileManager defaultManager];
    NSArray* arr=[fm contentsOfDirectoryAtPath:bundlePath error:nil];
    NSMutableArray *allArr = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0; i < arr.count; i ++) {
        NSString *bin=[arr[i] componentsSeparatedByString:@"."].lastObject;
        if ([bin isEqualToString:[NSString stringWithFormat:@"bin"]]) {
            [allArr addObject:arr[i]];
        }
    }
    return allArr;
}

- (NSArray *)readFile:(NSString *)typeStr {
    NSArray* dataArr;
    if ([typeStr isEqualToString:@"wifi"]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"mac_org_list" ofType:@"txt"];
        NSString *UTF8txtString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
        dataArr=[UTF8txtString componentsSeparatedByString:@"\n"];
    }else {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"bt_org_list" ofType:@"txt"];
        NSString *UTF8txtString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
        dataArr = [UTF8txtString componentsSeparatedByString:@"\n"];
    }
//    NSLog(@"dataArr ====> %@",dataArr);
    return dataArr;
}

@end
