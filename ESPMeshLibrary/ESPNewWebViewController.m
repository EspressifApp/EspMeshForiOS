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

#import "HGBRSAEncrytor.h"
#import "ESPDataConversion.h"
#import "NSString+URL.h"

#define ESPMeshAppleID @"1420425921"
#define ValidDict(f) (f!=nil && [f isKindOfClass:[NSDictionary class]])
#define ValidArray(f) (f!=nil && [f isKindOfClass:[NSArray class]] && [f count]>0)

@interface ESPNewWebViewController ()<UIWebViewDelegate,NativeApisProtocol>{
    
    UIImageView* loadingImgView;
    NSMutableDictionary* ScanBLEDevices;
    NSMutableDictionary* DevicesOfScanUDP;
    NSMutableDictionary *requestOTAProgressDic;
    NSMutableArray *StaMacsForBleMacs;
    YTKKeyValueStore *dbStore;
    ESPDocumentsPath *espDocumentPath;
    ESPUploadHandleTool *espUploadHandleTool;
    
    BOOL isUDPScan;
    NSDate* lastRequestDate;
    NSTimer* BLETimer;
    NSTimer *OTATimer;
    NSTimer *UPDTimer;
    NSString* username;
    NSString* lastSSID;
    NSOperationQueue* controlQueue;
    NSNumber* pairProgress;
    NSURLSessionTask *sessionTask;
    NSArray *stopRequestIpArr;
}


@property (weak,nonatomic) UIWebView *webView;
@property (strong,nonatomic) JSContext *context;
@property (strong, nonatomic)JSValue *callbacks;

@end

@implementation ESPNewWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self settingUi];
    espUploadHandleTool = [[ESPUploadHandleTool alloc]init];
    espDocumentPath = [[ESPDocumentsPath alloc]init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layOutControllerViews) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    //设备状态变化监视
    [[ESPUDP3232 share] starScan:^(NSString *type, NSString *mac) {
        if ([type containsString:@"http"]) {//http,https
            [self sendDeviceFoundOrLost:mac];
        } else if ([type containsString:@"status"]) {
            [self sendDeviceStatusChanged:mac];
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
    dbStore = [[YTKKeyValueStore alloc] initDBWithName:[NSString stringWithFormat:@"%@.db",username]];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
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
    NSString *number = [[ESPCheckAppVersion sharedInstance] checkAppVersionNumber:ESPMeshAppleID];
    if (number == nil) {
        NSString* paramjson=[ESPDataConversion jsonFromObject:@{@"status":@"-1"}];
        [self sendMsg:@"onCheckAppVersion" param:paramjson];
    }else {
        NSString* paramjson=[ESPDataConversion jsonFromObject:@{@"status":@"0",@"name":ESPMeshAppleID,@"version":number}];
        [self sendMsg:@"onCheckAppVersion" param:paramjson];
    }
    
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
        NSString* dbName=[NSString stringWithFormat:@"%@.db",username.lowercaseString];
        dbStore = [[YTKKeyValueStore alloc] initDBWithName:dbName];
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
    dispatch_async(dispatch_get_main_queue(), ^(){
        [[ESPMeshManager share] starScanRootUDP:^(NSArray *devixe) {
            [self obtainDeviceDetails:devixe];
        } failblock:^(int code) {
        }];
    });
    dispatch_async(dispatch_get_main_queue(), ^(){
        [[ESPMeshManager share] starScanRootmDNS:^(NSArray * _Nonnull devixe) {
            [self obtainDeviceDetails:devixe];
        } failblock:^(int code) {
        }];
    });
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
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastScanRootDevice"];
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
            NSLog(@"meshinfoArr------> %lu",(unsigned long)meshinfoArr.count);
        }
        NSLog(@"meshinfoArr------> %lu",(unsigned long)meshinfoArr.count);
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
            NSString* tmpjson=[ESPDataConversion jsonFromObject:tempInfosArr];
//            [self DevicesOfScanUDPData];
//            [self sendUDPResult];
            [self sendMsg:@"onDeviceScanning" param:tmpjson];
            
        }else{
            [UPDTimer invalidate];
//            [self DevicesOfScanUDPData];
            [self sendUDPResult];
            self->isUDPScan=false;
            return ;
        }
        
        NSMutableArray *DevicesOfScanUDPKeyArr = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray *DevicesOfScanUDPHostArr = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray *DevicesOfScanUDPValueArr = [NSMutableArray arrayWithCapacity:0];
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
                    NSMutableDictionary *mDic=[NSMutableDictionary dictionaryWithCapacity:0];
                    mDic[@"mac"]=newDevice.mac;
                    if (responDic[@"position"]) {
                        mDic[@"position"]=responDic[@"position"];
                    }else {
                        mDic[@"position"]=@"";
                    }
                    mDic[@"state"]=@"local";
                    mDic[@"meshLayerLevel"]=[NSString stringWithFormat:@"%d",newDevice.meshLayerLevel];
                    mDic[@"meshID"]=newDevice.meshID;
                    mDic[@"host"]=newDevice.host;
                    mDic[@"tid"]=responDic[@"tid"];
                    if (responDic[@"idf_version"]) {
                        mDic[@"idf_version"]=responDic[@"idf_version"];
                    }else {
                        mDic[@"idf_version"]=@"";
                    }
                    if (responDic[@"mdf_version"]) {
                        mDic[@"mdf_version"]=responDic[@"mdf_version"];
                    }else {
                        mDic[@"mdf_version"]=@"";
                    }
                    if (responDic[@"mlink_version"]) {
                        mDic[@"mlink_version"]=responDic[@"mlink_version"];
                    }else {
                        mDic[@"mlink_version"]=@"";
                    }
                    if (responDic[@"mlink_trigger"]) {
                        mDic[@"mlink_trigger"]=responDic[@"mlink_trigger"];
                    }else {
                        mDic[@"mlink_trigger"]=@"";
                    }
                    mDic[@"name"]=responDic[@"name"];
                    mDic[@"version"]=responDic[@"version"];
                    mDic[@"characteristics"]=[ESPDataConversion getJSCharacters:responDic[@"characteristics"]];
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
            [defaults synchronize];
            
        }else {
            [self DevicesOfScanUDPData];
        }
        
        [UPDTimer invalidate];
        [self sendUDPResult];
        self->isUDPScan=false;
    }];
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
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSDictionary* argsDic = msg;
    [dbStore createTableWithName:@"hwdevice_table"];
    NSString *key = argsDic[@"mac"];
    [dbStore putObject:argsDic withId:key intoTable:@"hwdevice_table"];
}
- (void)saveHWDevices:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSArray* argsArr = msg;
    [dbStore createTableWithName:@"hwdevice_table"];
    
    for (int i=0; i<argsArr.count; i++) {
        NSDictionary* itemDic=argsArr[i];
        NSString *key = itemDic[@"mac"];
        [dbStore putObject:itemDic withId:key intoTable:@"hwdevice_table"];
    }
}
- (void)deleteHWDevice:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString* mac = msg;
    [dbStore createTableWithName:@"hwdevice_table"];
    [dbStore deleteObjectById:mac fromTable:@"hwdevice_table"];
}
- (void)deleteHWDevices:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSArray* argsDic = msg;
    [dbStore createTableWithName:@"hwdevice_table"];
    
    for (int j=0; j<argsDic.count; j++) {
        id mac = argsDic[j];
        [dbStore deleteObjectById:mac fromTable:@"hwdevice_table"];
    }
}
- (void)loadHWDevices {
    [dbStore createTableWithName:@"hwdevice_table"];
    NSArray* dataArr=[dbStore getAllItemsFromTable:@"hwdevice_table"];
    NSMutableArray* needArr=[NSMutableArray arrayWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
        [needArr addObject:item];
    }
    NSString* json=[ESPDataConversion jsonFromObject:needArr];
    [self sendMsg:@"onLoadHWDevices" param:json];
}

//发送多个设备命令防止重复操作
- (void)addQueueTask:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    if ([[msg objectForKey:@"method"] isEqualToString:[NSString stringWithFormat:@"requestDevicesMulticastAsync"]]) {
        [self requestDevicesMulticastAsync:[msg objectForKey:@"argument"]];
    }
}

//发送多设备命令
- (void)requestDevicesMulticastAsync:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *requestStr = [msg objectForKey:@"request"];
    NSString *callbackStr = [msg objectForKey:@"callback"];
    id tag = [msg objectForKey:@"tag"];
    
    if (lastRequestDate) {
        NSLog(@"requestDevices两次请求时间间隔：%f",[[NSDate date] timeIntervalSinceDate:lastRequestDate]);
        if ([[NSDate date] timeIntervalSinceDate:lastRequestDate]<0.5) {
            return;//过滤频繁操作
        }
    }
    lastRequestDate=[NSDate date];
    
    NSDictionary *deviceIpWithMacDic = [ESPDataConversion deviceRequestIpWithMac:[msg objectForKey:@"mac"]];
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
        if ([requestStr isEqualToString:@"reset"]) {//重置设备
            [self->DevicesOfScanUDP removeObjectForKey:macsStr];
        }
        for (int i=1; i<macs.count; i++) {
            macsStr=[NSString stringWithFormat:@"%@,%@",macsStr,macs[i]];
            
            if ([requestStr isEqualToString:@"reset"]) {//重置设备
                [self->DevicesOfScanUDP removeObjectForKey:macs[i]];
            }
        }
        
        NSString *port = @"80";
        NSString *urlStr = [NSString stringWithFormat:@"http://%@:%@/device_request",deviceIpArr[i],port];
        
        NSMutableDictionary* headers = [NSMutableDictionary dictionary];
        [headers setObject:[NSString stringWithFormat:@"%lu",(unsigned long)macs.count] forKey:@"meshNodeNum"];
        if ([msg objectForKey:@"root_response"]) {
            NSString* root_response = [NSString stringWithFormat:@"%@", [msg objectForKey:@"root_response"]];
            [headers setObject:root_response forKey:@"rootResponse"];
        }
        [headers setObject:macsStr forKey:@"meshNodeMac"];
        
        if (callbackStr) {
            [msg removeObjectForKey:@"callback"];
        }
        if (tag) {
            [msg removeObjectForKey:@"tag"];
        }
        [msg removeObjectForKey:@"root_response"];
        [msg removeObjectForKey:@"mac"];
        [msg removeObjectForKey:@"host"];
        
        
        if (controlQueue==nil) {
            controlQueue = [[NSOperationQueue alloc] init];
            controlQueue.maxConcurrentOperationCount=1;//1串行，>2并发
        }
        [controlQueue addOperationWithBlock:^{
            [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:headers withBodyContent:msg andSuccess:^(NSDictionary * _Nonnull dic) {
                if (dic != nil && [[dic objectForKey:@"status_code"] intValue] == 0) {
                    if (callbackStr == nil) {
                        return;
                    }
                    NSMutableDictionary * jsonDic = [[NSMutableDictionary alloc]initWithDictionary:dic];
                    if (tag) {
                        jsonDic[@"tag"] = tag;
                    }
                    NSString *json = [ESPDataConversion jsonFromObject:jsonDic];
                    [self sendMsg:callbackStr param:json];
                }
            } andFailure:^(int fail) {
                NSLog(@"%d",fail);
                NSString* json=[ESPDataConversion jsonFromObject:@{@"status_code":@"-100"}];
                [self sendMsg:callbackStr param:json];
            }];
        }];
    }
    
    
}
//发送单个设备命令
- (void)requestDeviceAsync:(NSString *)message {
    
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *callbackStr = [msg objectForKey:@"callback"];
    id tag = [msg objectForKey:@"tag"];
    NSString *requestStr = [msg objectForKey:@"request"];
    
    NSString* macsStr=[msg objectForKey:@"mac"];
    if ([requestStr isEqualToString:@"reset"]) {//重置设备
        [self->DevicesOfScanUDP removeObjectForKey:macsStr];
    }
    NSMutableDictionary* headers = [NSMutableDictionary dictionary];
    [headers setObject:@"1" forKey:@"meshNodeNum"];
    if ([msg objectForKey:@"root_response"]) {
        NSString* root_response = [NSString stringWithFormat:@"%@", [msg objectForKey:@"root_response"]];
        [headers setObject:root_response forKey:@"rootResponse"];
    }
    [headers setObject:macsStr forKey:@"meshNodeMac"];
    
    NSString *port = @"80";
    NSString *hostStr = [ESPDataConversion deviceRequestIp:macsStr];
    if (hostStr == nil) {
        return;
    }
    NSString *urlStr = [NSString stringWithFormat:@"http://%@:%@/device_request",hostStr,port];
    if (callbackStr) {
        [msg removeObjectForKey:@"callback"];
    }
    if (tag) {
        [msg removeObjectForKey:@"tag"];
    }
    [msg removeObjectForKey:@"root_response"];
    [msg removeObjectForKey:@"mac"];
    [msg removeObjectForKey:@"host"];
    
    [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:headers withBodyContent:msg andSuccess:^(NSDictionary * _Nonnull dic) {
        if ([[dic objectForKey:@"status_code"] intValue] == 0) {
            if (callbackStr == nil) {
                return;
            }
            NSMutableDictionary *jsonDic = [[NSMutableDictionary alloc]initWithDictionary:dic];
            if (tag) {
                jsonDic[@"tag"] = tag;
            }
            NSString* json=[ESPDataConversion jsonFromObject:jsonDic];
            [self sendMsg:callbackStr param:json];
        }
        NSLog(@"dic-->%@",dic);
    } andFailure:^(int fail) {
        NSLog(@"%d",fail);
    }];
    
}

//表  Group组
- (void)saveGroup:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSMutableDictionary* argsDic = msg;
    [dbStore createTableWithName:@"group_table"];
    id key = argsDic[@"id"];
    if (key==nil) {
        key=[ESPDataConversion getRandomStringWithLength];
        argsDic[@"id"]=key;
    }
    [dbStore putObject:argsDic withId:key intoTable:@"group_table"];
    
    [self sendMsg:@"onSaveGroup" param:key];
}
- (void)saveGroups:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if ([msg isEqual:[NSNull null]]) {
        return;
    }
//    NSLog(@"%@",msg);
    if (msg==nil) {
        return;
    }
    NSArray* argsDic = msg;
    [dbStore createTableWithName:@"group_table"];
    
    for (int j=0; j<argsDic.count; j++) {
        NSMutableDictionary* itemDic=argsDic[j];
        id key = itemDic[@"id"];
        if (key==nil) {
            key=[ESPDataConversion getRandomStringWithLength];
            itemDic[@"id"]=key;
        }
        [dbStore putObject:itemDic withId:key intoTable:@"group_table"];
    }
}
- (void)loadGroups {
    [dbStore createTableWithName:@"group_table"];
    NSArray* dataArr=[dbStore getAllItemsFromTable:@"group_table"];
    NSMutableArray* needArr=[NSMutableArray arrayWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
        [needArr addObject:item];
    }
    NSString* json=[ESPDataConversion jsonFromObject:needArr];
    [self sendMsg:@"onLoadGroups" param:json];
}
- (void)deleteGroup:(NSString *)message {
    if (message==nil) {
        return;
    }
    dbStore = [[YTKKeyValueStore alloc] initDBWithName:[NSString stringWithFormat:@"%@.db",username]];
    [dbStore createTableWithName:@"group_table"];
    id key = message;
    [dbStore deleteObjectById:key fromTable:@"group_table"];
}
//Mac  Mac表
- (void)saveMac:(NSString *)message {
    NSString* mac = message;
    [dbStore createTableWithName:@"mac_table"];
    [dbStore putObject:@{@"mac":mac} withId:mac intoTable:@"mac_table"];
}
- (void)deleteMac:(NSString *)message {
    NSString* mac = message;
    [dbStore createTableWithName:@"mac_table"];
    [dbStore deleteObjectById:mac fromTable:@"mac_table"];
}
- (void)deleteMacs:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSArray* argsDic = msg;
    [dbStore createTableWithName:@"mac_table"];
    
    for (int j=0; j<argsDic.count; j++) {
        id mac = argsDic[j];
        [dbStore deleteObjectById:mac fromTable:@"mac_table"];
    }
}
- (void)loadMacs {
    [dbStore createTableWithName:@"mac_table"];
    NSArray* dataArr=[dbStore getAllItemsFromTable:@"mac_table"];
    NSMutableArray* needArr=[NSMutableArray arrayWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject[@"mac"];
        [needArr addObject:item];
    }
    NSString* json=[ESPDataConversion jsonFromObject:needArr];
    [self sendMsg:@"onLoadMacs" param:json];
}
// 获取APP版本信息
- (void)getAppInfo {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    // app build版本
    NSString *app_build = [infoDictionary objectForKey:@"CFBundleVersion"];
    NSString* json=[ESPDataConversion jsonFromObject:@{@"version_name":app_build,@"version_code":app_Version}];
    [self sendMsg:@"onGetAppInfo" param:json];
}
//获取配网记录
- (void)loadAPs {
    NSArray* dataArr=[dbStore getAllItemsFromTable:@"ap_table"];
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
    [dbStore createTableWithName:@"ap_table"];
    NSString* ssid=argsDic[@"ssid"];
    NSString* password=argsDic[@"password"];
    NSDictionary* objItem=@{@"ssid":ssid,@"password":password};
    [dbStore putObject:objItem withId:ssid intoTable:@"ap_table"];
    //开始配网
    //EspDevice* device=_deviceDic.allValues[0];
    //        NSArray *whiteListArr = argsDic[@"whiteList"];
    //        for (int i = 0; i < whiteListArr.count; i ++) {
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
    //        }
    
}
- (void)stopConfigureBlufi {
    [[ESPMeshManager share] cancleBLEPair];
}
//meshId表
- (void)saveMeshId:(NSString *)message {
    NSString* meshid = message;
    [dbStore createTableWithName:@"meshid_table"];
    [dbStore putObject:@{@"meshid":meshid} withId:meshid intoTable:@"meshid_table"];
}
- (void)deleteMeshId:(NSString *)message {
    NSString* meshid = message;
    [dbStore createTableWithName:@"meshid_table"];
    [dbStore deleteObjectById:meshid fromTable:@"meshid_table"];
}
- (void)loadLastMeshId {
    [dbStore createTableWithName:@"meshid_table"];
    NSArray* dataArr=[dbStore getAllItemsFromTable:@"meshid_table"];
    NSString* meshid=@"";
    if (dataArr.count>0) {
        meshid=((YTKKeyValueItem*)dataArr[0]).itemObject[@"meshid"];
        NSDate* oldDate=((YTKKeyValueItem*)dataArr[0]).createdTime;
        for (int i=1; i<dataArr.count; i++) {
            NSDate* itemDate=((YTKKeyValueItem*)dataArr[i]).createdTime;
            if (([itemDate timeIntervalSince1970]-[oldDate timeIntervalSince1970])>0) {
                oldDate=itemDate;
                meshid=((YTKKeyValueItem*)dataArr[i]).itemObject[@"meshid"];
            }
        }
    }
    //NSString* json=[ESPDataConversion jsonFromObject:meshid];
    [self sendMsg:@"onLoadLastMeshId" param:meshid];
}
- (void)loadMeshIds {
    [dbStore createTableWithName:@"meshid_table"];
    NSArray* dataArr=[dbStore getAllItemsFromTable:@"meshid_table"];
    NSMutableArray* needArr=[NSMutableArray arrayWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject[@"meshid"];
        [needArr addObject:item];
    }
    NSString* json=[ESPDataConversion jsonFromObject:needArr];
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
    sessionTask = [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:@{@"meshNodeMac":requestOTAProgressDic[@"mac"],@"meshNodeNum":[NSString stringWithFormat:@"%lu",(unsigned long)macArr.count]} withBodyContent:@{@"request":@"get_ota_progress"} andSuccess:^(NSDictionary * _Nonnull dic) {
        NSLog(@"dic-->%@",dic);
        if (dic==nil) {
            return ;
        }
        if (macArr.count == 1) {
            NSDictionary *resultDic = [dic objectForKey:@"result"];
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
            NSArray *resultArr = [dic objectForKey:@"result"];
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
//        NSString *downloadProgressStr = [NSString stringWithFormat:@"%f",downloadProgress.fractionCompleted * 100];
//        NSString *paramjson=[ESPDataConversion jsonFromObject:@{@"status":@"0",@"message":@"下载进度",@"downloadProgress":downloadProgressStr}];
//        [self sendMsg:@"onDownloadLatestRom" param:paramjson];
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
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *tableName = [msg objectForKey:@"name"];
    NSArray *contentArr = [msg objectForKey:@"content"];
    for (int i = 0; i < contentArr.count; i ++) {
        NSDictionary *contentDic = contentArr[i];
        NSString *keyStr = [contentDic objectForKey:@"key"];
        NSString *valueStr = [contentDic objectForKey:@"value"];
        [dbStore putObject:@{keyStr:valueStr} withId:keyStr intoTable:tableName];
    }
}
- (void)removeValuesForKeysInFile:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *tableName=[msg objectForKey:@"name"];
    NSArray *keysArr=[msg objectForKey:@"keys"];
    [dbStore createTableWithName:tableName];
    for (int i = 0; i < keysArr.count; i ++) {
        [dbStore deleteObjectById:keysArr[i] fromTable:tableName];
    }
}
- (void)loadValueForKeyInFile:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *tableName=[msg objectForKey:@"name"];
    NSString *tableKey=[msg objectForKey:@"key"];
    [dbStore createTableWithName:tableName];
    NSArray* dataArr=[dbStore getAllItemsFromTable:tableName];
    NSMutableDictionary* needDic=[NSMutableDictionary dictionaryWithCapacity:0];
    NSMutableDictionary* contetDic=[NSMutableDictionary dictionaryWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        NSString *itemId = ((YTKKeyValueItem*)dataArr[i]).itemId;
        if ([tableKey isEqualToString:[NSString stringWithFormat:@"%@",itemId]]) {
            id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
            contetDic[itemId] = [item objectForKey:itemId];
        }
    }
    needDic[@"name"] = tableName;
    needDic[@"content"] = contetDic;
    NSString* json=[ESPDataConversion jsonFromObject:needDic];
    [self sendMsg:@"onLoadValueForKeyInFile" param:json];
}
- (void)loadAllValuesInFile:(NSString *)message {
    if (message==nil) {
        return;
    }
    NSString *tableName=message;
    [dbStore createTableWithName:tableName];
    NSArray* dataArr=[dbStore getAllItemsFromTable:tableName];
    NSMutableDictionary* needDic=[NSMutableDictionary dictionaryWithCapacity:0];
    NSMutableDictionary* contetDic=[NSMutableDictionary dictionaryWithCapacity:0];
    NSString *firstItemKey = @"";
    for (int i=0; i<dataArr.count; i++) {
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
        NSString *itemId = ((YTKKeyValueItem*)dataArr[i]).itemId;
        firstItemKey = itemId;
        contetDic[itemId] = [item objectForKey:itemId];
    }
    needDic[@"name"] = tableName;
    needDic[@"content"] = contetDic;
    needDic[@"latest_key"] = firstItemKey;
    NSString* json=[ESPDataConversion jsonFromObject:needDic];
    [self sendMsg:@"onLoadAllValuesInFile" param:json];
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
        [espUploadHandleTool requestWithIpUrl:urlStr withRequestHeader:@{@"meshNodeMac":macsStr,@"meshNodeNum":[NSString stringWithFormat:@"%lu",(unsigned long)macs.count]} withBodyContent:@{@"request":@"reboot"} andSuccess:^(NSDictionary * _Nonnull dic) {
            NSLog(@"%@",dic);
        } andFailure:^(int fail) {
            NSLog(@"%d",fail);
        }];
    }
}
//保存本地事件
- (void)saveDeviceEventsPosition:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *tableName = @"localEvents";
    NSString *keyStr = [msg objectForKey:@"mac"];
    [dbStore putObject:@{keyStr:msg} withId:keyStr intoTable:tableName];
}
- (void)loadDeviceEventsPositioin:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *tableName=@"localEvents";
    NSString *tableKey=[msg objectForKey:@"mac"];
    NSString *callback=[msg objectForKey:@"callback"];
    NSString *tag=[msg objectForKey:@"tag"];
    [dbStore createTableWithName:tableName];
    NSArray* dataArr=[dbStore getAllItemsFromTable:tableName];
    NSMutableDictionary* contetDic=[NSMutableDictionary dictionaryWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        NSString *itemId = ((YTKKeyValueItem*)dataArr[i]).itemId;
        if ([tableKey isEqualToString:[NSString stringWithFormat:@"%@",itemId]]) {
            id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
            contetDic = [item objectForKey:itemId];
        }
    }
    contetDic[@"tag"] = tag;
    NSString* json=[ESPDataConversion jsonFromObject:contetDic];
    [self sendMsg:callback param:[json URLEncodedString]];
}
- (void)loadAllDeviceEventsPosition:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *tableName=@"localEvents";
    NSString *callback=[msg objectForKey:@"callback"];
    NSString *tag=[msg objectForKey:@"tag"];
    [dbStore createTableWithName:tableName];
    NSArray* dataArr=[dbStore getAllItemsFromTable:tableName];
    NSMutableDictionary* needDic=[NSMutableDictionary dictionaryWithCapacity:0];
    NSMutableArray* contetArr=[NSMutableArray arrayWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        NSString *itemId = ((YTKKeyValueItem*)dataArr[i]).itemId;
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
        [contetArr addObject:[item objectForKey:itemId]];
    }
    needDic[@"tag"] = tag;
    needDic[@"content"] = [[ESPDataConversion jsonFromObject:contetArr] URLEncodedString];
    NSString* json=[ESPDataConversion jsonFromObject:needDic];
    [self sendMsg:callback param:json];
}
- (void)deleteDeviceEventsPosition:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *tableName=@"localEvents";
    NSString *keyStr=[msg objectForKey:@"keys"];
    [dbStore createTableWithName:tableName];
    [dbStore deleteObjectById:keyStr fromTable:tableName];
}
- (void)deleteAllDeviceEventsPosition:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *tableName=@"localEvents";
    [dbStore createTableWithName:tableName];
    NSArray* dataArr=[dbStore getAllItemsFromTable:tableName];
    for (int i=0; i<dataArr.count; i++) {
        NSString *itemId = ((YTKKeyValueItem*)dataArr[i]).itemId;
        [dbStore deleteObjectById:itemId fromTable:tableName];
    }
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
- (void)openHyperlinks:(NSString *)message {
    NSURL *urlStr = [NSURL URLWithString:message];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:urlStr options:@{} completionHandler:^(BOOL success) {
                if (success) {
                    NSLog(@"success");
                }else{
                    NSLog(@"fail");
                }
            }];
        } else {
            [[UIApplication sharedApplication] openURL:urlStr];
        }
    });
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
                [sendArr addObject:@{@"mac":tmpArr[i][@"mac"],@"name":tmpArr[i][@"name"],@"rssi":tmpArr[i][@"rssi"],@"version":tmpArr[i][@"version"],@"bssid":tmpArr[i][@"bssid"],@"tid":tmpArr[i][@"tid"],@"only_beacon":tmpArr[i][@"only_beacon"]}];
            }
        }
        NSString* json=[ESPDataConversion jsonFromObject:sendArr];
        [self sendMsg:@"onScanBLE" param:json];
    }
}

//UDP Scan超时或者失败反馈
-(void)sendUDPResult{
    
    [[ESPMeshManager share] cancelScanRootUDP];
    [[ESPMeshManager share] cancelScanRootmDNS];
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
    if (lastRequestDate) {
        NSLog(@"sendDeviceStatus两次请求时间间隔：%f",[[NSDate date] timeIntervalSinceDate:lastRequestDate]);
        if ([[NSDate date] timeIntervalSinceDate:lastRequestDate]<0.5) {
            return;//过滤频繁操作
        }
    }
    lastRequestDate= [NSDate date];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *ScanUDPKeyArr = [defaults objectForKey:@"DevicesOfScanUDPKeyArr"];
    NSMutableArray *DevicesOfScanUDPKeyArr = [NSMutableArray arrayWithArray:ScanUDPKeyArr];
    NSArray *ScanUDPHostArr = [defaults objectForKey:@"DevicesOfScanUDPHostArr"];
    NSMutableArray *DevicesOfScanUDPHostArr = [NSMutableArray arrayWithArray:ScanUDPHostArr];
    NSArray *ScanUDPValueArr = [defaults objectForKey:@"DevicesOfScanUDPValueArr"];
    NSMutableArray *DevicesOfScanUDPValueArr = [NSMutableArray arrayWithArray:ScanUDPValueArr];
    
    NSArray *macsArray = [mac componentsSeparatedByString:@","];
    NSSet *set = [NSSet setWithArray:macsArray];
    NSArray * macArray = [set allObjects];
    NSLog(@"macArray个数：%@,ee%@",macsArray,macArray);
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
                    NSMutableDictionary *mDic=[NSMutableDictionary dictionaryWithCapacity:0];
                    mDic[@"mac"]=device.mac;
                    if (responDic[@"position"]) {
                        mDic[@"position"]=responDic[@"position"];
                    }else {
                        mDic[@"position"]=@"";
                    }
                    mDic[@"state"]=@"local";
                    mDic[@"meshLayerLevel"]=[NSString stringWithFormat:@"%d",device.meshLayerLevel];
                    mDic[@"meshID"]=device.meshID;
                    mDic[@"host"]=device.host;
                    if (responDic[@"idf_version"]) {
                        mDic[@"idf_version"]=responDic[@"idf_version"];
                    }else {
                        mDic[@"idf_version"]=@"";
                    }
                    if (responDic[@"mdf_version"]) {
                        mDic[@"mdf_version"]=responDic[@"mdf_version"];
                    }else {
                        mDic[@"mdf_version"]=@"";
                    }
                    mDic[@"tid"]=responDic[@"tid"];
                    mDic[@"name"]=responDic[@"name"];
                    mDic[@"version"]=responDic[@"version"];
                    
                    mDic[@"characteristics"]=[ESPDataConversion getJSCharacters:responDic[@"characteristics"]];
                    if (responDic[@"characteristics"] != nil) {
                        [DevicesOfScanUDPHostArr addObject:device.host];
                        [DevicesOfScanUDPKeyArr addObject:device.mac];
                        [DevicesOfScanUDPValueArr addObject:mDic];
                        device.sendInfo = mDic;
                        self->DevicesOfScanUDP[device.mac]=device;
                    }
                    NSString* json=[ESPDataConversion jsonFromObject:mDic];
                    [self sendMsg:@"onDeviceStatusChanged" param:json];
                }
            }
            
            [defaults setValue:DevicesOfScanUDPHostArr forKey:@"DevicesOfScanUDPHostArr"];
            [defaults setValue:DevicesOfScanUDPKeyArr forKey:@"DevicesOfScanUDPKeyArr"];
            [defaults setValue:DevicesOfScanUDPValueArr forKey:@"DevicesOfScanUDPValueArr"];
            [defaults synchronize];
            
        }
    }];
    
}

//设备http变化上报
-(void)sendDeviceFoundOrLost:(NSString*)mac{
    
    if (isUDPScan) {
        return;
    }
    
    if (lastRequestDate) {
        NSLog(@"sendDeviceFound两次请求时间间隔：%f",[[NSDate date] timeIntervalSinceDate:lastRequestDate]);
        if ([[NSDate date] timeIntervalSinceDate:lastRequestDate]<0.5) {
            return;//过滤频繁操作
        }
    }
    lastRequestDate= [NSDate date];
    
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
                    NSMutableDictionary *mDic=[NSMutableDictionary dictionaryWithCapacity:0];
                    mDic[@"mac"]=newDevice.mac;
                    if (responDic[@"position"]) {
                        mDic[@"position"]=responDic[@"position"];
                    }else {
                        mDic[@"position"]=@"";
                    }
                    mDic[@"state"]=@"local";
                    mDic[@"meshLayerLevel"]=[NSString stringWithFormat:@"%d",newDevice.meshLayerLevel];
                    mDic[@"meshID"]=newDevice.meshID;
                    mDic[@"host"]=newDevice.host;
                    if (responDic[@"idf_version"]) {
                        mDic[@"idf_version"]=responDic[@"idf_version"];
                    }else {
                        mDic[@"idf_version"]=@"";
                    }
                    if (responDic[@"mdf_version"]) {
                        mDic[@"mdf_version"]=responDic[@"mdf_version"];
                    }else {
                        mDic[@"mdf_version"]=@"";
                    }
                    mDic[@"tid"]=responDic[@"tid"];
                    mDic[@"name"]=responDic[@"name"];
                    mDic[@"version"]=responDic[@"version"];
                    mDic[@"characteristics"]=[ESPDataConversion getJSCharacters:responDic[@"characteristics"]];
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
                }
            }
            for (int i=0; i<oldMacs.count; i++) {
                if (![newMacs containsObject:oldMacs[i]]) {
                    //下线
                    NSLog(@"设备下线：%@",oldMacs[i]);
                    NSString* json=oldMacs[i];
                    [self sendMsg:@"onDeviceLost" param:json];
                }
            }
            if (newDevices.count>0) {
                self->DevicesOfScanUDP=newDevices;
            }
            
        }];
        
    } failblock:^(int code) {
        
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
