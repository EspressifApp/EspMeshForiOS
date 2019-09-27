//
//  ESPFBYAliViewController.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/9/16.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import "ESPFBYAliViewController.h"

#define FBYDeviceWidth ([UIScreen mainScreen].bounds.size.width)
#define FBYDeviceHeight ([UIScreen mainScreen].bounds.size.height)
#define ValidDict(f) (f!=nil && [f isKindOfClass:[NSDictionary class]])
#define ValidArray(f) (f!=nil && [f isKindOfClass:[NSArray class]] && [f count]>0)

#define StatusBar [UIApplication sharedApplication].statusBarFrame.size.height

@interface ESPFBYAliViewController ()

// 文本
@property (strong, nonatomic) UITextView *peripheralText;

@property (strong, nonatomic) NSMutableArray *iotDeviceArr;

@end

@implementation ESPFBYAliViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    [self showViewUI];
}

- (void)showViewUI {
    NSArray *bleArr = @[@"设备详情",@"停止扫描",@"清空数据"];
    for (int i = 0; i < bleArr.count; i ++) {
        int count = FBYDeviceWidth*i/3;
        UIButton *scanBtn = [[UIButton alloc]initWithFrame:CGRectMake(count, FBYDeviceHeight-50, (FBYDeviceWidth-2)/3, 50)];
        scanBtn.backgroundColor = [UIColor whiteColor];
        [scanBtn setTitleColor:[UIColor lightGrayColor] forState:0];
        scanBtn.tag = 6000 + i;
        [scanBtn setTitle:bleArr[i] forState:0];
        [scanBtn addTarget:self action:@selector(scanBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:scanBtn];
    }
    
    NSArray *bluetoothArr = @[@"查询设备",@"升级设备",@"升级进度"];
    for (int i = 0; i < bluetoothArr.count; i ++) {
        int count = FBYDeviceWidth*i/3;
        UIButton *bluetoothBtn = [[UIButton alloc]initWithFrame:CGRectMake(count, FBYDeviceHeight-101, (FBYDeviceWidth-2)/3, 50)];
        bluetoothBtn.backgroundColor = [UIColor whiteColor];
        [bluetoothBtn setTitleColor:[UIColor lightGrayColor] forState:0];
        bluetoothBtn.tag = 7000 + i;
        [bluetoothBtn setTitle:bluetoothArr[i] forState:0];
        [bluetoothBtn addTarget:self action:@selector(bluetoothBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:bluetoothBtn];
    }
    
    NSArray *upgradesArr = @[@"登录",@"登出",@"设备列表"];
    for (int i = 0; i < upgradesArr.count; i ++) {
        int count = FBYDeviceWidth*i/3;
        UIButton *upgradesBtn = [[UIButton alloc]initWithFrame:CGRectMake(count, FBYDeviceHeight-152, (FBYDeviceWidth-2)/3, 50)];
        upgradesBtn.backgroundColor = [UIColor whiteColor];
        [upgradesBtn setTitleColor:[UIColor lightGrayColor] forState:0];
        upgradesBtn.tag = 8000 + i;
        [upgradesBtn setTitle:upgradesArr[i] forState:0];
        [upgradesBtn addTarget:self action:@selector(upgradesBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:upgradesBtn];
    }
    self.peripheralText = [[UITextView alloc]initWithFrame:CGRectMake(10, StatusBar+50, FBYDeviceWidth-20, FBYDeviceHeight-210-StatusBar)];
    [self.peripheralText setEditable:NO];
    [self.view addSubview:_peripheralText];
}

- (void)scanBtn:(UIButton *)sender {
    
    if (sender.tag == 6000) {
        [self showMessage:@"升级设备详情"];
        if (ValidArray(_iotDeviceArr)) {
            for (int i = 0; i < _iotDeviceArr.count; i ++) {
                [[ESPAliyunSDKUse sharedClient] queryProductsInfoWithIotId:_iotDeviceArr[i] completionHandler:^(NSDictionary * _Nonnull queryProductsInfoResult) {
                    NSLog(@"升级设备详情：%@", queryProductsInfoResult);
                    [self showMessage:[NSString stringWithFormat:@"升级设备详情：%@", queryProductsInfoResult]];
                }];
            }
        }
    }else if (sender.tag == 6001) {
        [self showMessage:@"停止扫描"];
        
    }else if (sender.tag == 6002) {
        self.peripheralText.text = @"";
        [self showMessage:@"清空设备"];
    }
    
}

- (void)bluetoothBtn:(UIButton *)sender {
    if (sender.tag == 7000) {
        [self showMessage:@"待升级设备列表"];
        self.iotDeviceArr = [NSMutableArray arrayWithCapacity:0];
        [[ESPAliyunSDKUse sharedClient] loadOTAUpgradeDeviceList:^(NSDictionary * _Nonnull deviceListResult) {
            NSLog(@"待升级设备列表：%@", deviceListResult);
            [self showMessage:[NSString stringWithFormat:@"待升级设备列表：%@", deviceListResult]];
            if (ValidDict(deviceListResult)) {
                NSArray *dataArr = [deviceListResult objectForKey:@"data"];
                for (int i = 0; i < dataArr.count; i ++) {
                    if ([[dataArr[i] objectForKey:@"status"] intValue] == 1) {
                        [self.iotDeviceArr addObject:[dataArr[i] objectForKey:@"iotId"]];
                    }
                }
            }
        }];
    }else if (sender.tag == 7001) {
        [self showMessage:@"设备升级结果"];
        if (ValidArray(_iotDeviceArr)) {
            [[ESPAliyunSDKUse sharedClient] upgradeWifiDeviceFirmware:_iotDeviceArr completionHandler:^(NSDictionary * _Nonnull upgradeResult) {
                NSLog(@"设备升级结果：%@", upgradeResult);
                [self showMessage:[NSString stringWithFormat:@"设备升级结果：%@", upgradeResult]];
            }];
        }
    }else if (sender.tag == 7002) {
        [self showMessage:@"设备升级进度"];
        if (ValidArray(_iotDeviceArr)) {
            for (int i = 0; i < _iotDeviceArr.count; i ++) {
                [[ESPAliyunSDKUse sharedClient] loadOTAFirmwareDetailAndUpgradeStatus:_iotDeviceArr[i] completionHandler:^(NSDictionary * _Nonnull deviceStatusResult) {
                    NSLog(@"设备升级进度：%@", deviceStatusResult);
                    NSString* json=[ESPDataConversion jsonConfigureFromObject:deviceStatusResult];
                    NSLog(@"设备升级进度：%@", json);
                    [self showMessage:[NSString stringWithFormat:@"设备升级进度：%@", deviceStatusResult]];
                }];
            }
        }
    }
}

- (void)upgradesBtn:(UIButton *)sender {
    if (sender.tag == 8000) {
        [self showMessage:@"登录"];
        [self aliyunLogin];
    }else if (sender.tag == 8001) {
        [self showMessage:@"登出"];
        [self aliyunLogout];
    }else if (sender.tag == 8002) {
        [[ESPAliyunSDKUse sharedClient] getAliyunDeviceList:^(NSDictionary * _Nonnull resultdeviceDic) {
            NSLog(@"resultdeviceDic:%@",resultdeviceDic);
            [self showMessage:[NSString stringWithFormat:@"已绑定设备列表：%@", resultdeviceDic]];
            NSArray *arr = [resultdeviceDic objectForKey:@"date"];
            for (int i = 0; i < arr.count; i ++) {
                NSLog(@"productName:%@",[arr[i] objectForKey:@"productName"]);
            }
            
        }];
    }
}

- (void)aliyunLogin {
    [[ESPAliyunSDKUse sharedClient] aliyunPresentLogin:self andSuccess:^(ALBBOpenAccountUser * _Nonnull dic) {
        //        NSString* paramjson=[ESPDataConversion jsonConfigureFromObject:dic];
        NSString* paramjson = [NSString stringWithFormat:@"%@",dic];
        NSLog(@"dic --> %@, %@",dic, paramjson);
        [self showMessage:[NSString stringWithFormat:@"登录成功后的信息:%@",dic]];
    } andFailure:^(NSString * _Nonnull errorMsg) {
        NSLog(@"errorMsg --> %@",errorMsg);
        [self showMessage:errorMsg];
    }];
}

- (void)aliyunLogout {
    if ([[ESPAliyunSDKUse sharedClient] isAliyunLogin]) {
        [[ESPAliyunSDKUse sharedClient] aliyunLogout];
        [self showMessage:@"已退出登录"];
    }else {
        [self showMessage:@"用户未登录"];
    }
}


- (void)showMessage:(NSString *)message
{
    self.peripheralText.text = [self.peripheralText.text stringByAppendingFormat:@"%@\n",message];
    [self.peripheralText scrollRectToVisible:CGRectMake(0, self.peripheralText.contentSize.height -15, self.peripheralText.contentSize.width, 10) animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
