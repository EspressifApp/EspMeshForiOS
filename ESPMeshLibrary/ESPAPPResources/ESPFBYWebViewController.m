//
//  ESPFBYWebViewController.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/19.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "ESPFBYWebViewController.h"

#import "ESPFBYBLEHelper.h"
#import "ESPFBYBLECBPeripheral.h"

#import "ESPAliyunSDKUse.h"
#import "ESPAliyunSDKInit.h"
#import "ESPDataConversion.h"

#define FBYDeviceWidth ([UIScreen mainScreen].bounds.size.width)
#define FBYDeviceHeight ([UIScreen mainScreen].bounds.size.height)

#define StatusBar [UIApplication sharedApplication].statusBarFrame.size.height

@interface ESPFBYWebViewController ()
// 文本
@property (strong, nonatomic) UITextView *peripheralText;

@property(nonatomic,strong)ESPFBYBLEHelper *bleHelper;

@property(nonatomic,strong)ESPFBYBLECBPeripheral *BLECBPeripheral;

@end


@implementation ESPFBYWebViewController

{
    NSTimer* BLETimer;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.BLECBPeripheral = [ESPFBYBLECBPeripheral shared];
    self.bleHelper = [[ESPFBYBLEHelper alloc]init];
    [self.bleHelper initBle];
    
    ESPAliyunSDKInit *HandleToolInit = [[ESPAliyunSDKInit alloc]init];
    [HandleToolInit LongLinksHandleToolInit];
    
    [self showViewUI];
}

- (void)showViewUI {
    NSArray *bleArr = @[@"扫描设备",@"停止扫描",@"清空数据"];
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
    
    NSArray *bluetoothArr = @[@"蓝牙初始化",@"添加服务",@"开始广播"];
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
        [self showMessage:@"开始扫描"];
        [self.bleHelper startScan:^(EspDevice *device) {
            [self showMessage:[NSString stringWithFormat:@"发现设备，设备名：%@",device.name]];
        }];
    }else if (sender.tag == 6001) {
        [self showMessage:@"停止扫描"];
        [self.bleHelper stopScan];
    }else if (sender.tag == 6002) {
        self.peripheralText.text = @"";
        [self showMessage:@"清空设备"];
        [self.bleHelper disconnect];
    }
    
}

- (void)bluetoothBtn:(UIButton *)sender {
    if (sender.tag == 7000) {
        [self.BLECBPeripheral setup];
    }else if (sender.tag == 7001) {
        [self.BLECBPeripheral addSe];
    }else if (sender.tag == 7002) {
        [self.BLECBPeripheral adv];
    }
}

- (void)upgradesBtn:(UIButton *)sender {
    if (sender.tag == 8000) {
        [self aliyunLogin];
    }else if (sender.tag == 8001) {
        [self aliyunLogout];
    }else if (sender.tag == 8002) {
        [[ESPAliyunSDKUse sharedClient] getAliyunDeviceList:^(NSDictionary * _Nonnull resultdeviceDic) {
            NSLog(@"resultdeviceDic:%@",resultdeviceDic);
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
