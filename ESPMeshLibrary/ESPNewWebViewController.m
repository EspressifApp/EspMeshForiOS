//
//  ESPNewWebViewController.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/27.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "ESPNewWebViewController.h"

#import "YTKKeyValueStore.h"
#import "ESPUDP3232.h"

#import "QRCodeReaderViewController.h"
//#import <objc/runtime.h>
#import "ESPUploadHandleTool.h"
#import "ESPCheckAppVersion.h"
#import "ESPDataConversion.h"
#import "ESPFBYDataBase.h"
#import "NSString+URL.h"

#import "ESPLoadHyperlinksViewController.h"
#import "ESPAliyunSDKUse.h"
#import "ESPAPPResources.h"
#import "ESPMeshManager.h"

// 项目Apple ID
#define ESPMeshAppleID @""
#define ValidDict(f) (f!=nil && [f isKindOfClass:[NSDictionary class]])
#define ValidArray(f) (f!=nil && [f isKindOfClass:[NSArray class]] && [f count]>0)

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface ESPNewWebViewController ()<UIWebViewDelegate,NativeApisProtocol,BleDelegate>{
    
    UIImageView* loadingImgView;
    NSMutableDictionary* ScanBLEDevices;
    NSMutableDictionary* DevicesOfScanUDP;
    ESPUploadHandleTool *espUploadHandleTool;
    
    BOOL isUDPScan;
    NSTimer* BLETimer;
    NSTimer *OTATimer;
    NSTimer *UPDTimer;
    NSString* username;
    BOOL isSendQueue;
    NSURLSessionTask *sessionTask;
    
    BabyBluetooth *babys;
}


@property (weak,nonatomic) UIWebView *webView;
@property (strong,nonatomic) JSContext *context;
@property (strong, nonatomic)JSValue *callbacks;

@end

@implementation ESPNewWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    ESPBLEHelper *espMesh = [ESPBLEHelper share];
    espMesh.delegate = self;
    [self settingUi];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self functionInit];
    });
}

- (void)bleUpdateStatusBlock:(CBCentralManager *)central {
    if (@available(iOS 10.0, *)) {
        if (central.state != CBManagerStatePoweredOn) {
            NSLog(@"蓝牙打开");
        }else if (central.state != CBManagerStatePoweredOff) {
            NSLog(@"蓝牙关闭");
        }
    } else {
        if (central.state != CBCentralManagerStatePoweredOn) {
            NSLog(@"蓝牙打开");
        }else if (central.state != CBCentralManagerStatePoweredOn) {
            NSLog(@"蓝牙关闭");
        }
    }
}

- (void)functionInit {
    isSendQueue = NO;
    espUploadHandleTool = [ESPUploadHandleTool shareInstance];
    [espUploadHandleTool sendSessionInit];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layOutControllerViews) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    //设备状态变化监视
    [[ESPUDP3232 share] starScan:^(NSString *type, NSString *mac) {
        if ([type containsString:@"http"]) {//http,https
            [self sendDeviceFoundOrLost:mac];
        } else if ([type containsString:@"status"]) {
            [self sendDeviceStatusChanged:mac];
        } else if ([type containsString:@"sniffer"]) {
            [self sendDeviceSnifferChanged:mac];
        }
    } failblock:^(int code) {}];
}

- (void)layOutControllerViews {
    NSString* htmlName=@"WebUI/app";
//    NSString *deviceType = [UIDevice currentDevice].model;
//    if([deviceType isEqualToString:@"iPhone"]) {
//        htmlName = @"WebUI/app";
//    }else if([deviceType isEqualToString:@"iPad"]) {
//        htmlName = @"WebUI/ipad";
//    }
    CGRect rectOfStatusbar = [[UIApplication sharedApplication] statusBarFrame];
    UIWebView * webView;
    if (rectOfStatusbar.size.height == 40) {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-20)];
    }else {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    }
    webView.delegate = self;
    webView.scrollView.bounces=false;
    [self.view addSubview:webView];
    [_webView removeFromSuperview];
    _webView=webView;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:htmlName ofType:@"html"]]]];
}

#pragma mark - 自定义方法
- (void)settingUi
{
    username=@"guest";
    [ESPFBYDataBase espDataBaseInit:username];
    self.view.backgroundColor = [UIColor whiteColor];
    
    loadingImgView=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    loadingImgView.contentMode=UIViewContentModeScaleAspectFill;
    
    NSString* htmlName=@"WebUI/app";
    loadingImgView.image=[UIImage imageNamed:@"启动图"];
//    NSString *deviceType = [UIDevice currentDevice].model;
//    if([deviceType isEqualToString:@"iPhone"]) {
//        htmlName = @"WebUI/app";
//        loadingImgView.image=[UIImage imageNamed:@"启动图"];
//    }else if([deviceType isEqualToString:@"iPad"]) {
//        htmlName = @"WebUI/ipad";
//        loadingImgView.image=[UIImage imageNamed:@"ipadLaunch"];
//    }
    CGRect rectOfStatusbar = [[UIApplication sharedApplication] statusBarFrame];
    UIWebView * webView;
    if (rectOfStatusbar.size.height == 40) {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-20)];
    }else {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    }
    webView.delegate = self;
    webView.scrollView.bounces=false;
    [self.view addSubview:webView];
    _webView=webView;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:htmlName ofType:@"html"]]]];
    [self.view addSubview:loadingImgView];
}

#pragma mark - <UIWebViewDelegate>代理方法
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    //从webview上获取相应的JSContext。
    self.context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    //设置异常处理
    self.context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        [JSContext currentContext].exception = exception;
        NSLog(@"context JS异常:%@",exception);
    };
    self.context[@"espmesh"] = self;
}

//关闭蓝牙扫描
- (void)stopBleScan {
    if (BLETimer) {
        [BLETimer invalidate];
        BLETimer=nil;
    }
    [[ESPMeshManager share] cancelScanBLE];
}
// 初始化视图
- (void)hideCoverImage {
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self->loadingImgView removeFromSuperview];
    });
}
//APP版本检测
- (void)checkAppVersion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *appResultsDict = [[ESPCheckAppVersion sharedInstance] checkAppVersionNumber:ESPMeshAppleID];
        if (!ValidDict(appResultsDict)) {
            NSString* paramjson=[ESPDataConversion jsonFromObject:@{@"status":@"-1"}];
            [self sendMsg:@"onCheckAppVersion" param:paramjson];
        }else {
            NSString *appStoreVersion = appResultsDict[@"version"];
            NSString *releaseNotesStr = appResultsDict[@"releaseNotes"];
            NSString* paramjson=[ESPDataConversion jsonConfigureFromObject:@{@"status":@"0",@"name":ESPMeshAppleID,@"version":appStoreVersion,@"notes":releaseNotesStr}];
            [self sendMsg:@"onCheckAppVersion" param:paramjson];
        }
    });
}
//APP版本更新
- (void)appVersionUpdate:(NSString *)message {
    BOOL updateBool = [[ESPCheckAppVersion sharedInstance] appVersionUpdate];
    if (updateBool) {
        NSString* paramjson=[ESPDataConversion jsonFromObject:@{@"status":@"0",@"message":@"更新成功"}];
        [self sendMsg:@"onCheckAppVersion" param:paramjson];
    }else {
        NSString* paramjson=[ESPDataConversion jsonFromObject:@{@"status":@"-1",@"message":@"更新失败"}];
        [self sendMsg:@"onCheckAppVersion" param:paramjson];
    }
}
//获取系统语言
- (void)getLocale {
    NSString *tmplanguageName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0];
    NSString *languageName=([tmplanguageName.lowercaseString containsString:@"zh"] ? @"zh":@"en");
    
    NSString* paramjson=[ESPDataConversion jsonFromObject:@{@"language":languageName,@"country":languageName,@"os":@"ios"}];
    [self sendMsg:@"onLocaleGot" param:paramjson];
}
//开启蓝牙扫描
- (void)startBleScan {
//    [self sendBLEResult];
    ScanBLEDevices=[NSMutableDictionary dictionaryWithCapacity:0];
    if (BLETimer) {
        [BLETimer invalidate];
        BLETimer=nil;
    }
    BLETimer=[NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(sendBLEResult) userInfo:nil repeats:true];
    [[NSRunLoop mainRunLoop] addTimer:BLETimer forMode:NSDefaultRunLoopMode];
    [ESPAPPResources startBleScanSuccess:^(NSDictionary * _Nonnull BleScanDic) {
        NSString *bssid = [BleScanDic objectForKey:@"bssid"];
        self->ScanBLEDevices[bssid] = BleScanDic;
    } andFailure:^(int fail) {
        
    }];
}

//获取topo结构
- (void)scanTopo {
    [ESPDataConversion scanDeviceTopo:^(NSArray * _Nonnull resultArr) {
        NSString* json=[ESPDataConversion jsonFromObject:resultArr];
        [self sendMsg:@"onTopoScanned" param:json];
    } andFailure:^(int fail) {
        NSString* json=[ESPDataConversion jsonFromObject:@[]];
        [self sendMsg:@"onTopoScanned" param:json];
    }];
}
//开启UDP扫描
- (void)scanDevicesAsync {
    isUDPScan=true;
    DevicesOfScanUDP=[NSMutableDictionary dictionaryWithCapacity:0];
    UPDTimer=[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(sendUDPResult) userInfo:nil repeats:false];
    [[NSRunLoop mainRunLoop] addTimer:UPDTimer forMode:NSDefaultRunLoopMode];
    [ESPAPPResources scanDevicesAsyncSuccess:^(NSDictionary * _Nonnull DevicesAsyncDic) {
        NSArray *onDeviceScanning = [DevicesAsyncDic objectForKey:@"onDeviceScanningResult"];
        if (onDeviceScanning != nil) {
            NSString* tmpjson=[ESPDataConversion jsonFromObject:onDeviceScanning];
            [self sendMsg:@"onDeviceScanning" param:tmpjson];
        }else {
            DevicesOfScanUDP=[[NSMutableDictionary alloc]initWithDictionary:DevicesAsyncDic];
            [self sendUDPResult];
        }
    } andFailure:^(int fail) {
        switch (fail) {
            case 8010:
                [self sendUDPResult];
                break;
            case 8011:
                [self DevicesOfScanUDPData];
                [self sendUDPResult];
                break;
            case 8012:
                [self DevicesOfScanUDPData];
                [self sendUDPResult];
                break;
            default:
                break;
        }
    }];
}

//更新房间信息
- (void)updateDeviceGroup:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    [ESPDataConversion updateGroupInformation:msg];
}

- (void)DevicesOfScanUDPData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *keyData = [defaults objectForKey:@"DevicesOfScanUDPKeyArr"];
    NSArray *valueData = [defaults objectForKey:@"DevicesOfScanUDPValueArr"];
    for (int i = 0; i < keyData.count; i ++) {
        EspDevice *newDevice = [[EspDevice alloc]init];
        newDevice.sendInfo = valueData[i];
        self->DevicesOfScanUDP[keyData[i]]=newDevice;
    }
}

//hwdevice_table表  保存本地配对信息
- (void)saveHWDevice:(NSString *)message {
    [ESPFBYDataBase saveHWDevicefby:message];
}
- (void)saveHWDevices:(NSString *)message {
    [ESPFBYDataBase saveHWDevicesfby:message];
}
- (void)deleteHWDevice:(NSString *)message {
    [ESPFBYDataBase deleteHWDevicefby:message];
}
- (void)deleteHWDevices:(NSString *)message {
    [ESPFBYDataBase deleteHWDevicesfby:message];
}
- (void)loadHWDevices {
    NSString *json = [ESPFBYDataBase loadHWDevicesfby];
    [self sendMsg:@"onLoadHWDevices" param:json];    
}

//发送多个设备命令防止重复操作
- (void)addQueueTask:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    isSendQueue = YES;
    
    if ([[msg objectForKey:@"method"] isEqualToString:[NSString stringWithFormat:@"requestDevicesMulticast"]]) {
        [self requestDevicesMulticast:[msg objectForKey:@"argument"]];
    } else if ([[msg objectForKey:@"method"] isEqualToString:[NSString stringWithFormat:@"requestDevice"]]) {
        [self requestDevice:[msg objectForKey:@"argument"]];
    }
}

//发送多设备命令
- (void)requestDevicesMulticast:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSMutableDictionary *messageDic = [[NSMutableDictionary alloc]initWithDictionary:msg];
    messageDic[@"isSendQueue"] = @(isSendQueue);
    [ESPAPPResources requestDevicesMulticastAsync:messageDic andSuccess:^(NSDictionary * _Nonnull dic) {
        NSMutableDictionary *resultDic = [[NSMutableDictionary alloc]initWithDictionary:dic];
        NSString *callbackStr = [resultDic objectForKey:@"callbackStr"];
        [resultDic removeObjectForKey:@"callbackStr"];
        NSString *json = [ESPDataConversion jsonFromObject:resultDic];
        [self sendMsg:callbackStr param:json];
    } andFailure:^(NSDictionary * _Nonnull failureDic) {
        int code = [[failureDic objectForKey:@"code"] intValue];
        if (code == 8010) {
            NSString *callBackStr = [failureDic objectForKey:@"callbackStr"];
            [self sendMsg:callBackStr param:@""];
        }else if (code == 8011) {
            NSString *macsStr = [failureDic objectForKey:@"resetMacsStr"];
            [self->DevicesOfScanUDP removeObjectForKey:macsStr];
        }
    }];
    isSendQueue = NO;
}
//发送单个设备命令
- (void)requestDevice:(NSString *)message {
    [self requestDevicesMulticast:message];
}

//表  Group组
- (void)saveGroup:(NSString *)message {
    id key = [ESPFBYDataBase saveGroupfby:message];
    if (key == nil) {
        return;
    }
    [self sendMsg:@"onSaveGroup" param:key];
}
- (void)saveGroups:(NSString *)message {
    [ESPFBYDataBase saveGroupsfby:message];
}
- (void)loadGroups {
    NSString *json = [ESPFBYDataBase loadGroupsfby];
    [self sendMsg:@"onLoadGroups" param:json];
}
- (void)deleteGroup:(NSString *)message {
    [ESPFBYDataBase deleteGroupfby:message];
}
//Mac  Mac表
- (void)saveMac:(NSString *)message {
    [ESPFBYDataBase saveMacfby:message];
}
- (void)deleteMac:(NSString *)message {
    [ESPFBYDataBase deleteMacfby:message];
}
- (void)deleteMacs:(NSString *)message {
    [ESPFBYDataBase deleteMacsfby:message];
}
- (void)loadMacs {
    NSString* json=[ESPFBYDataBase loadMacsfby];
    [self sendMsg:@"onLoadMacs" param:json];
}
// 获取APP版本信息
- (void)getAppInfo {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    // app build版本
//    NSString *app_build = [infoDictionary objectForKey:@"CFBundleVersion"];
    NSString* json=[ESPDataConversion jsonFromObject:@{@"version_name":app_Version,@"version_code":app_Version}];
    [self sendMsg:@"onGetAppInfo" param:json];
}
//获取配网记录
- (void)loadAPs {
    NSArray* dataArr=[ESPFBYDataBase getAllItemsFromTablefby:@"ap_table"];
    NSMutableArray* needArr=[NSMutableArray arrayWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
        [needArr addObject:item];
    }
    NSString* json=[ESPDataConversion jsonFromObject:needArr];
    [self sendMsg:@"onLoadAPs" param:json];
}
//蓝牙配网
- (void)startConfigureBlufi:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (!ValidDict(msg)) {
        NSString* json=[ESPDataConversion jsonFromObject:@{@"progress":@"0",@"code":@0,@"message":@"参数有误"}];
        [self sendMsg:@"onConfigureProgress" param:json];
        return;
    }
    NSDictionary* argsDic=[[NSMutableDictionary alloc]initWithDictionary:msg];
    NSDictionary *deviceInfo = ScanBLEDevices[argsDic[@"ble_addr"]];
    // 蓝牙连接
    [ESPAPPResources BleConnection:deviceInfo andSuccess:^(NSDictionary * _Nonnull dic) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:dic];
        [self sendMsg:@"onConfigureProgress" param:json];
        int code = [[dic objectForKey:@"code"] intValue];
        if (code == NotificationSuccessful) {
            // 发送协商加密
            [[ESPMeshManager share] sendDevicesNegotiatesEncryption];
        }else if (code == NegotiateSecuritykeySuccessful) {
            // 通知设备进入加密模式
            [[ESPMeshManager share] notifyDevicesToEnterEncryptionMode];
            // 蓝牙配网
            [ESPAPPResources startBLEConfigure:argsDic andSuccess:^(NSDictionary * _Nonnull dic) {
                NSString *code = [dic objectForKey:@"code"];
                if ([code isEqualToString:@"-8010"]) {
                    NSDictionary *deviceBind = [dic objectForKey:@"deviceBind"];
                    NSString* json=[ESPDataConversion jsonConfigureFromObject:deviceBind];
                    [self sendMsg:@"onAliDeviceBind" param:json];
                }else {
                    NSString* json=[ESPDataConversion jsonConfigureFromObject:dic];
                    [self sendMsg:@"onConfigureProgress" param:json];
                }
            } andFailure:^(NSDictionary * _Nonnull dic) {
                NSString* json=[ESPDataConversion jsonFromObject:@{@"progress":@"69",@"code":@0,@"message":@"配网失败"}];
                [self sendMsg:@"onConfigureProgress" param:json];
            }];
        }else if (code == CustomDataBlock) {
            NSLog(@"设备接收到自定义数据的回复：%@",[dic objectForKey:@"message"]);
        }
    } andFailure:^(NSDictionary * _Nonnull dic) {
        NSString* json=[ESPDataConversion jsonFromObject:@{@"progress":@"39",@"code":@0,@"message":@"蓝牙连接失败"}];
        [self sendMsg:@"onConfigureProgress" param:json];
    }];
}
- (void)stopConfigureBlufi {
    [[ESPMeshManager share] cancleBLEPair];
}
//meshId表
- (void)saveMeshId:(NSString *)message {
    [ESPFBYDataBase saveMeshIdfby:message];
}
- (void)deleteMeshId:(NSString *)message {
    [ESPFBYDataBase deleteMeshIdfby:message];
}
- (void)loadLastMeshId {
    
    NSString *meshid = [ESPFBYDataBase loadLastMeshIdfby];
    [self sendMsg:@"onLoadLastMeshId" param:meshid];
}
- (void)loadMeshIds {
    NSString* json=[ESPFBYDataBase loadMeshIdsfby];
    [self sendMsg:@"onLoadMeshIds" param:json];
}
//扫描二维码
- (void)scanQRCode {
    if ([QRCodeReader supportsMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]]) {
        static QRCodeReaderViewController *vc = nil;
        static dispatch_once_t onceToken;
        
        dispatch_once(&onceToken, ^{
            QRCodeReader *reader = [QRCodeReader readerWithMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
            vc                   = [QRCodeReaderViewController readerWithCancelButtonTitle:@"Cancel" codeReader:reader startScanningAtLoad:YES showSwitchCameraButton:YES showTorchButton:YES];
            vc.modalPresentationStyle = UIModalPresentationFormSheet;
        });
        vc.delegate = self;
        
        [vc setCompletionWithBlock:^(NSString *resultAsString) {
            NSLog(@"二维码结果: %@", resultAsString);
            [self sendMsg:@"onQRCodeScanned" param:resultAsString];
        }];
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self presentViewController:vc animated:YES completion:NULL];
        });
    }else {
        [self sendMsg:@"onQRCodeScanned" param:@"当前设备不支持二维码扫描"];
    }
}
//设备升级
- (void)startOTA:(NSString *)message {
    [ESPAPPResources startOTA:message Success:^(NSDictionary * _Nonnull startOTADic) {
        int type = [[startOTADic objectForKey:@"type"] intValue];
        sessionTask = [startOTADic objectForKey:@"sessionTask"];
        NSArray *startOTAArr = [startOTADic objectForKey:@"jsonArr"];
        NSString* json=[ESPDataConversion jsonFromObject:startOTAArr];
        [self sendMsg:@"onOTAProgressChanged" param:json];
        if (type == 0) {
            sleep(3);
            dispatch_queue_t queue = dispatch_queue_create("my.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
            dispatch_async(queue, ^{
                if (OTATimer) {
                    [OTATimer invalidate];
                    OTATimer=nil;
                }
                OTATimer=[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(requestOTAProgress) userInfo:nil repeats:true];
                [[NSRunLoop mainRunLoop] addTimer:OTATimer forMode:NSDefaultRunLoopMode];
            });
        }
    } andFailure:^(int fail) {
        NSString* json=[ESPDataConversion jsonFromObject:@[]];
        [self sendMsg:@"onOTAResult" param:json];
    }];
}
- (void)requestOTAProgress {
    [ESPAPPResources networkRequestOTAProgress:^(NSDictionary * _Nonnull startOTADic) {
        int type = [[startOTADic objectForKey:@"type"] intValue];
        sessionTask = [startOTADic objectForKey:@"sessionTask"];
        NSArray *startOTAArr = [startOTADic objectForKey:@"jsonArr"];
        NSString* json=[ESPDataConversion jsonFromObject:startOTAArr];
        if (type == 0) {
            [self sendMsg:@"onOTAProgressChanged" param:json];
        }else if (type == 1) {
            [self sendMsg:@"onOTAResult" param:json];
        }
        [self->OTATimer invalidate];
    } andFailure:^(int fail) {
        if (fail == 8010) {
            NSString* json=[ESPDataConversion jsonFromObject:@[]];
            [self sendMsg:@"onOTAResult" param:json];
        }else if (fail == 8011) {
            NSString* json=[ESPDataConversion jsonFromObject:@[]];
            [self sendMsg:@"onOTAResult" param:json];
            [self->OTATimer invalidate];
        }
    }];
    
}

//下载设备升级文件
- (void)downloadLatestRom {
    [ESPDataConversion downloadDeviceOTAFiles:^(NSString * _Nonnull successMsg) {
        NSString *paramjson=[ESPDataConversion jsonFromObject:@{@"download":@(true),@"file":successMsg}];
        [self sendMsg:@"onDownloadLatestRom" param:paramjson];
    } andFailure:^(int fail) {
        NSString *paramjson=[ESPDataConversion jsonFromObject:@{@"download":@(false),@"file":@"下载失败"}];
        [self sendMsg:@"onDownloadLatestRom" param:paramjson];
    }];
}
//获取本地升级文件
- (void)getUpgradeFiles {
    ESPDocumentsPath *espDocumentPath = [[ESPDocumentsPath alloc]init];
    NSArray *filePathArr = [espDocumentPath documentFileName];
    if (filePathArr == nil) {
        NSString *paramjson=[ESPDataConversion jsonFromObject:@[]];
        [self sendMsg:@"onGetUpgradeFiles" param:paramjson];
    }else{
        NSString *paramjson=[ESPDataConversion jsonFromObject:filePathArr];
        [self sendMsg:@"onGetUpgradeFiles" param:paramjson];
    }
}

//JS 注册系统通知
- (void)registerPhoneStateChange {
    dispatch_queue_t queue = dispatch_queue_create("my.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        //注册蓝牙变化通知
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appBleStateCallBack:) name:@"appBleStateNotification" object:nil];
        [self isBluetoothEnable];
        //程序进入前台并处于活动状态调用
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendWifiStatus) name:UIApplicationDidBecomeActiveNotification object:nil];
        //注册Wi-Fi变化通知
        AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
        [manager startMonitoring];
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            [self sendWifiStatus];
        }];
    });
}
//判断手机蓝牙是否打开
- (void)isBluetoothEnable {
    //返回true/false
    bool bleStatusBool=[[BabyBluetooth shareBabyBluetooth] centralManager].state==5 ? true:false;
    NSString *paramjson=[ESPDataConversion jsonFromObject:@{@"enable":@(bleStatusBool)}];
    [self sendMsg:@"onBluetoothStateChanged" param:paramjson];
}
//蓝牙变化通知
- (void)appBleStateCallBack:(NSNotification *)message {
    NSDictionary *objectDic = [message object];
    NSString *paramjson=[ESPDataConversion jsonFromObject:objectDic];
    [self sendMsg:@"onBluetoothStateChanged" param:paramjson];
}
//文件 Key - Value 增删改查
- (void)saveValuesForKeysInFile:(NSString *)message {
    [ESPFBYDataBase saveValuesForKeysInFilefby:message];
}
- (void)removeValuesForKeysInFile:(NSString *)message {
    [ESPFBYDataBase removeValuesForKeysInFilefby:message];
}
- (void)loadValueForKeyInFile:(NSString *)message {
    NSString* json=[ESPFBYDataBase loadValueForKeyInFilefby:message];
    if (json == nil) {
        return;
    }
    [self sendMsg:@"onLoadValueForKeyInFile" param:json];
}
- (void)loadAllValuesInFile:(NSString *)message {
    NSString* json=[ESPFBYDataBase loadAllValuesInFilefby:message];
    if (json == nil) {
        return;
    }
    id msg=[ESPDataConversion objectFromJsonString:message];
    NSString *callBack = [msg objectForKey:@"callback"];
    [self sendMsg:callBack param:json];
}

- (void)clearBleCache {
    
    
}
- (void)removeDevicesForMacs:(NSString *)message {
    
}

//停止OTA升级
- (void)stopOTA:(NSString *)message {
    [ESPAPPResources stopOTA:message withSessionTask:sessionTask];
}
//重启设备命令
- (void)reboot:(NSString *)message {
    [ESPAPPResources reboot:message];
}
//保存本地事件
- (void)saveDeviceEventsCoordinate:(NSString *)message {
    [ESPFBYDataBase saveDeviceEventsCoordinatefby:message];
}
- (void)loadDeviceEventsCoordinate:(NSString *)message {
    NSString* json=[ESPFBYDataBase loadDeviceEventsCoordinatefby:message];
    if (json == nil) {
        return;
    }
    id msg=[ESPDataConversion objectFromJsonString:message];
    NSString *callback=[msg objectForKey:@"callback"];
    [self sendMsg:callback param:[json URLEncodedString]];
}
- (void)loadAllDeviceEventsCoordinate:(NSString *)message {
    NSString* json=[ESPFBYDataBase loadAllDeviceEventsCoordinatefby:message];
    if (json == nil) {
        return;
    }
    id msg=[ESPDataConversion objectFromJsonString:message];
    NSString *callback=[msg objectForKey:@"callback"];
    [self sendMsg:callback param:json];
}
- (void)deleteDeviceEventsCoordinate:(NSString *)message {
    [ESPFBYDataBase deleteDeviceEventsCoordinatefby:message];
}
- (void)deleteAllDeviceEventsCoordinate {
    [ESPFBYDataBase deleteAllDeviceEventsCoordinatefby];
}
//跳转系统设置页面
- (void)gotoSystemSettings:(NSString *)message {
    [[ESPCheckAppVersion sharedInstance] gotoSystemSetting];
}

//加载超链接
- (void)newWebView:(NSString *)message {
    ESPLoadHyperlinksViewController *loadHyperlinks = [[ESPLoadHyperlinksViewController alloc]init];
    loadHyperlinks.webURL = message;
    [self presentViewController:loadHyperlinks animated:YES completion:nil];
}

//table信息存储(ipad)
- (void)saveDeviceTable:(NSString *)message {
    [ESPFBYDataBase saveDeviceTablefby:message];
}
- (void)loadDeviceTable {
    NSString *itemStr = [ESPFBYDataBase loadDeviceTablefby];
    [self sendMsg:@"onLoadDeviceTable" param:itemStr];
}

//table设备信息存储(ipad)
- (void)saveTableDevices:(NSString *)message {
    [ESPFBYDataBase saveTableDevicesfby:message];
}
- (void)loadTableDevices {
    NSString *json = [ESPFBYDataBase loadTableDevicesfby];
    [self sendMsg:@"onLoadTableDevices" param:json];
}
- (void)removeTableDevices:(NSString *)message {
    [ESPFBYDataBase removeTableDevicesfby:message];
}
- (void)removeAllTableDevices {
    [ESPFBYDataBase removeAllTableDevicesfby];
}

//用户登录信息
- (void)getAliUserInfo {
    // 获取当前会话
    ALBBOpenAccountSession *session = [ALBBOpenAccountSession sharedInstance];
    if ([session isLogin]) {
        // 获取用户信息
        ALBBOpenAccountUser *user = session.getUser;
        NSString* paramjson = [NSString stringWithFormat:@"%@",user];
        [self sendMsg:@"onGetAliUserInfo" param:paramjson];
    }else {
        [self sendMsg:@"onGetAliUserInfo" param:@"账号未登录"];
    }
}
//用户登出
- (void)aliUserLogout {
    [[ESPAliyunSDKUse sharedClient] aliyunLogout];
}
//用户是否登录
- (void)isAliUserLogin {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL isLogin = [[ESPAliyunSDKUse sharedClient] isAliyunLogin];
        NSString *paramjson=[ESPDataConversion jsonFromObject:@{@"isLogin":@(isLogin)}];
        [self sendMsg:@"onIsAliUserLogin" param:paramjson];
    });
}
//用户登录
- (void)aliUserLogin {
    NSLog(@"请集成阿里云SDK");
//    [[ESPAliyunSDKUse sharedClient] aliyunPresentLogin:self andSuccess:^(ALBBOpenAccountUser * _Nonnull dic) {
//        NSString* paramjson = [NSString stringWithFormat:@"%@",dic];
//        if ([dic mobile]!=nil){
//            username=[dic mobile];
//            [ESPFBYDataBase espDataBaseInit:username];
//        }
//        [self sendMsg:@"onAliUserLogin" param:paramjson];
//    } andFailure:^(NSString * _Nonnull errorMsg) {
//        [self sendMsg:@"onAliUserLogin" param:errorMsg];
//    }];
}

// 获取阿里云绑定设备列表
- (void)getAliyunDeviceList {
    [[ESPAliyunSDKUse sharedClient] getAliyunDeviceList:^(NSDictionary * _Nonnull resultdeviceDic) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:resultdeviceDic];
        [self sendMsg:@"onGetAliyunDeviceList" param:json];
    }];
}
// 发现本地的已配网设备
- (void)aliStartDiscovery {
    [[ESPAliyunSDKUse sharedClient] aliStartDiscoveryDevice:^(NSArray * _Nonnull devices) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:devices];
        [self sendMsg:@"onAliStartDiscovery" param:json];
    }];
}
// 停止扫描设备
- (void)aliStopDiscovery {
    [[ESPAliyunSDKUse sharedClient] aliStopDiscoveryDevice];
}
//设备绑定
- (void)aliDeviceBinding:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    [[ESPAliyunSDKUse sharedClient] aliDeviceBinding:msg andSuccess:^(NSDictionary * _Nonnull resultIotid) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:resultIotid];
        [self sendMsg:@"onAliDeviceBind" param:json];
    } andFailure:^(NSDictionary * _Nonnull errorMsg) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:errorMsg];
        [self sendMsg:@"onAliDeviceBind" param:json];
    }];
}
// 设备解绑
- (void)aliyunDeviceUnbindRequest:(NSString *)message {
    [[ESPAliyunSDKUse sharedClient] unbindDeviceRequest:message];
}
// 获取设备状态
- (void)getAliDeviceStatus:(NSString *)message {
    [[ESPAliyunSDKUse sharedClient] getAliyunDeviceStatus:message andSuccess:^(NSArray * _Nonnull resultStatusArr) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:resultStatusArr];
        [self sendMsg:@"onGetAliDeviceStatus" param:json];
    }];
}
// 获取设备属性
- (void)getAliDeviceProperties:(NSString *)message {
    [[ESPAliyunSDKUse sharedClient] getAliyunDeviceProperties:message andSuccess:^(NSArray * _Nonnull resultStatusArr) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:resultStatusArr];
        [self sendMsg:@"onGetAliDeviceProperties" param:json];
    }];
}
// 修改设备属性
- (void)setAliDeviceProperties:(NSString *)message {
    [[ESPAliyunSDKUse sharedClient] setAliyunDeviceProperties:message andSuccess:^(NSArray * _Nonnull resultStatusArr) {
        NSLog(@"setAliDeviceProperties ---> %@",resultStatusArr);
//        NSString* json=[ESPDataConversion jsonConfigureFromObject:resultStatusArr];
//        [self sendMsg:@"onGetAliDeviceProperties" param:json];
    }];
}

//发送消息给JS
-(void)sendMsg:(NSString*)methodName param:(id)params{
    
    if ([methodName isEqualToString:@"(null)"]) {
        return;
    }
    if (![methodName  isEqual: @"onScanBLE"]) {
        NSLog(@"app---->JS method:%@,params:%@",methodName,params);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        JSValue *callback = self.context[methodName];
        NSMutableArray *resultArr = [NSMutableArray arrayWithCapacity:0];
        [resultArr addObject:params];
        [callback callWithArguments:resultArr];
    });
}

-(void)sendBLEResult{
    if (ScanBLEDevices.count>0) {
        NSMutableArray *tmpArr = [NSMutableArray arrayWithCapacity:0];
        NSArray *allKeyArr = ScanBLEDevices.allKeys;
        for (int i = 0; i < allKeyArr.count; i ++) {
            [tmpArr addObject:ScanBLEDevices[allKeyArr[i]]];
        }
        NSMutableArray* sendArr = [NSMutableArray arrayWithCapacity:0];
        for (int i=0; i<tmpArr.count; i++) {
            
            if (ValidDict(tmpArr[i])) {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:tmpArr[i]];
                [dict removeObjectForKey:@"device"];
                [sendArr addObject:dict];
            }
        }
        NSString* json=[ESPDataConversion jsonFromObject:sendArr];
        [self sendMsg:@"onScanBLE" param:json];
    }
}

//UDP Scan超时或者失败反馈
-(void)sendUDPResult{
    
//    [[ESPMeshManager share] cancelScanRootUDP];
//    [[ESPMeshManager share] cancelScanRootmDNS];
    [UPDTimer invalidate];
    if (DevicesOfScanUDP.count>0) {
        NSMutableArray* sendInfo=[NSMutableArray arrayWithCapacity:0];
        for (EspDevice* item in DevicesOfScanUDP.allValues) {
            [sendInfo addObject:item.sendInfo];
        }
        
        NSString* json=[ESPDataConversion jsonFromObject:sendInfo];
        [self sendMsg:@"onDeviceScanned" param:json];
    }else{
        [self sendMsg:@"onDeviceScanned" param:@"[]"];
    }
    isUDPScan=false;
}

//wifi状态变化回掉
-(void)sendWifiStatus{
    [ESPDataConversion sendAPPWifiStatus:^(NSString * _Nonnull message) {
        [self sendMsg:@"onWifiStateChanged" param:message];
    }];
}

//设备状态变化上报
-(void)sendDeviceStatusChanged:(NSString*)mac{
    if (isUDPScan) {
        return;
    }
    isUDPScan=true;
    NSMutableDictionary *msgDic = [NSMutableDictionary dictionaryWithCapacity:0];
    msgDic[@"deviceMac"] = mac;
    msgDic[@"devicesOfScanUDP"] = DevicesOfScanUDP;

    [ESPDataConversion sendDevicesStatusChanged:msgDic withDeviceStatusSuccess:^(NSDictionary * _Nonnull statusResultDic) {
        DevicesOfScanUDP = statusResultDic[@"scanUDPDic"];
        NSString* json=[ESPDataConversion jsonFromObject:statusResultDic[@"resultDic"]];
        [self sendMsg:@"onDeviceStatusChanged" param:json];
        isUDPScan=false;
    } andFailure:^(int fail) {
        isUDPScan=false;
    }];
}

//设备http变化上报
-(void)sendDeviceFoundOrLost:(NSString*)mac{
    
    if (isUDPScan) {
        return;
    }
    isUDPScan=true;
    NSMutableDictionary *msgDic = [NSMutableDictionary dictionaryWithCapacity:0];
    msgDic[@"deviceMac"] = mac;
    msgDic[@"devicesOfScanUDP"] = DevicesOfScanUDP;
    [ESPDataConversion sendDevicesFoundOrLost:msgDic withDeviceStatusSuccess:^(NSDictionary * _Nonnull statusResultDic) {
        NSString *code = [statusResultDic objectForKey:@"code"];
        if ([code intValue] == 8011) {
            NSString *json = [statusResultDic objectForKey:@"result"];
            NSLog(@"设备上线：%@", json);
            [self sendMsg:@"onDeviceFound" param:json];
        }else if ([code intValue] == 8012) {
            NSString *json = [statusResultDic objectForKey:@"result"];
            NSLog(@"设备下线：%@",json);
            [self sendMsg:@"onDeviceLost" param:json];
        }else if ([code intValue] == 8013) {
            NSMutableDictionary *newDevices = [NSMutableDictionary dictionaryWithDictionary:statusResultDic[@"result"]];
            self->DevicesOfScanUDP=newDevices;
        }
        isUDPScan=false;
    } andFailure:^(int fail) {
        isUDPScan=false;
    }];
}

//设备Sniffer变化上报
- (void)sendDeviceSnifferChanged:(NSString*)mac{
    [ESPDataConversion sendDeviceSnifferInfo:mac withSnifferSuccess:^(NSArray * _Nonnull snifferResultArr) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:snifferResultArr];
        [self sendMsg:@"onSniffersDiscovered" param:json];
    } andFailure:^(int fail) {
        NSString* json=[ESPDataConversion jsonConfigureFromObject:@[]];
        [self sendMsg:@"onSniffersDiscovered" param:json];
    }];
}
//扫码代理
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    [reader stopScanning];
    
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:true];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:false];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
