//
//  ESPUDPUtils.m
//  Esp32Mesh
//
//  Created by zhaobing on 2018/6/12.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "ESPUDP3232.h"
#import "ESPTools.h"
//#import "EspDevice.h"

@interface ESPUDP3232()<GCDAsyncUdpSocketDelegate>{
    NSTimer* timer;
    NSString* curFlag;
}
@property (strong, nonatomic)GCDAsyncUdpSocket * udpCLientSoket;
@end
#define udpPort 3232
//#define udpHost @"255.255.255.255"

@implementation ESPUDP3232

//单例模式
+ (instancetype)share {
    static ESPUDP3232 *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[ESPUDP3232 alloc]init];
    });
    return share;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        
        
    }
    return self;
    
}

-(void)starScan:(SccessBlock)successBlock failblock:(UDPScanFailedBlock)failBlock{
    [self cancelScan];
    _successBlock=successBlock;
    _failBlock=failBlock;
    //开启定时发送请求设备信息
    [self createUdpSocket];

    
}
//停止扫描
-(void)cancelScan{
    [_udpCLientSoket close];
    _udpCLientSoket = nil;

    //取消定时器
    [timer invalidate];
    timer = nil;
}

-(void) createUdpSocket{
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _udpCLientSoket = [[GCDAsyncUdpSocket alloc]initWithDelegate:self delegateQueue:queue];
    NSError * error = nil;
    [_udpCLientSoket bindToPort:udpPort error:&error];
    [_udpCLientSoket enableBroadcast:true error:nil];
    if (error) {
        NSLog(@"error:%@",error);
    }else {
        [_udpCLientSoket beginReceiving:&error];
    }
}



-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContex
{
        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSLog(@"dataStr--->%@",dataStr);
        if ([dataStr.lowercaseString containsString:@"mac"]&&[dataStr.lowercaseString containsString:@"\r\n"]) {
            NSArray* dataArr=[dataStr componentsSeparatedByString:@"\r\n"];
            NSString* newflag=[dataArr[1] componentsSeparatedByString:@"="][1];
            NSString* mac=[dataArr[0] componentsSeparatedByString:@"="][1];
            NSString* type=[dataArr[2] componentsSeparatedByString:@"="][1];
            if (![newflag isEqualToString:curFlag]) {
                curFlag=newflag;
                _successBlock(type,mac);
            }
        }

}

@end
