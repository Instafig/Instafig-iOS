//
//  AWInstafig.h
//  InstafigSDK
//
//  Created by shy on 16/3/4.
//  Copyright © 2016年 AppTao. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const AWInstafigConfLoadSucceedNotification;
extern NSString *const AWInstafigConfLoadFailedNotification;

@interface AWInstafig : NSObject

+ (AWInstafig *)sharedInstance;

- (void)startWithAppKey:(NSString*)appKey;

- (NSDate *)lastUpdateTime;

- (void)update;

- (NSString *)stringForKey:(NSString *)key default:(NSString *)defaultValue;

- (long)integerForKey:(NSString *)key default:(long)defaultValue;

- (double)doubleForKey:(NSString *)key default:(double)defaultValue;

@end