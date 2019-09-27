//
//  FBYBallLoading.h
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/9/24.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBYBallLoading : UIView
-(void)start;

-(void)stop;

+(void)showInView:(UIView*)view;

+(void)hideInView:(UIView*)view;
@end

NS_ASSUME_NONNULL_END
