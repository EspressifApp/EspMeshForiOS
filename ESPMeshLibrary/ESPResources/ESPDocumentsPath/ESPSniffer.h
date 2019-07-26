//
//  ESPSniffer.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/7/9.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESPSniffer : NSObject

@property(nonatomic, assign)int rssi;
@property(nonatomic, strong)NSString *bssid;
@property(nonatomic, strong)NSString *UTCtime;
@property(nonatomic, assign)long time;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, assign)int channel;
@property(nonatomic, strong)NSString *manufacturerId;

@property(nonatomic, assign)int snifferType;
@property(nonatomic, strong)NSString *meshMac;

@end

NS_ASSUME_NONNULL_END
