//
//  ESPFBYWebViewController.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/19.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "ESPFBYWebViewController.h"

#import "ESPFBYBLEHelper.h"
#import "ESPDocumentsPath.h"
#import "ESPHomeService.h"
#import "ESPUploadHandleTool.h"
#import "ESPFBYBLECBPeripheral.h"

#define FBYDeviceWidth ([UIScreen mainScreen].bounds.size.width)
#define FBYDeviceHeight ([UIScreen mainScreen].bounds.size.height)

@interface ESPFBYWebViewController ()
// 文本
@property (strong, nonatomic) UITextView *peripheralText;

@property(nonatomic,strong)ESPFBYBLEHelper *bleHelper;

@property(nonatomic,strong)ESPFBYBLECBPeripheral *BLECBPeripheral;

@end


@implementation ESPFBYWebViewController

{
    ESPDocumentsPath *espDocumentPath;
    ESPUploadHandleTool *espUploadHandleTool;
    NSTimer* BLETimer;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.BLECBPeripheral = [ESPFBYBLECBPeripheral shared];
    self.bleHelper = [[ESPFBYBLEHelper alloc]init];
    [self.bleHelper initBle];
    
    espDocumentPath = [[ESPDocumentsPath alloc]init];
    espUploadHandleTool = [[ESPUploadHandleTool alloc]init];
    
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
    
    NSArray *upgradesArr = @[@"新建文件夹",@"下载文件",@"上传文件"];
    for (int i = 0; i < upgradesArr.count; i ++) {
        int count = FBYDeviceWidth*i/3;
        UIButton *upgradesBtn = [[UIButton alloc]initWithFrame:CGRectMake(count, FBYDeviceHeight-101, (FBYDeviceWidth-2)/3, 50)];
        upgradesBtn.backgroundColor = [UIColor whiteColor];
        [upgradesBtn setTitleColor:[UIColor lightGrayColor] forState:0];
        upgradesBtn.tag = 7000 + i;
        [upgradesBtn setTitle:upgradesArr[i] forState:0];
        [upgradesBtn addTarget:self action:@selector(upgradesBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:upgradesBtn];
    }
    
    NSArray *bluetoothArr = @[@"初始化",@"添加服务",@"开始广播"];
    for (int i = 0; i < bluetoothArr.count; i ++) {
        int count = FBYDeviceWidth*i/3;
        UIButton *bluetoothBtn = [[UIButton alloc]initWithFrame:CGRectMake(count, FBYDeviceHeight-152, (FBYDeviceWidth-2)/3, 50)];
        bluetoothBtn.backgroundColor = [UIColor whiteColor];
        [bluetoothBtn setTitleColor:[UIColor lightGrayColor] forState:0];
        bluetoothBtn.tag = 8000 + i;
        [bluetoothBtn setTitle:bluetoothArr[i] forState:0];
        [bluetoothBtn addTarget:self action:@selector(bluetoothBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:bluetoothBtn];
    }
    
    self.peripheralText = [[UITextView alloc]initWithFrame:CGRectMake(10, 64, FBYDeviceWidth-20, FBYDeviceHeight-220)];
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

- (void)upgradesBtn:(UIButton *)sender {
    if (sender.tag == 7000) {
        [self createDirectory];
    }else if (sender.tag == 7001) {
        [self downloadFile];
    }else if (sender.tag == 7002) {
        [self uploadFile];
    }
}

- (void)bluetoothBtn:(UIButton *)sender {
    if (sender.tag == 8000) {
        [self.BLECBPeripheral setup];
    }else if (sender.tag == 8001) {
        [self.BLECBPeripheral addSe];
    }else if (sender.tag == 8002) {
        [self.BLECBPeripheral adv];
    }
}

- (void)createDirectory {
    NSString *path = [espDocumentPath getDocumentsPath];
    NSLog(@"path:%@", path);
}


- (void)downloadFile {
    [ESPHomeService downloadWithURL:@"https://raw.githubusercontent.com/XuXiangJun/test/master/light.bin" fileDir:@"" progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"进度= %f",downloadProgress.fractionCompleted * 100);
    } success:^(NSString * _Nonnull success) {
        NSLog(@"success download fild path--->%@",success);
    } andFailure:^(int fail) {
        NSLog(@"%d",fail);
    }];
    
}

- (void)uploadFile {
    NSString *path = [espDocumentPath getDocumentsPath];
    NSString  *documentPath = [path stringByAppendingPathComponent:@"iOSUpgradeFiles/light.bin"];
    NSLog(@"%@",documentPath);
    NSLog(@"%f",[self getFileSize:documentPath]);
    NSString *ip=@"192.168.0.22";
    NSString *port=@"80";
    
    ////    升级文件上传
    NSString *urlStr=[NSString stringWithFormat:@"http://%@:%@/ota/firmware",ip,port];
    [espUploadHandleTool uploadFileWithURL:urlStr parameters:@{@"meshNodeMac":@"ffffffffffff",@"firmwareName":@"light.bin"} names:@[@"light"] filePaths:@[documentPath] progress:^(float Progress) {
        NSLog(@"进度 %f",Progress);
    } success:^(NSDictionary * _Nonnull success) {
        NSLog(@"%@",success);
        //        {"status_code":0,"status_msg":"MDF_OK"}
        if ([[success objectForKey:@"status_code"] intValue] == 0) {
            sleep(5);
            self->BLETimer=[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(requestOTAProgress) userInfo:nil repeats:true];
            [[NSRunLoop mainRunLoop] addTimer:self->BLETimer forMode:NSDefaultRunLoopMode];
        }
    } andFailure:^(int fail) {
        NSLog(@"%d",fail);
    }];
}

- (void)requestOTAProgress {
    NSString *ip=@"192.168.0.22";
    NSString *port=@"80";
    NSString *urlStr=[NSString stringWithFormat:@"http://%@:%@/device_request",ip,port];
    [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:@{@"meshNodeMac":@"240ac4286448",@"meshNodeNum":@"1"} withBodyContent:@{@"request":@"get_ota_progress"} andSuccess:^(NSArray * _Nonnull resultArr) {
        if ([[resultArr[0] objectForKey:@"status_code"] intValue] == 0) {
            [self->BLETimer invalidate];
        }
        NSLog(@"resultArr-->%@",resultArr);
    } andFailure:^(int fail) {
        NSLog(@"%d",fail);
        [self->BLETimer invalidate];
    }];
    
}


- (CGFloat) getFileSize:(NSString *)path
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];//获取文件的属性
        unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
        filesize = 1.0*size/1024;
    }
    return filesize;
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
