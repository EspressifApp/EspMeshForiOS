//
//  ESPUDPUtils.m
//  Esp32Mesh
//
//  Created by zhaobing on 2018/6/12.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "ESPRootScanUDP.h"
#import "ESPTools.h"
//#import "EspDevice.h"

@interface ESPRootScanUDP()<GCDAsyncUdpSocketDelegate>{
    
    NSMutableArray *deviceArr;
    NSTimer* timer;
    BOOL hasSended;
}
@property (strong, nonatomic)GCDAsyncUdpSocket * udpCLientSoket;
@end
#define udpPort 1025
#define udpHost @"255.255.255.255"

@implementation ESPRootScanUDP

//单例模式
+ (instancetype)share {
    static ESPRootScanUDP *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[ESPRootScanUDP alloc]init];
    });
    return share;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _udpCLientSoket = [[GCDAsyncUdpSocket alloc]initWithDelegate:self delegateQueue:queue];
        NSError * error = nil;
        [_udpCLientSoket bindToPort:udpPort error:&error];
        [_udpCLientSoket enableBroadcast:true error:nil];
    }
    return self;
    
}

-(void)starScan:(UDPScanSccessBlock)successBlock failblock:(UDPScanFailedBlock)failBlock{
   
    
    hasSended=false;
    _successBlock=successBlock;
    _failBlock=failBlock;
    [timer invalidate];
    timer = nil;
    [_udpCLientSoket beginReceiving:nil];
    deviceArr = [NSMutableArray arrayWithCapacity:0];
    
    NSOperationQueue* op=[NSOperationQueue mainQueue];
    [op addOperationWithBlock:^{
        self->timer =  [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(sendMsg) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self->timer forMode:NSDefaultRunLoopMode];
        
        NSArray *deviceArrs=[[NSUserDefaults standardUserDefaults] valueForKey:@"LastScanRootDevice"];
        //超时
        NSTimer* tmpTimer=[NSTimer scheduledTimerWithTimeInterval:deviceArrs? 2:3 target:self selector:@selector(cancelScan) userInfo:nil repeats:false];
        [[NSRunLoop currentRunLoop] addTimer:tmpTimer forMode:NSDefaultRunLoopMode];
    }];
    
}
//停止扫描
-(void)cancelScan{
    [_udpCLientSoket pauseReceiving];
    //取消定时器
    [timer invalidate];
    timer = nil;
    NSArray *deviceArrs = [[NSUserDefaults standardUserDefaults] valueForKey:@"LastScanRootDevice"];
    if (_successBlock&&_successBlock!=NULL&&hasSended==false) {
        hasSended=true;
        _successBlock(deviceArrs);
        _successBlock=nil;
    }
}


- (void) sendMsg {
    NSString *s = @"Are You Espressif IOT Smart Device?";
    NSLog(@"%@", s);
    NSData *data = [s dataUsingEncoding:NSUTF8StringEncoding];
    [_udpCLientSoket sendData:data toHost:udpHost port:udpPort withTimeout:-1 tag:0];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"UDP发送信息成功");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    NSLog(@"UDP发送信息失败");
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContex
{
    //取得发送发的ip和端口

    NSString *hostAddr = [GCDAsyncUdpSocket hostFromAddress:address];
    //uint16_t port = [GCDAsyncUdpSocket portFromAddress:address];
    NSString *deviceAddress=[hostAddr componentsSeparatedByString:@":"].lastObject;
    NSString *curDevice=[ESPTools.getIPAddresses objectForKey:@"en0/ipv4"];
    
    //data就是接收的数据
    if ([deviceAddress isEqualToString:curDevice]==false) {//不是当前设备发的消息
        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([dataStr.lowercaseString containsString:@"esp"] && [dataStr.lowercaseString containsString:@"http"]) {
            NSLog(@"接收到%@的消息:%@",deviceAddress,dataStr);
            NSArray* dataArr=[dataStr componentsSeparatedByString:@" "];
            EspDevice* device=[[EspDevice alloc] init];
            device.mac=dataArr[2];
            device.host=deviceAddress;
            device.httpType=dataArr[3];
            device.port=dataArr[4];
            
            NSString* lastDeviceInfo=[NSString stringWithFormat:@"%@:%@:%@:%@",device.mac,device.host,device.httpType,device.port];
            if (deviceArr.count == 0) {
                [deviceArr addObject:lastDeviceInfo];
                [[NSUserDefaults standardUserDefaults] setObject:deviceArr forKey:@"LastScanRootDevice"];
            }else {
                BOOL isbool = NO;
                for (int i = 0; i < deviceArr.count; i ++) {
                    NSArray *macArr=[deviceArr[i] componentsSeparatedByString:@":"];
                    if (![macArr[0] isEqual:dataArr[2]]) {
//                        isbool = NO;
                    }else {
                        isbool = YES;
                    }
                }
                if (!isbool) {
                    [deviceArr addObject:lastDeviceInfo];
                    [[NSUserDefaults standardUserDefaults] setObject:deviceArr forKey:@"LastScanRootDevice"];
                }
                if (_successBlock&&_successBlock!=NULL&&hasSended==false) {
                    hasSended=true;
                    _successBlock(deviceArr);
                    _successBlock=nil;
                    [_udpCLientSoket pauseReceiving];
                    //取消定时器
                    [timer invalidate];
                    timer = nil;
                }
                
            }
            
            NSLog(@"deviceArr---->%@",deviceArr);
            
        }

    }
}

@end
