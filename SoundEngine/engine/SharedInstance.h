//
//  SharedInstance.h
//  BraciPro
//
//  Created by Farhan on 09/04/15.
//  Copyright (c) 2015 Braci.co.LTD. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <PebbleKit/PebbleKit.h>

@interface SharedInstance : NSObject

+(instancetype)shared;

@property(nonatomic,assign)bool detectSound;
@property(nonatomic,assign)bool background;
//@property(nonatomic,assign)PBWatch *g_pebbleWatch;
@property(nonatomic,assign)NSString *profileMode;

@end
