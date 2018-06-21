//
//  SharedInstance.m
//  BraciPro
//
//  Created by Farhan on 09/04/15.
//  Copyright (c) 2015 Braci.co.LTD. All rights reserved.
//

#import "SharedInstance.h"

static SharedInstance *appSharedData_ = nil;

@implementation SharedInstance
@synthesize detectSound;
@synthesize background;
//@synthesize g_pebbleWatch;
@synthesize profileMode;

+(instancetype)shared {
    
    static dispatch_once_t predicate;
    
    if(appSharedData_ == nil){
        dispatch_once(&predicate,^{
            appSharedData_ = [[SharedInstance alloc] init];
        
        });
    }
    return appSharedData_;
}

@end
