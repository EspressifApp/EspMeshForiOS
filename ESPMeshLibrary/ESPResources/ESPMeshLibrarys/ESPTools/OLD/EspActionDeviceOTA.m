//
//  EspActionDeviceOTA.m
//  Esp32Mesh
//
//  Created by AE on 2018/4/24.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspActionDeviceOTA.h"
#import "EspRomQueryResult.h"
#import "EspHttpUtils.h"
#import "EspHttpResponse.h"
#import "GCDAsyncSocket.h"
#import "EspJsonUtils.h"
#import "EspDeviceUtil.h"
#import "EspBlockingQueue.h"
#import "EspNetUtils.h"

static NSString * const EspBinSuffix = @".bin";
static const int EspOTAStatusSuccess = 0;
static const int EspOTAStatusContinue = 1;

static NSString * const EspKeyBinVersion = @"ota_bin_version";
static NSString * const EspKeyBinLength = @"ota_bin_len";
static NSString * const EspKeyPackageLength = @"package_length";
static NSString * const EspKeyPackageSequence = @"package_sequence";

static NSString * const EspRequestOTAStatus = @"ota_status";
static NSString * const EspRequestOTAReboot = @"ota_reboot";

static NSString * const EspHeaderOTAAddress = @"Mesh-Ota-Address";
static NSString * const EspHeaderOTALength = @"Mesh-Ota-Length";

@interface EspActionDeviceOTA () <GCDAsyncSocketDelegate>

@property (strong, nonatomic) GCDAsyncSocket *socket;
@property (strong, nonatomic) EspBlockingQueue *writeQueue;
@property (strong, nonatomic) EspBlockingQueue *readQueue;

@end

@implementation EspActionDeviceOTA

- (BOOL)doActionDownloadLastestRomVersionCloud {
    // Query cloud
    EspRomQueryResult *queryResult = [self doActionQueryLatestVersionForKey:EspRomDeviceKey];
    if (!queryResult) {
        NSLog(@"Query latest rom failed");
        return NO;
    }
    
    // Query local cache
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *dirPath = [cachePath stringByAppendingPathComponent:@"ota"];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![manager fileExistsAtPath:dirPath isDirectory:&isDir]) {
        BOOL createDir = [manager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
        NSLog(@"Create ota dir %@", createDir?@"success":@"failed");
        if (!createDir) {
            return NO;
        }
    }
    NSString *fileName = [queryResult.fileNames objectAtIndex:0];
    NSString *binPath = [dirPath stringByAppendingPathComponent:fileName];
    BOOL isFile;
    if ([manager fileExistsAtPath:binPath isDirectory:&isFile]) {
        NSLog(@"The lastest bin exists");
        return YES;
    }
    
    NSString *downloadUrl = [NSString stringWithFormat:EspUrlRomDownloadFormat, queryResult.version, fileName];
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    NSString *authValue = [NSString stringWithFormat:@"%@ %@", EspKeyToken, EspRomDeviceKey];
    [headers setObject:authValue forKey:EspKeyAuth];
    
    EspHttpResponse *response = [EspHttpUtils getForUrl:downloadUrl params:nil headers:headers];
    if (!response) {
        NSLog(@"Download rom failed");
        return NO;
    }
    if (response.code != EspHttpCodeOK) {
        NSLog(@"Response failed code=%d, message=%@", response.code, response.message);
        return NO;
    }
    
    NSData *bin = response.content;
    BOOL write = [bin writeToFile:binPath atomically:YES];
    NSLog(@"Save bin %@", write?@"success":@"failed");
    return write;
}

- (EspRomQueryResult *)doActionQueryLatestVersionForKey:(NSString *)key {
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    NSString *authValue = [NSString stringWithFormat:@"%@ %@", EspKeyToken, key];
    [headers setObject:authValue forKey:EspKeyAuth];
    EspHttpResponse *response = [EspHttpUtils getForUrl:EspUrlRomQuery params:nil headers:headers];
    NSLog(@"Query rom get response");
    if (!response) {
        NSLog(@"Query rom response nil");
        return nil;
    }
    if (response.code != EspHttpCodeOK) {
        NSLog(@"Query rom response code %d", response.code);
        return nil;
    }
    
    id respJSON = [response getContentJSON];
    if (!respJSON) {
        NSLog(@"Query rom content nil");
        return nil;
    }
    
    @try {
        EspRomQueryResult *result = [[EspRomQueryResult alloc] init];
        
        NSString *latestVersion = [respJSON valueForKey:EspKeyLatestVersion];
        NSArray *romsArray = [respJSON valueForKey:EspKeyRoms];
        for (id versionJSON in romsArray) {
            NSString *version = [versionJSON valueForKey:EspKeyVersion];
            if (![version isEqualToString:latestVersion]) {
                continue;
            }
            
            NSArray *fileArray = [versionJSON valueForKey:EspKeyFiles];
            for (id fileJSON in fileArray) {
                NSString *fileName = [fileJSON valueForKey:EspKeyName];
                [result.fileNames addObject:fileName];
            }
            result.version = latestVersion;
            break;
        }
        
        return result;
    } @catch (NSException *e) {
        NSLog(@"Query lastest version rom error: %@", e);
        return nil;
    }
}
//开始
- (void)doActionOTALocalDevices:(NSArray<EspDevice *> *)devices binPath:(NSString *)binPath {
    [self otaLocalDevice:devices binPath:binPath];
}

- (void)otaLocalDevice:(NSArray<EspDevice *> *)devices binPath:(NSString *)binPath {
    EspDevice *deviceFirst = devices[0];
    NSString *host = deviceFirst.host;
    int port = deviceFirst.port.intValue;
    
    NSMutableString *binVersionReverse = [NSMutableString string];
    for (NSUInteger i = binPath.length - 1 - EspBinSuffix.length; ; i--) {
        unichar c = [binPath characterAtIndex:i];
        if (c != '/') {
            [binVersionReverse appendFormat:@"%c", c];
        } else {
            break;
        }
        
        if (i == 0) {
            break;
        }
    }
    NSMutableString *binVersion = [NSMutableString string];
    for (NSUInteger i = binVersionReverse.length - 1; ; i--) {
        unichar c = [binVersionReverse characterAtIndex:i];
        [binVersion appendFormat:@"%c", c];
        
        if (i == 0) {
            break;
        }
    }
    NSLog(@"OTA bin version = %@", binVersion);
    
    NSData *binData = [NSData dataWithContentsOfFile:binPath];
    if (!binData) {
        NSLog(@"OTA read bin data failed");
        return;
    }
    NSLog(@"OTA bin size = %lu", (unsigned long)binData.length);
    
    GCDAsyncSocket *socket = nil;
    int appPkgLength = 1440;
    
    NSMutableArray<EspDevice *> *postDevices = [NSMutableArray arrayWithArray:devices];
    NSMutableDictionary<NSString *, NSMutableSet<NSNumber *> *> *postDict = [NSMutableDictionary dictionary];
    const int retry = 10;
    BOOL checkStatus = YES;
    
    self.writeQueue = [[EspBlockingQueue alloc] init];
    self.readQueue = [[EspBlockingQueue alloc] init];
    
    for (int i = 0; i < retry; i++) {
        if (!socket) {
            NSLog(@"OTA create long socket host=%@, port=%d", host, port);
            socket = [self createLongSocketWithHost:host port:port];
            socket.delegate = self;
            self.socket = socket;
        }
        if (!socket) {
            NSLog(@"OTA create long socket failed");
            continue;
        }
        
        
        
        if (checkStatus) {
            NSLog(@"OTA check status");
            NSMutableDictionary *statusDict = [self checkStatusForDevices:devices binVersion:binVersion binLength:binData.length appPkgLen:&appPkgLength];
            
            if (statusDict.count == 0) {
                NSLog(@"OTA all complete");
                break;
            }
            
            [postDict removeAllObjects];
            [postDict setDictionary:statusDict];
            
            [postDevices removeAllObjects];
            for (EspDevice *device in devices) {
                if (postDict[device.mac]) {
                    [postDevices addObject:device];
                }
            }
            checkStatus = NO;
        }
        
        NSLog(@"OTA request ota");
        NSString *ipv4 = [EspNetUtils getIPAddress:YES];
        EspHttpResponse *requResp = [self requestOTADevices:devices appPort:socket.localPort appIP:ipv4 appPkgLen:appPkgLength];
        if (!requResp) {
            continue;
        }
        
        NSLog(@"OTA write bin data");
//        BOOL writeBinSuc = [self writeBinData:socket bin:binData packageLength:appPkgLength devices:devices deviceSequenceDictionary:postDict];
//        if (!writeBinSuc) {
//            [self closeSocket:socket];
//            continue;
//        }
        
//        NSLog(@"OTA read response");
//        NSTimeInterval respTimeout = 10;
//        NSUInteger respLen = 1;
//        [socket readDataToLength:respLen withTimeout:respTimeout tag:0];
//        NSData *respData = [self.readQueue dequeue];
//        if (respData.length < respLen) {
//            NSLog(@"OTA read response faied");
//            [self closeSocket:socket];
//            continue;
//        }
//        Byte *respBytes = (Byte *)[respData bytes];
//        if (respBytes[0] != 200) {
//            NSLog(@"OTA read response %d", respBytes[0]);
//            [self closeSocket:socket];
//            continue;
//        }
//
//        NSLog(@"OTA read delay");
//        respTimeout = 5;
//        NSUInteger delayLen = 2;
//        [socket readDataToLength:delayLen withTimeout:respTimeout tag:1];
//        NSData *delayData = [self.readQueue dequeue];
//        if (delayData.length < delayLen) {
//            NSLog(@"OTA read delay failed");
//            [self closeSocket:socket];
//            continue;
//        }
//        Byte *delayBytes = (Byte *)[delayData bytes];
//        NSTimeInterval delay = delayBytes[0] | (delayBytes[1] << 8);
//        NSLog(@"OTA read delay %lf", delay);
//        [NSThread sleepForTimeInterval:(delay / 1000.0)];
    }
    
    NSLog(@"OTA try close socket");
    [self closeSocket:socket];
    
    NSLog(@"OTA reboot");
    [self otaReboot:devices];
}

- (void)closeSocket:(GCDAsyncSocket *)socket {
    if (socket) {
        [socket disconnect];
        socket.delegate = nil;
        socket = nil;
        self.socket = nil;
    }
}

- (GCDAsyncSocket *)createLongSocketWithHost:(NSString *)host port:(int)port {
    GCDAsyncSocket *socket;
    for (int i = 0; i < 3; i++) {
        socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        NSError *error = nil;
        
        BOOL connected = [socket connectToHost:host onPort:port error:&error];
        if (connected) {
            break;
        } else {
            socket = nil;
        }
    }
    return socket;
}

- (NSMutableDictionary<NSString *, NSMutableSet<NSNumber *> *> *)checkStatusForDevices:(NSArray *)devices binVersion:(NSString *)binVersion binLength:(NSUInteger)binLength appPkgLen:(int *)appPkgLen {
    NSMutableDictionary<NSString *, NSMutableSet<NSNumber *> *> *result = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionary];
    [postDict setObject:EspRequestOTAStatus forKey:EspKeyRequest];
    [postDict setObject:binVersion forKey:EspKeyBinVersion];
    [postDict setObject:[NSNumber numberWithUnsignedLong:binLength] forKey:EspKeyBinLength];
    [postDict setObject:[NSNumber numberWithUnsignedLong:1440] forKey:@"package_length"];
    
    NSData *postData = [EspJsonUtils getDataWithDictionary:postDict];
    
    EspHttpParams *params = [[EspHttpParams alloc] init];
    params.timeout = 60;
    NSMutableDictionary *deviceDict = [NSMutableDictionary dictionary];
    for (EspDevice *device in devices) {
        [deviceDict setObject:device forKey:device.mac];
    }
    NSMutableDictionary *respDict = [NSMutableDictionary dictionary];
    for (int i = 0; i < 3 && deviceDict.count > 0; i++) {
        NSArray<EspHttpResponse *> *respArray = [EspDeviceUtil httpLocalMulticastRequestForDevices:deviceDict.allValues content:postData params:params headers:nil multithread:YES];
        
        NSDictionary<NSString *,EspHttpResponse *> *dict = [EspDeviceUtil getDictionaryWithDeviceResponses:respArray];
        for (NSString *mac in dict.allKeys) {
            [deviceDict removeObjectForKey:mac];
        }
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, EspHttpResponse * _Nonnull obj, BOOL * _Nonnull stop) {
            [respDict setObject:obj forKey:key];
        }];
    }
    
    for (EspDevice *device in devices) {
        if (respDict.count == 0) {
            break;
        }
        
        EspHttpResponse *response = respDict[device.mac];
        id respJSON = [response getContentJSON];
        if (!respJSON) {
            NSLog(@"OTA check sequence json nil");
            [result setObject:[NSMutableSet set] forKey:device.mac];
            continue;
        }
        
        int status = [[respJSON valueForKey:EspKeyStatusCode] intValue];
        switch (status) {
            case EspOTAStatusSuccess:
                NSLog(@"OTA %@ recv bin data success", device.mac);
                break;
            case EspOTAStatusContinue:
                {
                    NSLog(@"OTA %@ ota status continue", device.mac);
                    NSArray *array =[respJSON valueForKey:EspKeyPackageSequence];
                    NSMutableSet *set = [NSMutableSet setWithArray:array];
                    [result setObject:set forKey:device.mac];
                    
                    NSNumber *pkgLen = [respJSON valueForKey:EspKeyPackageLength];
                    NSLog(@"剩余包数量：%lu",(unsigned long)array.count);
                    *appPkgLen = [pkgLen intValue];
                    //}
                }
                break;
            default:
                NSLog(@"OTA %@ unknow ota status", device.mac);
                [result setObject:[NSMutableSet set] forKey:device.mac];
                break;
        }
    }
    
    return result;
}

- (EspHttpResponse *)requestOTADevices:(NSArray<EspDevice *> *)devices appPort:(uint16_t)appPort appIP:(NSString *)appIP appPkgLen:(int)appPkgLen {
    EspDevice *deviceFirst = devices[0];
    NSString *urlOtaRequest = [NSString stringWithFormat:@"%@://%@:%@/mesh_ota", deviceFirst.httpType, deviceFirst.host, deviceFirst.port];
    
    NSMutableString *otaAddr = [NSMutableString string];
    [otaAddr appendFormat:@"%02x%02x", (appPort & 0xff), ((appPort >> 8) & 0xff)];
    
    NSArray<NSString *> * ipSplit = [appIP componentsSeparatedByString:@"."];
    for (NSString *str in ipSplit) {
        int i = [str intValue];
        [otaAddr appendFormat:@"%02x", i];
    }
    
    NSMutableString *macs = [NSMutableString string];
    for (int i = 0; i < devices.count; i++) {
        NSString *mac = devices[i].mac;
        [macs appendString:mac];
        if (i < devices.count - 1) {
            [macs appendString:@","];
        }
    }
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [headers setObject:otaAddr forKey:EspHeaderOTAAddress];
    [headers setObject:[NSString stringWithFormat:@"%d", appPkgLen] forKey:EspHeaderOTALength];
    [headers setObject:[NSString stringWithFormat:@"%lu", (unsigned long)devices.count] forKey:EspHeaderNodeNum];
    [headers setObject:macs forKey:EspHeaderNodeMac];
    [headers setObject:EspHttpHeaderValueContentTypeJSON forKey:EspHttpHeaderConentType];
    
    EspHttpParams *params = [[EspHttpParams alloc] init];
    params.tryCount = 3;
    params.timeout = 5;
    
    return [EspHttpUtils postForUrl:urlOtaRequest content:nil params:params headers:headers];
}

- (BOOL)writeBinData:(GCDAsyncSocket *)socket bin:(NSData *)bin packageLength:(int)pkgLen devices:(NSArray<EspDevice *> *)devices deviceSequenceDictionary:(NSDictionary<NSString *, NSMutableSet<NSNumber *> *> *)deviceSeqDict {
    // Split bin data with sequence
    NSMutableArray<NSData *> *binDataArray = [NSMutableArray array];
    const int headLen = 8;
    const int binPkgLen = pkgLen - headLen;
    for (int i = 0; ; i++) {
        NSUInteger binPosition = i * binPkgLen;
        if (binPosition >= bin.length) {
            break;
        }
        
        NSMutableData *data = [NSMutableData data];
        Byte data03[4] = {0xa5, 0xa5, 0xa5, 0xa5};
        [data appendBytes:data03 length:4];
        Byte data45[2] = {i & 0xff, (i >> 8) & 0xff};
        [data appendBytes:data45 length:2];
        
        long exceed = (long)(binPosition) + (long)binPkgLen - (long)bin.length;
        NSUInteger binRangeLen = exceed > 0 ? (binPkgLen - exceed) : binPkgLen;
        Byte data67[2] = {binRangeLen & 0xff, (binRangeLen >> 8) & 0xff};
        [data appendBytes:data67 length:2];
        
        NSRange binRange = NSMakeRange(binPosition, binRangeLen);
        NSData *binData = [bin subdataWithRange:binRange];
        [data appendData:binData];
        
        if (exceed > 0) {
            NSData *zeroFill = [NSMutableData dataWithLength:exceed];
            [data appendData:zeroFill];
        }
        
        [binDataArray addObject:data];
    }
    
    // Process sequence
    NSNumber *fuyi = [NSNumber numberWithInt:-1];
    for (NSString *mac in deviceSeqDict.allKeys) {
        NSMutableSet<NSNumber *> *set = deviceSeqDict[mac];
        if ([set containsObject:fuyi]) {
            [set removeObject:fuyi];
            NSNumber *seq = [[set objectEnumerator] nextObject];
            for (int index = [seq intValue]; index < binDataArray.count; index++) {
                [set addObject:[NSNumber numberWithInt:index]];
            }
        }
    }
    
    NSArray<EspDevice *> *postDevices = [devices sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSSet *set1 = obj1;
        NSSet *set2 = obj2;
        
        if (set1.count == 0) {
            return 1;
        }
        if (set2.count == 0) {
            return -1;
        }
        
        if (set1.count < set2.count) {
            return -1;
        } else if (set1.count == set2.count) {
            return 0;
        } else {
            return 1;
        }
    }];
    
    for (NSUInteger i = 0; i < postDevices.count; i++) {
        NSMutableSet<NSNumber *> *set1 = deviceSeqDict[postDevices[i].mac];
        for (NSUInteger j = i + 1; j < postDevices.count; j++) {
            NSMutableSet<NSNumber *> *set2 = deviceSeqDict[postDevices[j].mac];
            for (NSNumber *seq in set1) {
                if ([set2 containsObject:seq]) {
                    [set2 removeObject:seq];
                }
            }
        }
    }

    
    NSTimeInterval timeout = 30;
    for (EspDevice *device in postDevices) {
        NSSet<NSNumber *> *set = deviceSeqDict[device.mac];
        NSMutableArray<NSNumber *> *array = [NSMutableArray array];
        for (NSNumber *seq in set) {
            [array addObject:seq];
        }
        [array sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [obj1 compare:obj2];
        }];
        
        for (NSNumber *seq in array) {
            NSData *postData = binDataArray[[seq intValue]];
            [socket writeData:postData withTimeout:timeout tag:[seq longValue]];
//            NSNumber *writeSuc = [self.writeQueue dequeue];
//            if ([writeSuc boolValue]) {
//                return NO;
//            }
            //sleep(0.1);
        }
    }
    
    // Post end package
    NSMutableData *endData = [NSMutableData dataWithLength:pkgLen];
    Byte end01[2] = {-1, -1};
    [endData replaceBytesInRange:NSMakeRange(0, 2) withBytes:end01];
    socket.delegate = self;
    [socket writeData:endData withTimeout:timeout tag:-1];
    NSNumber *writeEndSuc = [self.writeQueue dequeue];
    return [writeEndSuc boolValue];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@" did write data tag:%ld",tag);
    [self.writeQueue enqueue:[NSNumber numberWithBool:YES]];
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    [self.writeQueue enqueue:[NSNumber numberWithBool:NO]];
    return -1;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [self.readQueue enqueue:data];
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    [self.readQueue enqueue:[NSData data]];
    return -1;
}

- (void)otaReboot:(NSArray<EspDevice *> *)devices {
    EspHttpParams *params = [[EspHttpParams alloc] init];
    params.tryCount = 3;
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionary];
    [postDict setObject:EspRequestOTAReboot forKey:EspKeyRequest];
    long delay = devices.count > 1 ? 3000 : 500;
    [postDict setObject:[NSNumber numberWithLong:delay] forKey:EspKeyDelay];
    NSData *postData = [EspJsonUtils getDataWithDictionary:postDict];
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [headers setObject:EspHeaderNoResponse forKey:@"true"];
    
    [EspDeviceUtil httpLocalMulticastRequestForDevices:devices content:postData params:params headers:headers multithread:NO];
}

@end
