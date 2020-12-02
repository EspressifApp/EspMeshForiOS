//
//  ESPRootScanmDNS.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/1/30.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import "ESPRootScanmDNS.h"
#include <arpa/inet.h>

#define ValidArray(f) (f!=nil && [f isKindOfClass:[NSArray class]] && [f count]>0)
#define MDNS_TYPE_HTTP @"_mesh-http._tcp."
#define MDNS_TYPE_HTTPS @"_mesh-https._tcp."
#define MDNS_TYPE_LOCAL @"local."
@interface ESPRootScanmDNS()<NSNetServiceBrowserDelegate,NSNetServiceDelegate>

{
    NSMutableArray *deviceArr;
    BOOL hasSended;
}
@property (strong,nonatomic) NSNetService *netService;

@property (strong,nonatomic)NSNetServiceBrowser *browser;
@property NSMutableArray *services;
@property (strong,nonatomic) NSNetService *service;
@end

@implementation ESPRootScanmDNS
//单例模式
+ (instancetype)share {
    static ESPRootScanmDNS *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[ESPRootScanmDNS alloc]init];
    });
    return share;
}

- (void)starmDNSScan:(mDNSScanSccessBlock)successBlock failblock:(mDNSScanFailedBlock)failBlock {
    
    
    hasSended=false;
    _successBlock=successBlock;
    _failBlock=failBlock;
    deviceArr = [NSMutableArray arrayWithCapacity:0];
    
    NSOperationQueue* op=[NSOperationQueue mainQueue];
    [op addOperationWithBlock:^{
        
        self.netService = [[NSNetService alloc]initWithDomain:@"local." type:@"_mesh-http._tcp." name:@"" port:0];
        self.netService.delegate = self;
        
        [self performSelector:@selector(getSevices) withObject:nil afterDelay:1];
        
        NSArray *deviceArrs=[[NSUserDefaults standardUserDefaults] valueForKey:@"LastScanRootDevicemDNS"];
        //        超时
        NSTimer* tmpTimer=[NSTimer scheduledTimerWithTimeInterval:deviceArrs? 3:4 target:self selector:@selector(cancelmDNSScan) userInfo:nil repeats:false];
        [[NSRunLoop currentRunLoop] addTimer:tmpTimer forMode:NSDefaultRunLoopMode];
    }];
    
}

//停止扫描
-(void)cancelmDNSScan{
    [self.netService stop];
    
    NSArray *deviceArrs = [[NSUserDefaults standardUserDefaults] valueForKey:@"LastScanRootDevicemDNS"];
    if (ValidArray(deviceArrs)) {
        if (_successBlock&&_successBlock!=NULL&&hasSended==false) {
            hasSended=true;
            _successBlock(deviceArrs);
            _successBlock=nil;
        }
    }else {
        _failBlock(8004);
    }
}

-(void)getSevices{
    
    if (self.browser) {
        [self.browser stop];
    }
    else{
        self.browser = [[NSNetServiceBrowser alloc]init];
        self.browser.delegate = self;
        self.services = [NSMutableArray array];
    }
    [self.browser searchForServicesOfType:MDNS_TYPE_HTTP inDomain:MDNS_TYPE_LOCAL];
}

/*
 * 发现客户端服务
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    
    [self.services addObject:aNetService];
    
    [self performSelector:@selector(setService:) withObject:aNetService afterDelay:1];
    
}
/*
 * 客户端服务移除
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [self.services removeObject:aNetService];
    
}

- (void)setService:(NSNetService *)service
{
    _service = service;
    self.service.delegate = self;
    [self.service resolveWithTimeout:5];
}
/*
 * 解析成功
 */
- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog(@"netServiceDidResolveAddress---------=%@  =%@  =%@ = %@",_service.name,_service.addresses,_service.hostName,_service.type);
    NSLog(@"sender netServiceDidResolveAddress---------=%@  =%@  =%@ =%@",sender.name,sender.addresses,sender.hostName,sender.type);
    NSData *addressData = sender.addresses.firstObject;
    NSLog(@"addressData------>%@",addressData);
    NSString *addressStr = [self IPFromData:addressData];
    NSDictionary *attrs = [NSNetService dictionaryFromTXTRecordData:[sender TXTRecordData]];
    NSString *type = sender.type;
    if ([type isEqualToString:[NSString stringWithFormat:MDNS_TYPE_HTTP]]) {
        type = @"http";
    }else if ([type isEqualToString:[NSString stringWithFormat:MDNS_TYPE_HTTPS]]) {
        type = @"https";
    }else {
        return;
    }
    NSData *macData = attrs[@"mac"];
    if (macData == nil) {
        return;
    }
    NSString *mac = [[NSString alloc] initWithData:macData encoding:NSUTF8StringEncoding];
    
    if (![addressStr isEqualToString:[NSString stringWithFormat:@""]]) {
        NSArray *addressArr = [addressStr componentsSeparatedByString:@":"];
        EspDevice *device = [[EspDevice alloc] init];
        device.mac = mac;
        device.host = addressArr[0];
        device.httpType = type;
        device.port = addressArr[1];
        
        NSString* lastDeviceInfo=[NSString stringWithFormat:@"lastDeviceInfo---->%@:%@:%@:%@",device.mac,device.host,device.httpType,device.port];
        [deviceArr addObject:lastDeviceInfo];
        
        NSSet *set = [NSSet setWithArray:deviceArr];
        NSArray *deviceAllArray = [set allObjects];
        [[NSUserDefaults standardUserDefaults] setObject:deviceAllArray forKey:@"LastScanRootDevicemDNS"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        
    }
}
-(NSString*)IPFromData:(NSData*)data
{
    
    char addressBuffer[INET6_ADDRSTRLEN];
    
    memset(addressBuffer, 0, INET6_ADDRSTRLEN);
    
    typedef union {
        struct sockaddr sa;
        struct sockaddr_in ipv4;
        struct sockaddr_in6 ipv6;
    } ip_socket_address;
    
    ip_socket_address *socketAddress = (ip_socket_address *)[data bytes];
    
    if (socketAddress && (socketAddress->sa.sa_family == AF_INET || socketAddress->sa.sa_family == AF_INET6))
    {
        const char *addressStr = inet_ntop(
                                           socketAddress->sa.sa_family,
                                           (socketAddress->sa.sa_family == AF_INET ? (void *)&(socketAddress->ipv4.sin_addr) : (void *)&(socketAddress->ipv6.sin6_addr)),
                                           addressBuffer,
                                           sizeof(addressBuffer));
        
        int port = ntohs(socketAddress->sa.sa_family == AF_INET ? socketAddress->ipv4.sin_port : socketAddress->ipv6.sin6_port);
        
        if (addressStr && port)
        {
            NSLog(@"Found service at %s:%d", addressStr, port);
            return [NSString stringWithFormat:@"%s:%d",addressStr,port];
        }
    }
    return @"";
}


@end

