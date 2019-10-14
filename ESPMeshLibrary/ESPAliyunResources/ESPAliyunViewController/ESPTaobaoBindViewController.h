//
//  ESPTaobaoBindViewController.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/10/9.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IMSTmallSpeakerApi.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ESPFBYTaobaoBindDelegate <NSObject>

-(void)userTaobaoBindWithResult:(NSDictionary *)result error:(NSError *)err;

@end

@interface ESPTaobaoBindViewController : UIViewController

@property (weak, nonatomic)id<ESPFBYTaobaoBindDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
