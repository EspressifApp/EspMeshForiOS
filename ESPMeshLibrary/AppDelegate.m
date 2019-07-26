//
//  AppDelegate.m
//  ESPMeshLibrary
//
//  Created by zhaobing on 2018/6/20.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "AppDelegate.h"
#import "IQKeyboardManager.h"
#import "ESPNewWebViewController.h"
#import "ESPFBYWebViewController.h"


@interface AppDelegate ()<UIApplicationDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //不能删，否则，后面回掉的蓝牙状态不准确
    NSLog(@"初始化蓝牙状态：%ld", (long)[[BabyBluetooth shareBabyBluetooth] centralManager].state);
    [IQKeyboardManager sharedManager].enable = true;
    
    //加载方法重构页面
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:[ESPNewWebViewController new]];
    self.window.rootViewController = navigationController;
    navigationController.navigationBarHidden = YES;
    self.window.backgroundColor = [UIColor colorWithRed:62/255.0 green:194/255.0 blue:252/255.0 alpha:1];
    [self.window makeKeyAndVisible];
    
    //加载测试页面
//    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:[ESPFBYWebViewController new]];
//    self.window.rootViewController = navigationController;
//    [self.window makeKeyAndVisible];
 
    return YES;
}

//- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window
//{
//
//    NSString *deviceType = [UIDevice currentDevice].model;
//    if([deviceType isEqualToString:@"iPhone"]) {
//        return UIInterfaceOrientationMaskPortrait;
//    }else{
//        return UIInterfaceOrientationMaskLandscapeLeft;
//    }
//
//}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
