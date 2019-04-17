//
//  EspActionDeviceOTA.h
//  Esp32Mesh
//
//  Created by AE on 2018/4/24.
//  Copyright © 2018年 AE. All rights reserved.
//

#import "EspActionDevice.h"
#import "EspDevice.h"

static NSString * const EspUrlRomQuery = @"https://iot.espressif.cn/v1/device/rom/";
static NSString * const EspUrlRomDownloadFormat = @"https://iot.espressif.cn/v1/device/rom/?action=download_rom&version=%@&filename=%@";
static NSString * const EspRomDeviceKey = @"11a7b2385567790ad8c60fe75557e15168abb7c5";

static NSString * const EspKeyRoms = @"productRoms";
static NSString * const EspKeyLatestVersion = @"recommended_rom_version";
static NSString * const EspKeyFiles = @"files";
static NSString * const EspKeyName = @"name";

@interface EspActionDeviceOTA : EspActionDevice

- (BOOL)doActionDownloadLastestRomVersionCloud;
- (void)doActionOTALocalDevices:(NSArray<EspDevice *> *)devices binPath:(NSString *)binPath;

- (void)otaReboot:(NSArray<EspDevice *> *)devices;
@end
