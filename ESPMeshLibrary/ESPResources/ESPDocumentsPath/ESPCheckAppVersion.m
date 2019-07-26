//
//  ESPCheckAppVersion.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/1/4.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import "ESPCheckAppVersion.h"
#import <UIKit/UIKit.h>

@interface ESPCheckAppVersion ()<UIAlertViewDelegate>

@property (nonatomic, strong) NSString *appId;

@end
@implementation ESPCheckAppVersion

+ (ESPCheckAppVersion *)sharedInstance
{
    static ESPCheckAppVersion *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instance = [[ESPCheckAppVersion alloc] init];
        
    });
    
    return instance;
}

- (ESPVersionStatus)checkAppVersion:(NSString *)appId
{
    NSURL *appUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?id=%@",appId]];
    NSString *appMsg = [NSString stringWithContentsOfURL:appUrl encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *appMsgDict = [self jsonStringToDictionary:appMsg];
    NSDictionary *appResultsDict = [appMsgDict[@"results"] lastObject];
    NSString *appStoreVersion = appResultsDict[@"version"];
    float newVersionFloat = [appStoreVersion floatValue];//新发布的版本号
    
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    float currentVersionFloat = [currentVersion floatValue];//使用中的版本号
    
    //当前版本小于App Store上的版本&用户未点击不再提示
    if (currentVersionFloat < newVersionFloat) {
        return ESPVersionAscending;
    }else if (currentVersionFloat == newVersionFloat) {
        return ESPVersionSame;
    }else{
        return ESPVersionDescending;
    }
    
}

- (NSDictionary *)checkAppVersionNumber:(NSString *)appId
{
    NSURL *appUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?id=%@",appId]];
    id appMsg = [NSString stringWithContentsOfURL:appUrl encoding:NSUTF8StringEncoding error:nil];
//    NSLog(@"%@",appMsg);
    NSDictionary *appMsgDict = [self jsonStringToDictionary:appMsg];
    NSDictionary *appResultsDict = [appMsgDict[@"results"] lastObject];
    
    return appResultsDict;
}

- (BOOL)appVersionUpdate {
    BOOL updateBool= [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/cn/app/id1420425921?mt=8"]];
    return updateBool;
}

- (NSDictionary *)jsonStringToDictionary:(NSString *)jsonStr
{
    if (jsonStr == nil)
    {
        return nil;
    }
    
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    if (error)
    {
        //NSLog(@"json格式string解析失败:%@",error);
        return nil;
    }
    
    return dict;
}

@end
