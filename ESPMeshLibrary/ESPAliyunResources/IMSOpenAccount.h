//
//  IMSOpenAccount.h
//  IMSAccount
//
//  Created by Hager Hu on 01/11/2017.
//

#import <Foundation/Foundation.h>

#import <IMSAccount/IMSAccountUIProtocol.h>
#import <IMSAccount/IMSAccountProtocol.h>

@interface IMSOpenAccount : NSObject <IMSAccountProtocol, IMSAccountUIProtocol>

+ (instancetype)sharedInstance;

@end
