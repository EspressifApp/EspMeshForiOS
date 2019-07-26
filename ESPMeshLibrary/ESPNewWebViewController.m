//
//  ESPNewWebViewController.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2018/12/27.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "ESPNewWebViewController.h"

#import "AFNetworking.h"
#import "YTKKeyValueStore.h"

#import "EspActionDeviceInfo.h"
#import "EspDeviceUtil.h"
#import "EspJsonUtils.h"
#import "EspHttpUtils.h"
#import "ESPUDP3232.h"

#import "QRCodeReaderViewController.h"
#import "QRCodeReader.h"
#import <objc/runtime.h>

#import "ESPHomeService.h"
#import "ESPDocumentsPath.h"

#import "ESPUploadHandleTool.h"
#import "ESPCheckAppVersion.h"
#import "ESPDataConversion.h"
#import "ESPFBYDataBase.h"

#import "HGBRSAEncrytor.h"
#import "ESPDataConversion.h"
#import "NSString+URL.h"

#import "ESPLoadHyperlinksViewController.h"

#import "EspBlockingQueue.h"

#import "ESPSniffer.h"

#define ESPMeshAppleID @"1420425921"
#define ValidDict(f) (f!=nil && [f isKindOfClass:[NSDictionary class]])
#define ValidArray(f) (f!=nil && [f isKindOfClass:[NSArray class]] && [f count]>0)
#define ValidStr(f) (f!=nil && [f isKindOfClass:[NSString class]] && ![f isEqualToString:@""])

@interface ESPNewWebViewController ()<UIWebViewDelegate,NativeApisProtocol>{
    
    UIImageView* loadingImgView;
    NSMutableDictionary* ScanBLEDevices;
    NSMutableDictionary* DevicesOfScanUDP;
    NSMutableDictionary *requestOTAProgressDic;
    NSMutableArray *StaMacsForBleMacs;
    ESPDocumentsPath *espDocumentPath;
    ESPUploadHandleTool *espUploadHandleTool;
    
    BOOL isUDPScan;
    NSTimer* BLETimer;
    NSTimer *OTATimer;
    NSTimer *UPDTimer;
    NSString* username;
    NSString* lastSSID;
    BOOL isSendQueue;
    NSNumber* pairProgress;
    NSURLSessionTask *sessionTask;
    NSArray *stopRequestIpArr;
    NSUInteger taskInt;
}


@property (weak,nonatomic) UIWebView *webView;
@property (strong,nonatomic) JSContext *context;
@property (strong, nonatomic)JSValue *callbacks;

@property (strong, nonatomic)NSDate *lastRequestDate;

@end

@implementation ESPNewWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self settingUi];
    isSendQueue = NO;
//    espUploadHandleTool = [[ESPUploadHandleTool alloc]init];
    espUploadHandleTool = [ESPUploadHandleTool shareInstance];
    [espUploadHandleTool sendSessionInit];
    espDocumentPath = [[ESPDocumentsPath alloc]init];
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
    dispatch_queue_t queue = dispatch_queue_create("my.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
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
//用户登录信息
- (void)userGuestLogin {
//    NSString* paramjson=[ESPDataConversion jsonFromObject:@{@"status":@"0",@"username":@"Guest"}];
//    [self sendMsg:@"userGuestLogin" param:paramjson];
}
//获取系统语言
- (void)getLocale {
    NSString *tmplanguageName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0];
    NSString *languageName=([tmplanguageName.lowercaseString containsString:@"zh"] ? @"zh":@"en");
    
    NSString* paramjson=[ESPDataConversion jsonFromObject:@{@"language":languageName,@"country":languageName,@"os":@"ios"}];
    [self sendMsg:@"onLocaleGot" param:paramjson];
}
//用户登录
- (void)userLogin:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSDictionary*argsicp=[msg objectForKey:@"args"];
    if (argsicp[@"username"]!=nil){
        username=argsicp[@"username"];
        [ESPFBYDataBase espDataBaseInit:username];
    }
    NSString* paramjson=[ESPDataConversion jsonFromObject:@{@"code":@"0"}];
    [self sendMsg:@"userLogin" param:paramjson];
}
//开启蓝牙扫描
- (void)startBleScan {
    [self sendBLEResult];
    ScanBLEDevices=[NSMutableDictionary dictionaryWithCapacity:0];
    if (BLETimer) {
        [BLETimer invalidate];
        BLETimer=nil;
    }
    BLETimer=[NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(sendBLEResult) userInfo:nil repeats:true];
    [[NSRunLoop mainRunLoop] addTimer:BLETimer forMode:NSDefaultRunLoopMode];
    dispatch_async(dispatch_get_main_queue(), ^(){
        [[ESPMeshManager share] starScanBLE:^(EspDevice *device) {
            //        NSLog(@"device ouiMDF---->%@", device.ouiMDF);
            NSMutableDictionary *deviceDic = [NSMutableDictionary dictionaryWithCapacity:0];
            deviceDic[@"mac"] = device.bssid;
            deviceDic[@"name"] = device.name;
            deviceDic[@"rssi"] = [NSString stringWithFormat:@"%d",device.RSSI];
            deviceDic[@"device"] = device;
            deviceDic[@"version"] = device.version;
            deviceDic[@"bssid"] = device.bssid;
            deviceDic[@"beacon"] = device.ouiMDF;
            deviceDic[@"tid"] = device.deviceTid;
            deviceDic[@"only_beacon"] = @(device.onlyBeacon);
            self->ScanBLEDevices[device.bssid] = deviceDic;
        } failblock:^(int code) {
            
        }];
    });
}

//获取topo结构
- (void)scanTopo {
    [[ESPMeshManager share] starScanRootUDP:^(NSArray *devixe) {
        NSOperationQueue* opera=[[NSOperationQueue alloc] init];
        [opera addOperationWithBlock:^{
            NSMutableArray* tmpDeviceArr = [NSMutableArray arrayWithCapacity:0];
            for (int i = 0; i < devixe.count; i ++) {
                NSArray *macArr=[devixe[i] componentsSeparatedByString:@":"];
                EspDevice* device=[[EspDevice alloc] init];
                device.mac=macArr[0];
                device.host=macArr[1];
                device.httpType=macArr[2];
                device.port=macArr[3];
                NSMutableArray *meshItermArr = [[ESPMeshManager share] getMeshInfoFromHost:device];
                for (int i = 0; i < meshItermArr.count; i ++) {
                    [tmpDeviceArr addObject:meshItermArr[i]];
                }
            }
            
            NSMutableArray* macsArr=[NSMutableArray arrayWithCapacity:0];
            for (int i=0; i< tmpDeviceArr.count; i++) {
                [macsArr addObject:((EspDevice*)tmpDeviceArr[i]).mac];
            }
            NSString* json=[ESPDataConversion jsonFromObject:macsArr];
            [self sendMsg:@"onTopoScanned" param:json];
        }];
    } failblock:^(int code) {
        
    }];
}
//开启UDP扫描
- (void)scanDevicesAsync {
    NSMutableArray *scanUDPArr = [NSMutableArray arrayWithCapacity:0];
   
    dispatch_queue_t queueT = dispatch_queue_create("my.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);//一个并发队列
    dispatch_group_t grpupT = dispatch_group_create();//一个线程组
    dispatch_group_enter(grpupT);
    dispatch_group_async(grpupT, queueT, ^{
        [[ESPMeshManager share] starScanRootUDP:^(NSArray *devixe) {
            [scanUDPArr addObjectsFromArray:devixe];
        } failblock:^(int code) {
            
        }];
    });
    dispatch_group_async(grpupT, queueT, ^{
        [[ESPMeshManager share] starScanRootmDNS:^(NSArray * _Nonnull devixe) {
            [scanUDPArr addObjectsFromArray:devixe];
        } failblock:^(int code) {
            
        }];
    });
    dispatch_group_async(grpupT, queueT, ^{
        sleep(2);
        [[ESPMeshManager share] cancelScanRootmDNS];
    });
    dispatch_group_notify(grpupT, queueT, ^{
        NSSet *set = [NSSet setWithArray:scanUDPArr];
        NSArray *allArray = [set allObjects];
        [self obtainDeviceDetails:allArray];
    });
    dispatch_group_leave(grpupT);
}

- (void)obtainDeviceDetails:(NSArray *)dev {
    isUDPScan=true;
    DevicesOfScanUDP=[NSMutableDictionary dictionaryWithCapacity:0];
    UPDTimer=[NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(sendUDPResult) userInfo:nil repeats:false];
    [[NSRunLoop mainRunLoop] addTimer:UPDTimer forMode:NSDefaultRunLoopMode];
    NSOperationQueue * opq=[[NSOperationQueue alloc] init];
    opq.maxConcurrentOperationCount=1;
    [opq addOperationWithBlock:^{
        
        NSMutableArray* meshinfoArr = [NSMutableArray arrayWithCapacity:0];
        if (!ValidArray(dev)) {
            [UPDTimer invalidate];
            [self sendUDPResult];
            self->isUDPScan=false;
            return ;
        }
        for (int i = 0; i < dev.count; i ++) {
            NSArray *macArr=[dev[i] componentsSeparatedByString:@":"];
            EspDevice* device=[[EspDevice alloc] init];
            device.mac=macArr[0];
            device.host=macArr[1];
            device.httpType=macArr[2];
            device.port=macArr[3];
            NSMutableArray *meshItermArr = [[ESPMeshManager share] getMeshInfoFromHost:device];
            for (int i = 0; i < meshItermArr.count; i ++) {
                [meshinfoArr addObject:meshItermArr[i]];
            }
        }
        NSString *httpResponse = [ESPDataConversion fby_getNSUserDefaults:@"httpResponse"];
        if ([httpResponse intValue] != 200) {
            [UPDTimer invalidate];
            [self sendUDPResult];
            self->isUDPScan=false;
            return ;
        }
        NSMutableArray* tempInfosArr=[NSMutableArray arrayWithCapacity:0];
        for (int i=0; i<meshinfoArr.count; i++) {
            EspDevice* newDevice=[meshinfoArr objectAtIndex:i];
            [tempInfosArr addObject:@{@"mac":newDevice.mac,
                                      @"layer":[NSString stringWithFormat:@"%d",newDevice.meshLayerLevel],
                                      @"host":newDevice.host
                                      }];
        }
        if (tempInfosArr.count>0) {
            NSArray *deviceDetailsArr = [ESPDataConversion DeviceOfScanningUDPData:tempInfosArr];
            NSSet *set = [NSSet setWithArray:deviceDetailsArr];
            NSArray *allArray = [set allObjects];
            NSString* tmpjson=[ESPDataConversion jsonFromObject:allArray];
            [self sendMsg:@"onDeviceScanning" param:tmpjson];
            
        }else{
            [UPDTimer invalidate];
            [self sendUDPResult];
            self->isUDPScan=false;
            return ;
        }
        
        NSMutableArray *DevicesOfScanUDPKeyArr = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray *DevicesOfScanUDPHostArr = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray *DevicesOfScanUDPValueArr = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray *DevicesOfScanUDPGroupArr = [NSMutableArray arrayWithCapacity:0];
        EspActionDeviceInfo* deviceinfoAction = [[EspActionDeviceInfo alloc] init];
        NSMutableDictionary* resps = [deviceinfoAction doActionGetDevicesInfoLocal:meshinfoArr];
        if (resps.count>0) {
            
            for (int i=0; i<meshinfoArr.count; i++) {
                EspDevice* newDevice=[meshinfoArr objectAtIndex:i];
                NSString *url = [EspDeviceUtil getLocalUrlForProtocol:newDevice.httpType host:newDevice.host port:newDevice.port.intValue file:@""];
                [[NSUserDefaults standardUserDefaults] setValue:url forKey:newDevice.mac];
                //获取详细信息
                EspHttpResponse *response = resps[newDevice.mac];
                if (response != nil) {
                    NSDictionary* responDic=response.getContentJSON;
//                    NSLog(@"responDic====%@",responDic);
                    NSMutableDictionary *mDic = [ESPDataConversion deviceDetailData:responDic withEspDevice:newDevice];
                    [DevicesOfScanUDPGroupArr addObject:mDic[@"group"]];
                    if (responDic[@"characteristics"] != nil) {
                        //self->ScanUDPDevices[newDevice.mac]=mDic;
                        [DevicesOfScanUDPHostArr addObject:newDevice.host];
                        [DevicesOfScanUDPKeyArr addObject:newDevice.mac];
                        [DevicesOfScanUDPValueArr addObject:mDic];
                        
                        newDevice.sendInfo=mDic;
                        self->DevicesOfScanUDP[newDevice.mac]=newDevice;
                    }
                }
            }
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setValue:DevicesOfScanUDPHostArr forKey:@"DevicesOfScanUDPHostArr"];
            [defaults setValue:DevicesOfScanUDPKeyArr forKey:@"DevicesOfScanUDPKeyArr"];
            [defaults setValue:DevicesOfScanUDPValueArr forKey:@"DevicesOfScanUDPValueArr"];
            [defaults setValue:DevicesOfScanUDPGroupArr forKey:@"DevicesOfScanUDPGroupArr"];
            [defaults synchronize];
            
            [UPDTimer invalidate];
            [self sendUDPResult];
            self->isUDPScan=false;
            
        }else {
            [self DevicesOfScanUDPData];
            [UPDTimer invalidate];
            [self sendUDPResult];
            self->isUDPScan=false;
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
    NSString *requestStr = [msg objectForKey:@"request"];
    NSString *callbackStr = [msg objectForKey:@"callback"];
    NSArray *groupArr = [msg objectForKey:@"group"];
    id tag = [msg objectForKey:@"tag"];
    id macArr = [msg objectForKey:@"mac"];
    if (!ValidArray(macArr)) {
        macArr = @[[msg objectForKey:@"mac"]];
    }
    
    NSDictionary *deviceIpWithDic;
    BOOL isGroupBool = [msg objectForKey:@"isGroup"];
    NSString *isGroup;
    NSArray *deviceIpArr;
    if (isGroupBool) {
        isGroup = @"1";
    }else {
        isGroup = @"0";
    }
    deviceIpWithDic = [ESPDataConversion deviceRequestIpWithMac:macArr];
    deviceIpArr = [deviceIpWithDic allKeys];
    if (!ValidArray(deviceIpArr)) {
        if (callbackStr != nil) {
            [self sendMsg:callbackStr param:@""];
        }
        return;
    }
    
    taskInt = deviceIpArr.count;
    NSUInteger requestInt = deviceIpArr.count;
    
    NSMutableArray *resultAllArr = [NSMutableArray arrayWithCapacity:0];
    
    for (int i = 0; i < deviceIpArr.count; i ++) {
        
        NSArray *macs;
        NSMutableDictionary* headers = [NSMutableDictionary dictionary];
        if ([isGroup integerValue] == 1) {
            NSString* groupsStr=groupArr[0];
            
            for (int j=1; j<groupArr.count; j++) {
                groupsStr=[NSString stringWithFormat:@"%@,%@",groupsStr,groupArr[j]];
            }
            [headers setObject:groupsStr forKey:@"meshNodeGroup"];
        }
        macs = [deviceIpWithDic objectForKey:deviceIpArr[i]];
        if (!ValidArray(macs)) {
            if (callbackStr != nil) {
                [self sendMsg:callbackStr param:@""];
            }
            return;
        }
        NSString* macsStr=macs[0];
        if ([requestStr isEqualToString:@"reset"]) {//重置设备
            [self->DevicesOfScanUDP removeObjectForKey:macsStr];
        }
        for (int m=1; m<macs.count; m++) {
            macsStr=[NSString stringWithFormat:@"%@,%@",macsStr,macs[m]];
            
            if ([requestStr isEqualToString:@"reset"]) {//重置设备
                [self->DevicesOfScanUDP removeObjectForKey:macs[m]];
            }
        }
        
        NSString *port = @"80";
        NSString *urlStr = [NSString stringWithFormat:@"http://%@:%@/device_request",deviceIpArr[i],port];
        
        [headers setObject:[NSString stringWithFormat:@"%lu",(unsigned long)macs.count] forKey:@"meshNodeNum"];
        if ([msg objectForKey:@"root_response"]) {
            NSString* root_response = [NSString stringWithFormat:@"%@", [msg objectForKey:@"root_response"]];
            [headers setObject:root_response forKey:@"rootResponse"];
        }
        [headers setObject:macsStr forKey:@"meshNodeMac"];
        [headers setObject:isGroup forKey:@"isGroup"];
        [headers setObject:[NSString stringWithFormat:@"%lu",(unsigned long)requestInt] forKey:@"taskStr"];
        
        if (callbackStr) {
            [msg removeObjectForKey:@"callback"];
        }
        if (tag) {
            [msg removeObjectForKey:@"tag"];
        }
        if ([isGroup integerValue] == 1) {
            [msg removeObjectForKey:@"group"];
        }
        [msg removeObjectForKey:@"root_response"];
        [msg removeObjectForKey:@"mac"];
        [msg removeObjectForKey:@"host"];
        
        if (isSendQueue) {
            dispatch_queue_t queue = dispatch_queue_create("my.concurrentQueue", DISPATCH_QUEUE_SERIAL);
            dispatch_sync(queue, ^{
//                NSLog(@"%@----------%d",[NSThread currentThread], i);
                [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:headers withBodyContent:msg andSuccess:^(NSArray * _Nonnull resultArr) {
                    if (ValidArray(resultArr)) {
                        if (callbackStr == nil) {
                            return;
                        }
                        if (taskInt > 1) {
                            [resultAllArr addObjectsFromArray:resultArr];
                        }else {
                            [resultAllArr addObjectsFromArray:resultArr];
                            NSSet *set = [NSSet setWithArray:resultAllArr];
                            NSArray *allArray = [set allObjects];
                            NSMutableDictionary * jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                            jsonDic[@"result"] = allArray;
                            if (tag) {
                                jsonDic[@"tag"] = tag;
                            }
                            NSString *json = [ESPDataConversion jsonFromObject:jsonDic];
                            [self sendMsg:callbackStr param:json];
                        }
                        taskInt --;
                        NSLog(@"taskInt ---> %lu",(unsigned long)taskInt);                    }
                } andFailure:^(int fail) {
                    NSLog(@"%d",fail);
                    if (callbackStr != nil) {
                        [self sendMsg:callbackStr param:@""];
                    }
                }];
            });
        }else {
            dispatch_queue_t queueT = dispatch_queue_create("my.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);//一个并发队列
            dispatch_async(queueT, ^{
//                NSLog(@"%@----------%d",[NSThread currentThread], i);
                [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:headers withBodyContent:msg andSuccess:^(NSArray * _Nonnull resultArr) {
                    if (ValidArray(resultArr)) {
                        if (callbackStr == nil) {
                            return;
                        }
                        if (taskInt > 1) {
                            [resultAllArr addObjectsFromArray:resultArr];
                        }else {
                            [resultAllArr addObjectsFromArray:resultArr];
                            NSSet *set = [NSSet setWithArray:resultAllArr];
                            NSArray *allArray = [set allObjects];
                            NSMutableDictionary * jsonDic = [NSMutableDictionary dictionaryWithCapacity:0];
                            jsonDic[@"result"] = allArray;
                            if (tag) {
                                jsonDic[@"tag"] = tag;
                            }
                            NSString *json = [ESPDataConversion jsonFromObject:jsonDic];
                            [self sendMsg:callbackStr param:json];
                        }
                        taskInt --;
                        NSLog(@"taskInt ---> %lu",(unsigned long)taskInt);
                    }
                } andFailure:^(int fail) {
                    NSLog(@"%d",fail);
                    if (callbackStr != nil) {
                        [self sendMsg:callbackStr param:@""];
                    }
                }];
            });
        }
        
    }
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
    if (msg==nil) {
        return;
    }
    NSMutableDictionary* argsDic=[msg copy];
    //保存记录
    NSString* ssid=argsDic[@"ssid"];
    NSString* password=argsDic[@"password"];
    NSDictionary* objItem=@{@"ssid":ssid,@"password":password};
    [ESPFBYDataBase saveObject:objItem withNameTable:@"ap_table" withId:ssid];
    //开始配网
    NSMutableDictionary* deviceInfo = self->ScanBLEDevices[argsDic[@"ble_addr"]];
    if (deviceInfo ==nil ) {
        NSString* json=[ESPDataConversion jsonFromObject:@{@"progress":@"0",@"code":@0,@"message":@"配网失败"}];
        [self sendMsg:@"onConfigureProgress" param:json];
        return;
    }else{
        EspDevice* tmpDevice = deviceInfo[@"device"];
        
        pairProgress=[NSNumber numberWithInt:0];
        
        [[ESPMeshManager share] starBLEPair:tmpDevice pairInfo:argsDic timeOut:60 callBackBlock:^(NSString *msg) {
            NSLog(@"msg:::::::%@",msg);
            NSDictionary* logMsg;
            if (self->pairProgress.intValue>=90) {
//                self->pairProgress=[NSNumber numberWithInt:self->pairProgress.intValue+1];
            }else{
                self->pairProgress=[NSNumber numberWithInt:self->pairProgress.intValue+10];
            }
            NSArray *messageArr = [msg componentsSeparatedByString:@":"];
            if ([messageArr[0] containsString:@"success"]) {
                logMsg=@{@"progress":@100,@"code":messageArr[2],@"message":messageArr[1]};
            }else if([messageArr[0] containsString:@"error"]){
                self->pairProgress=[NSNumber numberWithInt:99];
                logMsg=@{@"progress":self->pairProgress,@"code":messageArr[2],@"message":messageArr[1]};
            }else if([messageArr[0] containsString:@"code"]){
                self->pairProgress=[NSNumber numberWithInt:99];
                logMsg=@{@"progress":self->pairProgress,@"code":messageArr[2],@"message":messageArr[1]};
            }else{//msg:
                logMsg=@{@"progress":self->pairProgress,@"code":messageArr[2],@"message":messageArr[1]};
            }
            NSLog(@"pairProgress----->%@",pairProgress);
            NSString* json=[ESPDataConversion jsonConfigureFromObject:logMsg];
            [self sendMsg:@"onConfigureProgress" param:json];
            
        }];
    }
    
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
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSDictionary *deviceIpWithMacDic = [ESPDataConversion deviceRequestIpWithMac:[msg objectForKey:@"macs"]];
    if (deviceIpWithMacDic == nil) {
        return;
    }
    NSArray *deviceIpArr = [deviceIpWithMacDic allKeys];
    stopRequestIpArr = deviceIpArr;
    for (int i = 0; i < deviceIpArr.count; i ++) {
        requestOTAProgressDic = [NSMutableDictionary dictionaryWithCapacity:0];
        NSArray* macs = [deviceIpWithMacDic objectForKey:deviceIpArr[i]];
        NSString *hostStr = deviceIpArr[i];
        if (macs.count==0) {
            return;
        }
        NSString* macsStr=macs[0];
        for (int i=1; i<macs.count; i++) {
            macsStr=[NSString stringWithFormat:@"%@,%@",macsStr,macs[i]];
        }
        requestOTAProgressDic[@"mac"] = macsStr;
        requestOTAProgressDic[@"macArr"] = macs;
        requestOTAProgressDic[@"host"] = hostStr;
        if ([msg[@"type"] intValue] == 3) {
            sessionTask = [espUploadHandleTool meshNodeMac:macsStr andWithFirmwareUrl:msg[@"bin"] withIPUrl:hostStr andSuccess:^(NSDictionary * _Nonnull dic) {
                NSLog(@"dic--->%@",dic);
                if (dic==nil) {
                    return ;
                }
                NSDictionary *resultDic = [dic objectForKey:@"result"];
                if ([[resultDic objectForKey:@"status_code"] intValue] == 0) {
                    NSMutableArray *jsonArr = [NSMutableArray arrayWithCapacity:0];
                    for (int i = 0; i < macs.count; i ++) {
                        NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                        macDic[@"mac"] = macs[i];
                        macDic[@"progress"] = @"50";
                        macDic[@"message"] = @"ota message";
                        [jsonArr addObject:macDic];
                    }
                    NSString* json=[ESPDataConversion jsonFromObject:jsonArr];
                    [self sendMsg:@"onOTAProgressChanged" param:json];
                }else {
                    NSString* json=[ESPDataConversion jsonFromObject:@[]];
                    [self sendMsg:@"onOTAResult" param:json];
                }
                
                sleep(3);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (OTATimer) {
                        [OTATimer invalidate];
                        OTATimer=nil;
                    }
                    OTATimer=[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(requestOTAProgress) userInfo:nil repeats:true];
                    [[NSRunLoop mainRunLoop] addTimer:OTATimer forMode:NSDefaultRunLoopMode];
                });
            } andFailure:^(int fail) {
                NSLog(@"fail--->%d",fail);
                NSString* json=[ESPDataConversion jsonFromObject:@[]];
                [self sendMsg:@"onOTAResult" param:json];
            }];
        }else if ([msg[@"type"] intValue] == 2) {
            NSString* binPath=[msg[@"bin"] componentsSeparatedByString:@"_"].lastObject;
            NSString *path = [espDocumentPath getDocumentsPath];
            NSString  *documentPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"iOSUpgradeFiles/%@",binPath]];
            NSLog(@"%@",documentPath);
            NSString *port=@"80";
            //    升级文件上传
            NSString *urlStr=[NSString stringWithFormat:@"http://%@:%@/ota/firmware",hostStr,port];
            sessionTask = [espUploadHandleTool uploadFileWithURL:urlStr parameters:@{@"meshNodeMac":macsStr,@"firmwareName":@"light.bin"} names:@[@"light"] filePaths:@[documentPath] progress:^(float Progress) {
                NSLog(@"进度 %f",Progress);
                NSMutableArray *jsonArr = [NSMutableArray arrayWithCapacity:0];
                for (int i = 0; i < macs.count; i ++) {
                    NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                    macDic[@"mac"] = macs[i];
                    macDic[@"progress"] = [NSString stringWithFormat:@"%f",Progress];
                    macDic[@"message"] = @"ota message";
                    [jsonArr addObject:macDic];
                }
                NSString* json=[ESPDataConversion jsonFromObject:jsonArr];
                [self sendMsg:@"onOTAProgressChanged" param:json];
            } success:^(NSDictionary * _Nonnull success) {
                NSLog(@"%@",success);
                if (success==nil) {
                    return ;
                }
                NSDictionary *resultDic = [success objectForKey:@"result"];
                if ([[resultDic objectForKey:@"status_code"] intValue] == 0) {
                    NSMutableArray *jsonArr = [NSMutableArray arrayWithCapacity:0];
                    for (int i = 0; i < macs.count; i ++) {
                        NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                        macDic[@"mac"] = macs[i];
                        macDic[@"progress"] = @"50";
                        macDic[@"message"] = @"ota message";
                        [jsonArr addObject:macDic];
                    }
                    NSString* json=[ESPDataConversion jsonFromObject:jsonArr];
                    [self sendMsg:@"onOTAProgressChanged" param:json];
                }else {
                    NSString* json=[ESPDataConversion jsonFromObject:@[]];
                    [self sendMsg:@"onOTAResult" param:json];
                }
                sleep(3);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (OTATimer) {
                        [OTATimer invalidate];
                        OTATimer=nil;
                    }
                    OTATimer=[NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(requestOTAProgress) userInfo:nil repeats:true];
                    [[NSRunLoop mainRunLoop] addTimer:OTATimer forMode:NSDefaultRunLoopMode];
                });
            } andFailure:^(int fail) {
                NSLog(@"%d",fail);
                NSString* json=[ESPDataConversion jsonFromObject:@[]];
                [self sendMsg:@"onOTAResult" param:json];
            }];
        }else {
            NSString* json=[ESPDataConversion jsonFromObject:@[]];
            [self sendMsg:@"onOTAResult" param:json];
        }
    }
    
}
- (void)requestOTAProgress {
    NSString *ip = requestOTAProgressDic[@"host"];
    NSArray *macArr = requestOTAProgressDic[@"macArr"];
    NSString *port=@"80";
    NSString *urlStr=[NSString stringWithFormat:@"http://%@:%@/device_request",ip,port];
    sessionTask = [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:@{@"meshNodeMac":requestOTAProgressDic[@"mac"],@"meshNodeNum":[NSString stringWithFormat:@"%lu",(unsigned long)macArr.count]} withBodyContent:@{@"request":@"get_ota_progress"} andSuccess:^(NSArray * _Nonnull resultArr) {
        NSLog(@"resultArr-->%@",resultArr);
        if (!ValidArray(resultArr)) {
            return ;
        }
        if (macArr.count == 1) {
            NSDictionary *resultDic = resultArr[0];
            if ([[resultDic objectForKey:@"code"] isEqualToString:[NSString stringWithFormat:@"200"]]) {
                float totalSize = [[resultDic objectForKey:@"total_size"] floatValue];
                float writtenSize = [[resultDic objectForKey:@"total_size"] floatValue];
                int Progress = writtenSize/totalSize;
                NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                macDic[@"mac"] = macArr[0];
                macDic[@"progress"] = [NSString stringWithFormat:@"%d",Progress * 100];
                macDic[@"message"] = @"ota message";
                if (totalSize == writtenSize) {
                    NSString* json=[ESPDataConversion jsonFromObject:macArr];
                    [self sendMsg:@"onOTAResult" param:json];
                }else {
                    NSString* json=[ESPDataConversion jsonFromObject:@[macDic]];
                    [self sendMsg:@"onOTAProgressChanged" param:json];
                }
            }else {
                NSString* json=[ESPDataConversion jsonFromObject:@[]];
                [self sendMsg:@"onOTAResult" param:json];
            }
            
        }else {
            NSMutableArray *jsonArr = [NSMutableArray arrayWithCapacity:0];
            NSMutableArray *jsonMacArr = [NSMutableArray arrayWithCapacity:0];
            for (int i = 0; i < resultArr.count; i ++) {
                if ([[resultArr[i] objectForKey:@"code"] isEqualToString:[NSString stringWithFormat:@"200"]]) {
                    float totalSize = [[resultArr[i] objectForKey:@"total_size"] floatValue];
                    float writtenSize = [[resultArr[i] objectForKey:@"total_size"] floatValue];
                    int Progress = writtenSize/totalSize;
                    NSMutableDictionary *macDic = [NSMutableDictionary dictionaryWithCapacity:0];
                    macDic[@"mac"] = [resultArr[i] objectForKey:@"mac"];
                    macDic[@"progress"] = [NSString stringWithFormat:@"%d",Progress * 100];
                    macDic[@"message"] = @"ota message";
                    [jsonArr addObject:macDic];
                    if (totalSize == writtenSize) {
                        [jsonMacArr addObject:[resultArr[i] objectForKey:@"mac"]];
                    }
                }else {
                    NSString* json=[ESPDataConversion jsonFromObject:@[]];
                    [self sendMsg:@"onOTAResult" param:json];
                }
            }
            if (resultArr.count == jsonMacArr.count) {
                NSString* json=[ESPDataConversion jsonFromObject:jsonMacArr];
                [self sendMsg:@"onOTAResult" param:json];
            }else {
                NSString* json=[ESPDataConversion jsonFromObject:jsonArr];
                [self sendMsg:@"onOTAProgressChanged" param:json];
            }
        }
        [self->OTATimer invalidate];
    } andFailure:^(int fail) {
        NSLog(@"%d",fail);
        NSString* json=[ESPDataConversion jsonFromObject:@[]];
        [self sendMsg:@"onOTAResult" param:json];
        [self->OTATimer invalidate];
    }];
    
}

//下载设备升级文件
- (void)downloadLatestRom {
    NSString *pahtStr = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/iOSUpgradeFiles"];
    BOOL pathBool = [self->espDocumentPath isSxistAtPath:pahtStr];
    if (!pathBool) {
        [self->espDocumentPath createDirectory:@"iOSUpgradeFiles"];
    }
    [ESPHomeService downloadWithURL:@"https://raw.githubusercontent.com/XuXiangJun/test/master/light.bin" fileDir:@"" progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"进度= %f",downloadProgress.fractionCompleted * 100);
    } success:^(NSString * _Nonnull success) {
        NSLog(@"success download fild path--->%@",success);
        NSString *paramjson=[ESPDataConversion jsonFromObject:@{@"download":@(true),@"file":success}];
        [self sendMsg:@"onDownloadLatestRom" param:paramjson];
    } andFailure:^(int fail) {
        NSLog(@"%d",fail);
        NSString *paramjson=[ESPDataConversion jsonFromObject:@{@"download":@(false),@"file":@"下载失败"}];
        [self sendMsg:@"onDownloadLatestRom" param:paramjson];
    }];
    
}
//获取本地升级文件
- (void)getUpgradeFiles {
    NSArray *filePathArr = [self->espDocumentPath documentFileName];
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
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    [sessionTask cancel];
    if (stopRequestIpArr) {
        for (int i = 0; i < stopRequestIpArr.count; i ++) {
            [espUploadHandleTool stopOTA:stopRequestIpArr[i] andSuccess:^(NSDictionary * _Nonnull dic) {
                NSLog(@"%@",dic);
            } andFailure:^(int fail) {
                NSLog(@"%d",fail);
            }];
        }
    }else {
        return;
    }
}
//重启设备命令
- (void)reboot:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSDictionary *deviceIpWithMacDic = [ESPDataConversion deviceRequestIpWithMac:[msg objectForKey:@"macs"]];
    if (deviceIpWithMacDic == nil) {
        return;
    }
    NSArray *deviceIpArr = [deviceIpWithMacDic allKeys];
    for (int i = 0; i < deviceIpArr.count; i ++) {
        NSArray* macs = [deviceIpWithMacDic objectForKey:deviceIpArr[i]];
        if (macs.count==0) {
            return;
        }
        NSString* macsStr=macs[0];
        for (int i=1; i<macs.count; i++) {
            macsStr=[NSString stringWithFormat:@"%@,%@",macsStr,macs[i]];
        }
        NSString *ip = deviceIpArr[i];
        NSString *port=@"80";
        NSString *urlStr=[NSString stringWithFormat:@"http://%@:%@/device_request",ip,port];
        [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:@{@"meshNodeMac":macsStr,@"meshNodeNum":[NSString stringWithFormat:@"%lu",(unsigned long)macs.count]} withBodyContent:@{@"request":@"reboot"} andSuccess:^(NSArray * _Nonnull resultArr) {
            NSLog(@"%@",resultArr);
        } andFailure:^(int fail) {
            NSLog(@"%d",fail);
        }];
    }
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
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                if (success) {
                    NSLog(@"success");
                }else{
                    NSLog(@"fail");
                }
            }];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
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
//发送消息给JS
//NSOperationQueue* operaSend;
-(void)sendMsg:(NSString*)methodName param:(id)params{
    
    if ([methodName isEqualToString:@"(null)"]) {
        return;
    }
    if (![methodName  isEqual: @"onScanBLE"]) {
        NSLog(@"app---->JS method:%@,params:%@",methodName,params);
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        JSValue *callback = self.context[methodName];
        [callback callWithArguments:@[params]];
    }];
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
    sleep(1);
    NSString* ssid = ESPMeshManager.share.getCurrentWiFiSsid;
    NSString* bssid = ESPMeshManager.share.getCurrentBSSID;
    bool isConnect = ssid ? true:false;
    if (ssid==nil) {
        ssid=@"";
    }
    if (bssid==nil) {
        bssid=@"";
    }
    NSString* lastSSID=[[NSUserDefaults standardUserDefaults] valueForKey:@"lastSSID"];
    NSString* lastBSSID=[[NSUserDefaults standardUserDefaults] valueForKey:@"lastBSSID"];
    if (lastSSID==nil) {
        lastSSID=@"";
    }
    if (lastBSSID==nil) {
        lastBSSID=@"";
    }
    if (![ssid isEqualToString:lastSSID]) {
        lastSSID=ssid;
    NSDictionary *wifidate = @{@"connected":@(isConnect),@"ssid":ssid,@"bssid":bssid,@"frequency":@""};
        NSString* paramjson=[ESPDataConversion jsonFromObject:wifidate];
        [self sendMsg:@"onWifiStateChanged" param:paramjson];
        //清楚缓存的设备
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:@"DevicesOfScanUDPHostArr"];
        [defaults removeObjectForKey:@"DevicesOfScanUDPKeyArr"];
        [defaults removeObjectForKey:@"DevicesOfScanUDPValueArr"];
        [defaults removeObjectForKey:@"DevicesOfScanUDPGroupArr"];
        [defaults synchronize];
        [[NSUserDefaults standardUserDefaults] setObject:ssid forKey:@"lastSSID"];
        [[NSUserDefaults standardUserDefaults] setObject:bssid forKey:@"lastBSSID"];
    }else {
        NSDictionary *wifidate = @{@"connected":@(isConnect),@"ssid":lastSSID,@"bssid":lastBSSID,@"frequency":@""};
        NSString* paramjson=[ESPDataConversion jsonFromObject:wifidate];
        [self sendMsg:@"onWifiStateChanged" param:paramjson];
    }

}

//设备状态变化上报
-(void)sendDeviceStatusChanged:(NSString*)mac{
    if (isUDPScan) {
        return;
    }
    isUDPScan=true;
    if (self.lastRequestDate) {
        NSLog(@"sendDeviceStatus两次请求时间间隔：%f",[[NSDate date] timeIntervalSinceDate:self.lastRequestDate]);
        if ([[NSDate date] timeIntervalSinceDate:self.lastRequestDate]<0.5) {
            return;//过滤频繁操作
        }
    }
    self.lastRequestDate= [NSDate date];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *ScanUDPKeyArr = [defaults objectForKey:@"DevicesOfScanUDPKeyArr"];
    NSMutableArray *DevicesOfScanUDPKeyArr = [NSMutableArray arrayWithArray:ScanUDPKeyArr];
    NSArray *ScanUDPHostArr = [defaults objectForKey:@"DevicesOfScanUDPHostArr"];
    NSMutableArray *DevicesOfScanUDPHostArr = [NSMutableArray arrayWithArray:ScanUDPHostArr];
    NSArray *ScanUDPValueArr = [defaults objectForKey:@"DevicesOfScanUDPValueArr"];
    NSMutableArray *DevicesOfScanUDPValueArr = [NSMutableArray arrayWithArray:ScanUDPValueArr];
    NSArray *ScanUDPGroupArr = [defaults objectForKey:@"DevicesOfScanUDPGroupArr"];
    NSMutableArray *DevicesOfScanUDPGroupArr = [NSMutableArray arrayWithArray:ScanUDPGroupArr];
    
    NSArray *macsArray = [mac componentsSeparatedByString:@","];
    NSSet *set = [NSSet setWithArray:macsArray];
    NSArray * macArray = [set allObjects];
//    NSLog(@"macArray个数：%@,ee%@",macsArray,macArray);
    NSMutableArray *DevicesArr = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0; i < macArray.count; i ++) {
        EspDevice *newDevice = DevicesOfScanUDP[macArray[i]];
        if (newDevice==nil) {
            continue;
        }
        [DevicesArr addObject:newDevice];
    }
    NSOperationQueue* opqueue=[[NSOperationQueue alloc] init];
    opqueue.maxConcurrentOperationCount=1;
    [opqueue addOperationWithBlock:^{
        EspActionDeviceInfo* deviceinfoAction = [[EspActionDeviceInfo alloc] init];
        NSMutableDictionary* resps = [deviceinfoAction doActionGetDevicesInfoLocal:DevicesArr];
        if (resps.count > 0) {
            for (int j = 0; j < DevicesArr.count; j ++) {
                EspDevice* device=[DevicesArr objectAtIndex:j];
                //获取详细信息
                EspHttpResponse *response = resps[device.mac];
                if (response != nil) {
                    NSDictionary* responDic=response.getContentJSON;
                    NSMutableDictionary *mDic = [ESPDataConversion deviceDetailData:responDic withEspDevice:device];
                    [DevicesOfScanUDPGroupArr addObject:mDic[@"group"]];
                    if (responDic[@"characteristics"] != nil) {
                        [DevicesOfScanUDPHostArr addObject:device.host];
                        [DevicesOfScanUDPKeyArr addObject:device.mac];
                        [DevicesOfScanUDPValueArr addObject:mDic];
                        device.sendInfo = mDic;
                        self->DevicesOfScanUDP[device.mac]=device;
                    }
                    NSString* json=[ESPDataConversion jsonFromObject:mDic];
                    [self sendMsg:@"onDeviceStatusChanged" param:json];
                    isUDPScan=false;
                }
            }
            
            [defaults setValue:DevicesOfScanUDPHostArr forKey:@"DevicesOfScanUDPHostArr"];
            [defaults setValue:DevicesOfScanUDPKeyArr forKey:@"DevicesOfScanUDPKeyArr"];
            [defaults setValue:DevicesOfScanUDPValueArr forKey:@"DevicesOfScanUDPValueArr"];
            [defaults setValue:DevicesOfScanUDPGroupArr forKey:@"DevicesOfScanUDPGroupArr"];
            [defaults synchronize];
            
        }
    }];
    
}

//设备http变化上报
-(void)sendDeviceFoundOrLost:(NSString*)mac{
    
    if (isUDPScan) {
        return;
    }
    isUDPScan=true;
    if (self.lastRequestDate) {
        NSLog(@"sendDeviceFound两次请求时间间隔：%f",[[NSDate date] timeIntervalSinceDate:self.lastRequestDate]);
        if ([[NSDate date] timeIntervalSinceDate:self.lastRequestDate]<0.5) {
            return;//过滤频繁操作
        }
    }
    self.lastRequestDate= [NSDate date];
    
    NSLog(@"%@",mac);
    
    [[ESPMeshManager share] starScanRootUDP:^(NSArray *devixe) {
        
        NSOperationQueue * opq=[[NSOperationQueue alloc] init];
        opq.maxConcurrentOperationCount=1;
        [opq addOperationWithBlock:^{
            
            NSMutableArray* meshinfoArr = [NSMutableArray arrayWithCapacity:0];
            for (int i = 0; i < devixe.count; i ++) {
                NSArray *macArr=[devixe[i] componentsSeparatedByString:@":"];
                EspDevice* device=[[EspDevice alloc] init];
                device.mac=macArr[0];
                device.host=macArr[1];
                device.httpType=macArr[2];
                device.port=macArr[3];
                NSMutableArray *meshItermArr = [[ESPMeshManager share] getMeshInfoFromHost:device];
                for (int i = 0; i < meshItermArr.count; i ++) {
                    [meshinfoArr addObject:meshItermArr[i]];
                }
            }
            NSString *httpResponse = [ESPDataConversion fby_getNSUserDefaults:@"httpResponse"];
            if ([httpResponse intValue] != 200) {
                return ;
            }
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSArray *ScanUDPKeyArr = [defaults objectForKey:@"DevicesOfScanUDPKeyArr"];
            NSMutableArray *DevicesOfScanUDPKeyArr = [NSMutableArray arrayWithArray:ScanUDPKeyArr];
            NSArray *ScanUDPHostArr = [defaults objectForKey:@"DevicesOfScanUDPHostArr"];
            NSMutableArray *DevicesOfScanUDPHostArr = [NSMutableArray arrayWithArray:ScanUDPHostArr];
            NSArray *ScanUDPValueArr = [defaults objectForKey:@"DevicesOfScanUDPValueArr"];
            NSMutableArray *DevicesOfScanUDPValueArr = [NSMutableArray arrayWithArray:ScanUDPValueArr];
            NSArray *ScanUDPGroupArr = [defaults objectForKey:@"DevicesOfScanUDPGroupArr"];
            NSMutableArray *DevicesOfScanUDPGroupArr = [NSMutableArray arrayWithArray:ScanUDPGroupArr];
            
            EspActionDeviceInfo* deviceinfoAction = [[EspActionDeviceInfo alloc] init];
            NSMutableDictionary* resps = [deviceinfoAction doActionGetDevicesInfoLocal:meshinfoArr];
            
            NSMutableDictionary* newDevices=[NSMutableDictionary dictionaryWithCapacity:0];
            for (int i=0; i<meshinfoArr.count; i++) {
                EspDevice* newDevice=[meshinfoArr objectAtIndex:i];
                NSString *url = [EspDeviceUtil getLocalUrlForProtocol:newDevice.httpType host:newDevice.host port:newDevice.port.intValue file:@""];
                [[NSUserDefaults standardUserDefaults] setValue:url forKey:newDevice.mac];
                //获取详细信息
                EspHttpResponse *response = resps[newDevice.mac];
                if (response != nil) {
                    NSDictionary* responDic=response.getContentJSON;
                    NSMutableDictionary *mDic = [ESPDataConversion deviceDetailData:responDic withEspDevice:newDevice];
                    [DevicesOfScanUDPGroupArr addObject:mDic[@"group"]];
                    if (responDic[@"characteristics"] != nil) {
                        [DevicesOfScanUDPHostArr addObject:newDevice.host];
                        [DevicesOfScanUDPKeyArr addObject:newDevice.mac];
                        [DevicesOfScanUDPValueArr addObject:mDic];
                        newDevice.sendInfo=mDic;
                        newDevices[newDevice.mac]=newDevice;
                    }
                }
            }
            [defaults setValue:DevicesOfScanUDPHostArr forKey:@"DevicesOfScanUDPHostArr"];
            [defaults setValue:DevicesOfScanUDPKeyArr forKey:@"DevicesOfScanUDPKeyArr"];
            [defaults setValue:DevicesOfScanUDPValueArr forKey:@"DevicesOfScanUDPValueArr"];
            [defaults setValue:DevicesOfScanUDPGroupArr forKey:@"DevicesOfScanUDPGroupArr"];
            [defaults synchronize];
            NSArray* oldMacs=self->DevicesOfScanUDP.allKeys;
            NSArray* newMacs=newDevices.allKeys;
            for (int i=0; i<newMacs.count; i++) {
                if (![oldMacs containsObject:newMacs[i]]) {
                    //上线
                    EspDevice* tmpDevice=(EspDevice*)newDevices[newMacs[i]];
                    NSLog(@"设备上线：%@",tmpDevice.sendInfo);
                    NSString* json=[ESPDataConversion jsonFromObject:tmpDevice.sendInfo];
                    [self sendMsg:@"onDeviceFound" param:json];
                    isUDPScan=false;
                }
            }
            for (int i=0; i<oldMacs.count; i++) {
                if (![newMacs containsObject:oldMacs[i]]) {
                    //下线
                    NSLog(@"设备下线：%@",oldMacs[i]);
                    NSString* json=oldMacs[i];
                    [self sendMsg:@"onDeviceLost" param:json];
                    isUDPScan=false;
                }
            }
            if (newDevices.count>0) {
                self->DevicesOfScanUDP=newDevices;
            }
            
        }];
        
    } failblock:^(int code) {
        
    }];
}

//设备Sniffer变化上报
- (void)sendDeviceSnifferChanged:(NSString*)mac{
    
    if (self.lastRequestDate) {
//        NSLog(@"sendDeviceStatus两次请求时间间隔：%f",[[NSDate date] timeIntervalSinceDate:lastRequestDate]);
        if ([[NSDate date] timeIntervalSinceDate:self.lastRequestDate]<0.5) {
            return;//过滤频繁操作
        }
    }
    self.lastRequestDate= [NSDate date];
    
    NSArray *macArr=[mac componentsSeparatedByString:@","];
    NSDictionary *deviceIpWithDic = [ESPDataConversion deviceRequestIpWithMac:macArr];
    NSArray *deviceIpArr = [deviceIpWithDic allKeys];
    if (!ValidArray(deviceIpArr)) {
        return;
    }
    NSLog(@"%@,%lu",deviceIpArr[0],(unsigned long)deviceIpArr.count);
    for (int i = 0; i < deviceIpArr.count; i ++) {
        [espUploadHandleTool getSnifferInfo:deviceIpArr[i] withDeviceMacs:mac andSuccess:^(NSArray * _Nonnull dic) {
            NSLog(@"%@",dic);
            NSString *nameStr;
            NSMutableArray *resultArr = [NSMutableArray arrayWithCapacity:0];
            for (int i = 0; i < dic.count; i ++) {
                ESPSniffer *espsniffer = [dic objectAtIndex:i];
                NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:0];
                if (ValidStr(espsniffer.manufacturerId)) {
                    NSArray *fileArr = [espDocumentPath readFile:@"wifi"];
                    for (int j = 0; j < fileArr.count; j ++) {
                        if ([fileArr[j] containsString:espsniffer.manufacturerId]) {
                            NSArray *contentArr = [fileArr[j] componentsSeparatedByString:@":"];
                            nameStr = contentArr[1];
                        }
                    }
                }else {
                    NSArray *fileArr = [espDocumentPath readFile:@"ble"];
                    for (int j = 0; j < fileArr.count; j ++) {
                        NSString *macStr = [espsniffer.meshMac substringToIndex:5];
                        if ([fileArr[j] containsString:macStr]) {
                            NSArray *contentArr = [fileArr[j] componentsSeparatedByString:@":"];
                            nameStr = contentArr[1];
                        }
                    }
                }
                resultDic[@"type"] = [NSString stringWithFormat:@"%d",espsniffer.snifferType];
                resultDic[@"mac"] = espsniffer.meshMac;
                resultDic[@"channel"] = [NSString stringWithFormat:@"%d",espsniffer.channel];
                resultDic[@"time"] = [NSString stringWithFormat:@"%lu",espsniffer.time];
                resultDic[@"rssi"] = [NSString stringWithFormat:@"%d",espsniffer.rssi];
                resultDic[@"mac"] = espsniffer.name;
                resultDic[@"org"] = nameStr;
                
                [resultArr addObject:resultDic];
            }
            NSString* json=[ESPDataConversion jsonConfigureFromObject:resultArr];
            [self sendMsg:@"onSniffersDiscovered" param:json];
        } andFailure:^(int fail) {
            
        }];
    }
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
