//
//  ESPFBYBLECBPeripheral.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/5/5.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESPFBYBLECBPeripheral : NSObject<CBPeripheralManagerDelegate>
@property(nonatomic,strong) CBPeripheralManager *peripheralManager;

+(id)shared;

-(void)setup;

-(void)addSe;
-(void)adv;
@end

NS_ASSUME_NONNULL_END
