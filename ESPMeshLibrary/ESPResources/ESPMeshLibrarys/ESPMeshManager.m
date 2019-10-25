//
//  ESPMeshManager.m
//  ESPMeshLibrary
//
//  Created by zhaobing on 2018/6/20.
//  Copyright © 2018年 zhaobing. All rights reserved.
//

#import "ESPMeshManager.h"
#import "ESPTools.h"
#import "ESPNetWorking.h"
#import <CoreLocation/CoreLocation.h>


@protocol ChildrenDelegate <NSObject>
- (void)DeviceLost:(NSString *)mac;
- (void)DeviceFound:(NSDictionary *)devices;
- (void)DeviceStatusChanged:(NSDictionary *)devices;
@end

@implementation ESPMeshManager{
    ESPBLEIO* curPairIO;
    NSDate* starPairDate;
    CLLocationManager *_locationManagerSystem;
}

//单例模式
+ (instancetype)share {
    static ESPMeshManager *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[ESPMeshManager alloc]init];
    });
    return share;
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (BOOL)getUserLocationAuth {
    BOOL result = NO;
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            break;
        case kCLAuthorizationStatusRestricted:
            break;
        case kCLAuthorizationStatusDenied:
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            result = YES;
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            result = YES;
            break;
            
        default:
            break;
    }
    return result;
}

//获取当前Wi-Fi名
-(nullable NSString *)getCurrentWiFiSsid{
    if (![self getUserLocationAuth]) {
        _locationManagerSystem = [[CLLocationManager alloc]init];
        [_locationManagerSystem requestWhenInUseAuthorization];
    }
    return ESPTools.getCurrentWiFiSsid;
}
//获取当前BSSID
-(nullable NSString *)getCurrentBSSID{
    return ESPTools.getCurrentBSSID;
}
//开始蓝牙扫描
-(void)starScanBLE:(BLEScanSccessBlock)successBlock failblock:(BLEScanFailedBlock)failBlock
{
    [[ESPBLEHelper share] starScan:successBlock failblock:failBlock];
}
-(void)cancelScanBLE{
    [[ESPBLEHelper share] cancelScan];
}
//开始蓝牙Wi-Fi配网
-(void)starBLEPair:(EspDevice *)device withIsBleConnect:(BOOL)bleConnect callBackBlock:(BLEIOCallBackBlock)callBackBlock{
    [self cancelScanBLE];
    curPairIO = [[ESPBLEIO alloc] init:device withIsBleConnect:bleConnect callBackBlock:callBackBlock];
}


-(void)cancleBLEPair{
    if (curPairIO) {
        [curPairIO disconnectBLE];
        curPairIO=nil;
    }
}

- (void)sendMDFCustomDataToDevice:(NSData *)dataMessage {
    if (curPairIO) {
        [curPairIO sendMDFCustomData:dataMessage];
    }
}

- (void)sendDevicesNegotiatesEncryption {
    if (curPairIO) {
        [curPairIO sendDeviceNegotiatesEncryption];
    }
}

- (void)notifyDevicesToEnterEncryptionMode {
    if (curPairIO) {
        [curPairIO notifyDeviceToEnterEncryptionMode];
    }
}

- (void)sendDistributionNetworkDataToDevices:(NSMutableDictionary *)info timeOut:(NSInteger)timeOut callBackBlock:(BLEIOCallBackBlock)callBackBlock {
    if (curPairIO) {
        [curPairIO sendDistributionNetworkDataToDevice:info timeOut:timeOut callBackBlock:callBackBlock];
    }
}

//UDP扫描已联网设备根节点
-(void)starScanRootUDP:(UDPScanSccessBlock)successBlock failblock:(UDPScanFailedBlock)failBlock
{
    [[ESPRootScanUDP share] starScan:successBlock failblock:failBlock];
   
    
}
-(void)cancelScanRootUDP{
    [[ESPRootScanUDP share] cancelScan];
}

//mDNS扫描已联网设备根节点
- (void)starScanRootmDNS:(mDNSScanSccessBlock)successBlock failblock:(mDNSScanFailedBlock)failBlock {
    [[ESPRootScanmDNS share] starmDNSScan:successBlock failblock:failBlock];
}
- (void)cancelScanRootmDNS {
    [[ESPRootScanmDNS share] cancelmDNSScan];
}

//获取root host下的所有设备的mac
- (NSMutableArray*)getMeshInfoFromHost:(EspDevice *)device{
    return [ESPNetWorking getMeshInfoFromHost:device];
}

//OTA
-(void)StarOTA:(NSArray<EspDevice *> *)devices binPath:(NSString *)binPath callback:(MeshManagerCallBack)callback{
    //在串行异步队列中，任务都在新开辟的子线程中执行（异步），并且顺序执行（串行）
    dispatch_queue_t queue = dispatch_queue_create("com.serial.queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^(){
        //1.检查OTA版本和状态，是否需要升级及缺少的包
        NSLog(@"1.检查OTA版本和状态，是否需要升级及缺少的包");
       
        [ESPNetWorking requestOTAStatus:devices binPath:binPath callback:^(NSString *msg, NSDictionary *data) {
            callback(msg);
            NSLog(@"%@", data);
        }];
        
    });
    dispatch_async(queue, ^(){
        //2. tcp 把所有缺少的一次一次包发过去，完成之后发送结束包
        NSLog(@"2.tcp把所有缺少的一次一次包发过去，完成之后发送结束包");
    });
    dispatch_async(queue, ^(){
        //3. 回到1，检查还缺少的包和升级状况，如果没有缺少的包，进入4，有缺少的包，进入2
        NSLog(@"3. 回到1，检查还缺少的包和升级状况，如果没有缺少的包，进入4，有缺少的包，进入2");
    });
    dispatch_async(queue, ^(){
         //4.重启命令
        NSLog(@"4.重启命令");
       
    });
    NSLog(@"5.结束");
    
}

@end
